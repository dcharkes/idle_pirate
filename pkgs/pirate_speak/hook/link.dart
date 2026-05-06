import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:pirate_speak/src/category_ids.dart';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:record_use/record_use.dart';

import '../../../tree_shaking_config.dart';

void main(List<String> args) async {
  await link(args, (input, output) async {
    if (!input.config.buildDataAssets) return;

    final dataAssets = input.assets.data;
    final usages = input.recordedUses;

    await treeshakeTranslations(dataAssets, usages, input, output);

    _verifyAssetsFromLinking(input);
  });
}

Future<void> treeshakeTranslations(
  Iterable<DataAsset> dataAssets,
  Recordings? usages,
  LinkInput input,
  LinkOutputBuilder output,
) async {
  final requestedLanguages = _getRequestedLanguages(input);

  if (usages == null || !enableTranslationTreeShaking) {
    // No recorded uses found or tree-shaking disabled. Including assets.
    final assets = _filterByLanguage(dataAssets, requestedLanguages);
    output.assets.data.addAll(assets);
    output.dependencies.addAll(assets.map((a) => a.file));
    return;
  }

  final usedStaticTranslations = _usedStaticTranslations(usages);
  final usedCategories = _usedDynamicTranslations(usages);
  final receivedCategoryKeys = await _receivedCategoryKeys(input);
  _errorOnMissingCategories(usedCategories, receivedCategoryKeys);
  final usedTranslations = {
    ...usedStaticTranslations,
    for (final category in usedCategories) ...(receivedCategoryKeys[category]!),
  };

  final filteredAssets = _filterByLanguage(dataAssets, requestedLanguages);
  final (
    prunedTranslations,
    translationDeps,
  ) = await _pruneTranslations(
    filteredAssets,
    usedTranslations,
    input.outputDirectoryShared,
  );

  output.assets.data.addAll(prunedTranslations);
  output.dependencies.addAll(translationDeps);
}

void _verifyAssetsFromLinking(LinkInput input) {
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
    throw UnsupportedError(
      'Unsupported assets sent to link hook in pirate_speak: ${unsupportedAssets.map((a) => a.name).toList()}',
    );
  }
}

const _translationsLib = Library('package:pirate_speak/pirate_speak.dart');

Set<String> _usedStaticTranslations(Recordings usages) {
  const translateMethod = Method('translate', _translationsLib);
  final translateCalls = usages.calls[translateMethod];
  if (translateCalls == null) {
    return <String>{};
  }
  return {
    for (final call in translateCalls)
      switch (call) {
        CallWithArguments(
          positionalArguments: [StringConstant(value: final key), ...],
        ) =>
          key,
        _ => throw UnsupportedError(
          'Cannot safely parse translate call: $call.',
        ),
      },
  };
}

Set<String> _usedDynamicTranslations(Recordings usages) {
  const translateDynamicMethod = Method('translateDynamic', _translationsLib);
  final translateCalls = usages.calls[translateDynamicMethod];
  if (translateCalls == null) return <String>{};

  return {
    for (final call in translateCalls)
      switch (call) {
        CallWithArguments(
          positionalArguments: [_, StringConstant(value: final category), ...],
        ) =>
          category,
        _ => throw UnsupportedError(
          'Cannot safely parse translateDynamic call: $call',
        ),
      },
  };
}

Future<(List<DataAsset>, Set<Uri>)> _pruneTranslations(
  Iterable<DataAsset> assets,
  Set<String> usedTranslations,
  Uri baseOutputDir,
) async {
  final outputAssets = <DataAsset>[];
  final dependencies = <Uri>{};

  final outputDir = Directory.fromUri(baseOutputDir.resolve('translations/'));
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  for (final asset in assets) {
    final file = File.fromUri(asset.file);
    final filename = file.uri.pathSegments.last;
    final name = 'assets/translations/$filename';

    dependencies.add(file.uri);
    final jsonStr = await file.readAsString();
    final jsonMap = Map<String, String>.from(json.decode(jsonStr));

    // Check for missing translation keys in ALL files
    for (final key in usedTranslations) {
      if (!jsonMap.containsKey(key)) {
        throw ArgumentError(
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
        // Filtering out unused translation key: $key
      }
    }

    const encoder = JsonEncoder.withIndent('  ');
    final filteredJsonStr = encoder.convert(filteredMap);
    final outputFile = File.fromUri(outputDir.uri.resolve(filename));
    await outputFile.writeAsString(filteredJsonStr);

    outputAssets.add(
      DataAsset(package: 'pirate_speak', name: name, file: outputFile.uri),
    );
  }
  return (outputAssets, dependencies);
}

Set<String>? _getRequestedLanguages(LinkInput input) {
  final requestedLanguages = (input as dynamic).userDefines?['languages'];
  if (requestedLanguages == null) return null;

  final list = <String>{};
  if (requestedLanguages is List) {
    list.addAll(requestedLanguages.cast<String>());
  } else if (requestedLanguages is String) {
    list.addAll(requestedLanguages.split(',').map((e) => e.trim()));
  }
  return list;
}

List<DataAsset> _filterByLanguage(
  Iterable<DataAsset> assets,
  Set<String>? requestedLanguages,
) {
  if (requestedLanguages == null || !translationTreeShakingLookAtUserDefines) {
    return assets.toList();
  }
  return assets.where((a) {
    final lang = a.name.split('/').last.split('.').first;
    return requestedLanguages.contains(lang);
  }).toList();
}

Future<Map<String, Set<String>>> _receivedCategoryKeys(LinkInput input) async {
  final categoryIdsList = await PirateSpeakCategoryIds.fromInput(input);
  final map = <String, Set<String>>{};
  for (final categoryIds in categoryIdsList) {
    for (final entry in categoryIds.categoryIds.entries) {
      map.putIfAbsent(entry.key, () => <String>{}).addAll(entry.value);
    }
  }
  return map;
}

void _errorOnMissingCategories(
  Set<String> usedCategories,
  Map<String, Set<String>> receivedCategoryKeys,
) {
  for (final category in usedCategories) {
    if (!receivedCategoryKeys.containsKey(category)) {
      throw UnsupportedError(
        'Missing IDs for category: $category. You need to send them from the parent package using AssetRouting.',
      );
    }
  }
}
