// ignore_for_file: avoid_print

import 'dart:io';
import 'package:pirate_speak/src/category_ids.dart';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';
// ignore: experimental_member_use
import 'package:record_use/record_use.dart';

import '../../../tree_shaking_config.dart';

// Top-level constants for lookup
const _assetsLib = Library('package:idle_pirate/assets/images.dart');
const _modelsLib = Library('package:idle_pirate/models/item.dart');
const _soundsLib = Library('package:idle_pirate/assets/sounds.dart');

const _staticIconDef = Class('StaticIcon', _assetsLib);
const _dynamicIconDef = Class('DynamicIcon', _assetsLib);
const _itemDef = Class('Item', _modelsLib);
const _soundDef = Class('Sound', _soundsLib);

const _itemCategory = 'item';

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

    final usedStaticImages = _usedStaticImages(usages);
    final usedItems = _usedItems(usages);
    final usedSounds = _usedSounds(usages);

    final idsPerCategory = {_itemCategory: usedItems};

    final usedDynamicImages = _usedDynamicImages(usages, idsPerCategory);

    final usedImages = {...usedStaticImages, ...usedDynamicImages};

    final imageAssets = _imageAssets(input.assets.data);
    final soundAssets = _soundAssets(input.assets.data);

    final (handledImages, imageDeps) = await _treeShakeImages(
      imageAssets,
      usedImages,
      input.outputDirectoryShared,
    );
    final (handledSounds, soundDeps) = _treeShakeSounds(
      soundAssets,
      usedSounds,
    );

    output.assets.data.addAll(handledImages);
    output.assets.data.addAll(handledSounds);

    output.dependencies.addAll(imageDeps);
    output.dependencies.addAll(soundDeps);

    // Produce and route category IDs to pirate_speak!
    final categoryIds = PirateSpeakCategoryIds({
      'item': usedItems.toList(),
    });
    await categoryIds.sendToLinkHook(output, input.outputDirectoryShared);

    _handleOtherAssets(input.assets.data, output);
  });
}

void _checkCategories(Iterable<String> categories, String sourceName) {
  final unknown = categories.where((k) => k != _itemCategory).toList();
  if (unknown.isNotEmpty) {
    throw StateError(
      'Unknown categories in $sourceName: $unknown. You need to handle these in the link hook.',
    );
  }
}

Map<String, double> _usedStaticImages(Recordings usages) {
  final iconSizes = <String, double>{};
  final staticInstances = usages.instances[_staticIconDef];
  if (staticInstances == null) {
    throw StateError(
      'No recordings found for $_staticIconDef. You need to handle this in the link hook.',
    );
  }
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
        throw StateError('Cannot safely parse StaticIcon instance: $instance');
    }
  }
  return iconSizes;
}

Map<String, double> _usedDynamicImages(
  Recordings usages,
  Map<String, Set<String>> idsPerCategory,
) {
  final usedImages = <String, double>{};
  final usedCategories = <String>{};
  final dynamicInstances = usages.instances[_dynamicIconDef];
  if (dynamicInstances == null) {
    throw StateError(
      'No recordings found for $_dynamicIconDef. You need to handle this in the link hook.',
    );
  }
  for (final instance in dynamicInstances) {
    final String category;
    final double size;

    switch (instance) {
      case InstanceCreationReference(
        positionalArguments: [
          _, // id
          DoubleConstant(value: final s),
          StringConstant(value: final c),
        ],
      ):
        category = c;
        size = s;
      case InstanceConstantReference(
        instanceConstant: InstanceConstant(
          fields: {
            'size': DoubleConstant(value: final s),
            'category': StringConstant(value: final c),
          },
        ),
      ):
        category = c;
        size = s;
      case _:
        throw StateError('Cannot safely parse DynamicIcon instance: $instance');
    }

    usedCategories.add(category);

    if (!idsPerCategory.containsKey(category)) {
      throw StateError(
        'Unknown category in DynamicIcon: $category. You need to handle this in the link hook.',
      );
    }

    final ids = idsPerCategory[category] ?? {};
    for (final id in ids) {
      usedImages[id] = size;
    }
  }

  _checkCategories(usedCategories, '$_dynamicIconDef');

  return usedImages;
}

