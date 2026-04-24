// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';
// ignore: experimental_member_use
import 'package:record_use/record_use.dart';

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

    final iconSizes = <String, double>{};

    // Construct definitions for lookup
    final uiLib = Library('package:idle_pirate/ui/screens/game_screen.dart');
    final modelsLib = Library('package:idle_pirate/models/upgrade.dart');

    final staticIconDef = Class('StaticIcon', uiLib);
    final dynamicIconDef = Class('DynamicIcon', uiLib);
    final upgradeDef = Class('Upgrade', modelsLib);
    final soundDef = Class('Sound', modelsLib);
    final translationsLib = Library('package:idle_pirate/state/translations.dart');
    final translateMethod = Method('translate', translationsLib);

    // 1. Process StaticIcon records
    final staticInstances = usages.instances[staticIconDef] ?? [];
    for (final instance in staticInstances) {
      switch (instance) {
        case InstanceConstantReference(
          instanceConstant: InstanceConstant(
            fields: {
              'id': StringConstant(value: final id),
              'size': DoubleConstant(value: final size),
            },
          ),
        ):
          iconSizes[id] = size;
        case InstanceCreationReference(
          positionalArguments: [
            StringConstant(value: final id),
            DoubleConstant(value: final size),
          ],
        ):
          iconSizes[id] = size;
        case _:
          throw StateError(
            'Cannot safely parse StaticIcon instance: $instance',
          );
      }
    }

    // 2. Process DynamicIcon records to get category sizes
    final categorySizes = <String, double>{};
    final dynamicInstances = usages.instances[dynamicIconDef] ?? [];
    for (final instance in dynamicInstances) {
      switch (instance) {
        case InstanceCreationReference(
          positionalArguments: [
            _, // id
            DoubleConstant(value: final size),
            StringConstant(value: final category),
          ],
        ):
          categorySizes[category] = size;
        case InstanceConstantReference(
          instanceConstant: InstanceConstant(
            fields: {
              'size': DoubleConstant(value: final size),
              'category': StringConstant(value: final category),
            },
          ),
        ):
          categorySizes[category] = size;
        case _:
          throw StateError(
            'Cannot safely parse DynamicIcon instance: $instance',
          );
      }
    }

    // 3. Process Upgrade records to know which upgrades are used
    final usedUpgradeIds = <String>{};
    final upgradeInstances = usages.instances[upgradeDef] ?? [];
    for (final instance in upgradeInstances) {
      switch (instance) {
        case InstanceConstantReference(
          instanceConstant: InstanceConstant(
            fields: {'id': StringConstant(value: final id)},
          ),
        ):
          usedUpgradeIds.add(id);
        case InstanceCreationReference(
          namedArguments: {'id': StringConstant(value: final id)},
        ):
          usedUpgradeIds.add(id);
        case _:
          throw StateError('Cannot safely parse Upgrade instance: $instance');
      }
    }

    // 3.5 Process Sound records to know which sounds are used
    final usedSoundIds = <String>{};
    final soundInstances = usages.instances[soundDef] ?? [];
    for (final instance in soundInstances) {
      switch (instance) {
        case InstanceConstantReference(
          instanceConstant: InstanceConstant(
            fields: {'id': StringConstant(value: final id)},
          ),
        ):
          usedSoundIds.add(id);
        case InstanceCreationReference(
          positionalArguments: [StringConstant(value: final id)],
        ):
          usedSoundIds.add(id);
        case InstanceCreationReference():
          // Ignore non-const calls (e.g. from _extractAudioAssets)
          break;
        case _:
          throw StateError('Cannot safely parse Sound instance: $instance');
      }
    }

    // 3.6 Process translate calls to know which keys are used
    final usedTranslationKeys = <String>{};
    final translateCalls = usages.calls[translateMethod] ?? [];
    for (final call in translateCalls) {
      final positional = (call as dynamic).positionalArguments;
      if (positional.isNotEmpty && positional[0] is StringConstant) {
        usedTranslationKeys.add((positional[0] as StringConstant).value);
      }
    }

    // 4. Combine info: assume all used upgrades are in 'upgrade' category
    final upgradeSize = categorySizes['upgrade'];
    if (upgradeSize != null) {
      for (final id in usedUpgradeIds) {
        iconSizes[id] = upgradeSize;
      }
    }

    print('Icon sizes: $iconSizes');
    print('Used sound IDs: $usedSoundIds');

    await _processAssets(input, output, iconSizes, usedSoundIds, usedTranslationKeys, usedUpgradeIds);
  });
}

