// ignore_for_file: avoid_print

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:record_use/record_use.dart';

// Top-level constants for lookup
const _translationsLib = Library('package:pirate_speak/pirate_speak.dart');

const _translateMethod = Method('translate', _translationsLib);
const _translateDynamicMethod = Method('translateDynamic', _translationsLib);

void main(List<String> args) async {
  await link(args, (LinkInput input, LinkOutputBuilder output) async {
    // ignore: experimental_member_use
    final usages = input.recordedUses;

    if (usages == null) {
      print(
        'No recorded uses found. Bailing on treeshaking and including all assets.',
      );
      output.assets.data.addAll(input.assets.data);
      return;
    }

    final usedStaticTranslations = _usedStaticTranslations(usages);
    final usedCategories = _usedCategories(usages);

    // Read routed assets for category IDs!
    final categoryIdsAssets = input.assets.assetsFromLinking
        .where((e) => e.isDataAsset)
        .map(DataAsset.fromEncoded)
        .where((a) => a.name == 'pirate_speak_category_ids');

    final usedDynamicTranslations = <String>{};
    final receivedCategories = <String>{};
    for (final asset in categoryIdsAssets) {
      final file = File.fromUri(asset.file);
      if (file.existsSync()) {
        final jsonStr = await file.readAsString();
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        for (final entry in map.entries) {
          receivedCategories.add(entry.key);
          usedDynamicTranslations.addAll(List<String>.from(entry.value));
        }
        print('Received category IDs for: ${map.keys.toList()}');
      }
    }

    // Check for missing IDs for a used category!
    for (final category in usedCategories) {
      if (!receivedCategories.contains(category)) {
        throw StateError(
          'Missing IDs for category: $category. You need to send them from the parent package using AssetRouting.',
        );
      }
    }

    final usedTranslations = {
      ...usedStaticTranslations,
      ...usedDynamicTranslations,
    };

    // Read translation files directly from filesystem!
    final dir = Directory('assets/translations/');
    final translationFiles = <File>[];
    if (dir.existsSync()) {
      translationFiles.addAll(
        dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')),
      );
    }

    final (handledTranslations, translationDeps) = await _treeShakeTranslations(
      translationFiles,
      usedTranslations,
      input.outputDirectoryShared,
    );

    output.assets.data.addAll(handledTranslations);
    output.dependencies.addAll(translationDeps);

    // Verify no unsupported assets are sent in input.assetsFromLinking!
    final unsupportedAssets = input.assets.assetsFromLinking
        .where((e) => e.isDataAsset)
        .map(DataAsset.fromEncoded)
        .where(
          (a) =>
              !a.name.startsWith('assets/translations/') &&
              a.name != 'pirate_speak_category_ids',
        )
        .toList();

    if (unsupportedAssets.isNotEmpty) {
      throw StateError(
        'Unsupported assets sent to link hook in pirate_speak: ${unsupportedAssets.map((a) => a.name).toList()}',
      );
    }
  });
}

Set<String> _usedStaticTranslations(Recordings usages) {
  final usedTranslationKeys = <String>{};
  final translateCalls = usages.calls[_translateMethod];
  if (translateCalls == null) {
    print('No recordings found for $_translateMethod.');
    return usedTranslationKeys;
  }
  for (final call in translateCalls) {
    switch (call) {
      case CallWithArguments(
        positionalArguments: [StringConstant(value: final key), ...],
      ):
        usedTranslationKeys.add(key);
      case _:
        throw StateError('Cannot safely parse translate call: $call.');
    }
  }
  return usedTranslationKeys;
}

Set<String> _usedCategories(Recordings usages) {
  final categories = <String>{};
  final translateCalls = usages.calls[_translateDynamicMethod];
  if (translateCalls == null) return categories;

  for (final call in translateCalls) {
    switch (call) {
      case CallWithArguments(
        positionalArguments: [_, StringConstant(value: final category), ...],
      ):
        categories.add(category);
      case _:
        throw StateError('Cannot safely parse translateDynamic call: $call');
    }
  }
  return categories;
}

Future<(List<DataAsset>, Set<Uri>)> _treeShakeTranslations(
  Iterable<File> files,
  Set<String> usedTranslations,
  Uri baseOutputDir,
) async {
  final outputAssets = <DataAsset>[];
  final dependencies = <Uri>{};

  final outputDir = Directory.fromUri(baseOutputDir.resolve('translations/'));
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  for (final file in files) {
    final filename = file.uri.pathSegments.last;
    final name = 'assets/translations/$filename';

    dependencies.add(file.uri);
    final jsonStr = await file.readAsString();
    final jsonMap = Map<String, String>.from(json.decode(jsonStr));

    // Check for missing translation keys in ALL files
    for (final key in usedTranslations) {
      if (!jsonMap.containsKey(key)) {
        throw StateError(
          'Missing translation key in $name: $key. You need to add it.',
        );
      }
    }

    final filteredMap = SplayTreeMap<String, String>();

    for (final entry in jsonMap.entries) {
      final key = entry.key;
      final value = entry.value;

      if (usedTranslations.contains(key)) {
        filteredMap[key] = value;
      } else {
        print('Filtering out unused translation key: $key');
      }
    }

    const encoder = JsonEncoder.withIndent('  ');
    final filteredJsonStr = encoder.convert(filteredMap);
    final outputFile = File.fromUri(outputDir.uri.resolve(filename));
    await outputFile.writeAsString(filteredJsonStr);

    print(
      'Filtered translation file: $name, kept ${filteredMap.length}/${jsonMap.length} keys.',
    );

    outputAssets.add(
      DataAsset(package: 'pirate_speak', name: name, file: outputFile.uri),
    );
  }
  return (outputAssets, dependencies);
}