Set<String> _usedItems(Recordings usages) {
  final usedItemIds = <String>{};
  final itemInstances = usages.instances[_itemDef];
  if (itemInstances == null) {
    throw StateError(
      'No recordings found for $_itemDef. You need to handle this in the link hook.',
    );
  }
  for (final instance in itemInstances) {
    switch (instance) {
      case InstanceConstantReference(
        instanceConstant: InstanceConstant(
          fields: {'id': StringConstant(value: final id)},
        ),
      ):
        usedItemIds.add(id);
      case InstanceCreationReference(
        namedArguments: {'id': StringConstant(value: final id)},
      ):
        usedItemIds.add(id);
      case _:
        throw StateError('Cannot safely parse Item instance: $instance');
    }
  }
  return usedItemIds;
}

Set<String> _usedSounds(Recordings usages) {
  final usedSoundIds = <String>{};
  final soundInstances = usages.instances[_soundDef];
  if (soundInstances == null) {
    throw StateError(
      'No recordings found for $_soundDef. You need to handle this in the link hook.',
    );
  }
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
        // Ignore non-const calls
        break;
      case _:
        throw StateError('Cannot safely parse Sound instance: $instance');
    }
  }
  return usedSoundIds;
}

Iterable<DataAsset> _imageAssets(Iterable<DataAsset> assets) =>
    assets.where((a) => a.name.startsWith('assets/images/'));

Iterable<DataAsset> _soundAssets(Iterable<DataAsset> assets) =>
    assets.where((a) => a.name.startsWith('assets/sounds/'));

void _handleOtherAssets(Iterable<DataAsset> assets, LinkOutputBuilder output) {
  final otherAssets = assets.where(
    (a) =>
        !a.name.startsWith('assets/images/') &&
        !a.name.startsWith('assets/translations/') &&
        !a.name.startsWith('assets/sounds/'),
  );

  for (final asset in otherAssets) {
    print('Unknown asset type: ${asset.name}');
    output.assets.data.add(asset);
  }
}

Future<(List<DataAsset>, Set<Uri>)> _treeShakeImages(
  Iterable<DataAsset> assets,
  Map<String, double> usedImages,
  Uri baseOutputDir,
) async {
  final outputAssets = <DataAsset>[];
  final dependencies = <Uri>{};

  if (imageTreeShakingLevel == imageTreeShakingNone) {
    outputAssets.addAll(assets);
    dependencies.addAll(assets.map((e) => e.file));
    return (outputAssets, dependencies);
  }

  // Check for missing image assets
  for (final id in usedImages.keys) {
    final assetName = 'assets/images/$id.png';
    if (!assets.any((a) => a.name == assetName)) {
      throw StateError(
        'Missing image asset for ID: $id. Expected $assetName',
      );
    }
  }

  final outputDir = Directory.fromUri(baseOutputDir.resolve('images/'));
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  for (final asset in assets) {
    final filename = asset.name.split('/').last;
    final id = filename.split('.').first;

    if (usedImages.containsKey(id)) {
      dependencies.add(asset.file);
      if (imageTreeShakingLevel == imageTreeShakingFilterOnly) {
        outputAssets.add(asset);
        continue;
      }

      final logicalSize = usedImages[id]!;
      final targetSize = (logicalSize * 3.0).toInt();
      final sizeStr = '${targetSize}x$targetSize';

      final sourceFile = File.fromUri(asset.file);
      final outputFile = File.fromUri(outputDir.uri.resolve(filename));

      if (await _shouldResize(sourceFile, outputFile)) {
        final success = await _resizeIcon(sourceFile, outputFile, sizeStr);
        if (!success) {
          outputAssets.add(asset);
          continue;
        }
      } else {
        print('Asset ${asset.name} is up to date, skipping resize.');
      }

      outputAssets.add(
        DataAsset(
          package: asset.package,
          name: asset.name,
          file: outputFile.uri,
        ),
      );
    } else {
      print('Filtering out icon: ${asset.name}');
    }
  }
  return (outputAssets, dependencies);
}

(List<DataAsset>, Set<Uri>) _treeShakeSounds(
  Iterable<DataAsset> assets,
  Set<String> usedSounds,
) {
  final outputAssets = <DataAsset>[];
  final dependencies = <Uri>{};

  if (!enableAudioTreeShaking) {
    outputAssets.addAll(assets);
    dependencies.addAll(assets.map((e) => e.file));
    return (outputAssets, dependencies);
  }

  for (final asset in assets) {
    final filename = asset.name.split('/').last;
    final id = filename.split('.').first;

    dependencies.add(asset.file);
    if (usedSounds.contains(id)) {
      print('Keeping sound: ${asset.name}');
      outputAssets.add(asset);
    } else {
      print('Filtering out sound: ${asset.name}');
    }
  }
  return (outputAssets, dependencies);
}

Future<bool> _resizeIcon(File source, File target, String sizeStr) async {
  print('Resizing asset: ${source.path} to $sizeStr');
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