Future<void> _processAssets(
  LinkInput input,
  LinkOutputBuilder output,
  Map<String, double> iconSizes,
  Set<String> usedSoundIds,
  Set<String> usedTranslationKeys,
  Set<String> usedUpgradeIds,
) async {
  // Use a known subdirectory of outputDirectoryShared
  final assetsDir = Directory.fromUri(
    input.outputDirectoryShared.resolve('icons/'),
  );
  if (!assetsDir.existsSync()) {
    assetsDir.createSync(recursive: true);
  }

  for (final asset in input.assets.data) {
    final filename = asset.name.split('/').last;
    final id = filename.split('.').first;

    if (asset.name.startsWith('assets/images/')) {
      if (iconSizes.containsKey(id)) {
        final logicalSize = iconSizes[id]!;
        final targetSize = (logicalSize * 3.0).toInt();
        final sizeStr = '${targetSize}x$targetSize';

        final sourceFile = File.fromUri(asset.file);
        final outputFile = File.fromUri(assetsDir.uri.resolve(filename));

        if (await _shouldResize(sourceFile, outputFile)) {
          final success = await _resizeIcon(sourceFile, outputFile, sizeStr);
          if (!success) {
            // Fallback to original asset if resize fails
            output.assets.data.add(asset);
            continue;
          }
        } else {
          print('Asset ${asset.name} is up to date, skipping resize.');
        }

        output.assets.data.add(
          DataAsset(
            package: asset.package,
            name: asset.name,
            file: outputFile.uri,
          ),
        );
      } else {
        print('Filtering out icon: ${asset.name}');
      }
    } else if (asset.name.startsWith('assets/sounds/')) {
      if (usedSoundIds.contains(id)) {
        print('Keeping sound: ${asset.name}');
        output.assets.data.add(asset);
      } else {
        print('Filtering out sound: ${asset.name}');
      }
    } else if (asset.name.startsWith('assets/translations/')) {
      final file = File.fromUri(asset.file);
      if (file.existsSync()) {
        output.dependencies.add(file.uri);
        final jsonStr = await file.readAsString();
        final jsonMap = Map<String, String>.from(json.decode(jsonStr));
        final filteredMap = <String, String>{};
        
        for (final entry in jsonMap.entries) {
          final key = entry.key;
          final value = entry.value;
          
          if (usedTranslationKeys.contains(key)) {
            filteredMap[key] = value;
          } else if (usedUpgradeIds.contains(key)) {
            filteredMap[key] = value;
          } else {
            print('Filtering out unused translation key: $key');
          }
        }
        
        final filteredJsonStr = json.encode(filteredMap);
        
        final outputFile = File.fromUri(assetsDir.uri.resolve(filename));
        await outputFile.writeAsString(filteredJsonStr);
        
        print('Filtered translation file: ${asset.name}, kept ${filteredMap.length}/${jsonMap.length} keys.');
        
        output.assets.data.add(
          DataAsset(
            package: asset.package,
            name: asset.name,
            file: outputFile.uri,
          ),
        );
      }
    } else {
      print('Unknown asset type: ${asset.name}');
      output.assets.data.add(asset);
    }
  }
}

Future<bool> _resizeIcon(File source, File target, String sizeStr) async {
  print('Resizing asset: ${source.path} to $sizeStr');
  // Implementation Note: We are currently using external tools (like ImageMagick)
  // on the command line to resize images. In the future, to avoid command line
  // dependencies, we can use `stb_image_resize2.h` (compiled via a native helper)
  // to resize images directly within this link hook.
  final result = await Process.run('magick', [
    source.path,
    '-resize',
    sizeStr,
    target.path,
  ]);

  if (result.exitCode != 0) {
    stderr.writeln('Failed to resize asset: ${source.path}');
    stderr.writeln(result.stderr);
    return false;
  }
  return true;
}

Future<bool> _shouldResize(File source, File target) async {
  if (!target.existsSync()) return true;

  final sourceTime = await source.lastModified();
  final targetTime = await target.lastModified();

  return sourceTime.isAfter(targetTime) ||
      sourceTime.isAtSameMomentAs(targetTime);
}
