import 'dart:io';
import 'package:pirate_speak/src/category_ids.dart';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';

import 'package:record_use/record_use.dart';

import '../../../tree_shaking_config.dart';

void main(List<String> args) async {
  await link(args, (input, output) async {
    if (!input.config.buildDataAssets) return;

    final usages = input.recordedUses;
    final dataAssets = input.assets.data;

    if (usages == null) {
      // No recorded uses found. Bailing on treeshaking and including all assets.
      output.assets.data.addAll(dataAssets);
      output.dependencies.addAll(dataAssets.map((a) => a.file));
      return;
    }

    treeshakeSounds(dataAssets, usages, output);

    final usedItems = _usedItems(usages);

    await treeshakeImages(dataAssets, usages, usedItems, input, output);

    await treeshakeTranslations(usedItems, output, input);

    _handleOtherAssets(dataAssets, output);
  });
}

void treeshakeSounds(
  Iterable<DataAsset> dataAssets,
  Recordings usages,
  LinkOutputBuilder output,
) {
  final soundAssets = _soundAssets(dataAssets);
  if (!enableAudioTreeShaking) {
    output.assets.data.addAll(soundAssets);
    output.dependencies.addAll(soundAssets.map((e) => e.file));
    return;
  }

  final usedSounds = _usedSounds(usages);
  final (filteredSounds, soundDeps) = _filterSounds(
    soundAssets,
    usedSounds,
  );
  output.assets.data.addAll(filteredSounds);
  output.dependencies.addAll(soundDeps);
}

Iterable<DataAsset> _soundAssets(Iterable<DataAsset> assets) =>
    assets.where((a) => a.name.startsWith('assets/sounds/'));

Set<String> _usedSounds(Recordings usages) {
  const soundDef = Class(
    'Sound',
    Library('package:idle_pirate/assets/sounds.dart'),
  );
  final soundInstances = usages.instances[soundDef];
  if (soundInstances == null) {
    throw ArgumentError(
      'No recordings found for $soundDef. You need to handle this in the link hook.',
    );
  }

  return {
    for (final instance in soundInstances)
      switch (instance) {
        InstanceConstantReference(
          instanceConstant: InstanceConstant(
            fields: {'id': StringConstant(value: final id)},
          ),
        ) =>
          id,
        InstanceCreationReference(
          positionalArguments: [StringConstant(value: final id)],
        ) =>
          id,
        _ => throw UnsupportedError(
          'Non-const identifier for sound: $instance',
        ),
      },
  };
}

(List<DataAsset>, Set<Uri>) _filterSounds(
  Iterable<DataAsset> assets,
  Set<String> usedSounds,
) {
  final outputAssets = <DataAsset>[];
  final dependencies = <Uri>{};
  for (final asset in assets) {
    final filename = asset.name.split('/').last;
    final id = filename.split('.').first;
    if (usedSounds.contains(id)) {
      outputAssets.add(asset);
      dependencies.add(asset.file);
    }
  }
  return (outputAssets, dependencies);
}

Set<String> _usedItems(Recordings usages) {
  const itemDef = Class(
    'Item',
    Library('package:idle_pirate/models/item.dart'),
  );

  final itemInstances = usages.instances[itemDef];
  if (itemInstances == null) {
    throw ArgumentError(
      'No recordings found for $itemDef. You need to handle this in the link hook.',
    );
  }

  return {
    for (final instance in itemInstances)
      switch (instance) {
        InstanceConstantReference(
          instanceConstant: InstanceConstant(
            fields: {'id': StringConstant(value: final id)},
          ),
        ) =>
          id,
        InstanceCreationReference(
          namedArguments: {'id': StringConstant(value: final id)},
        ) =>
          id,
        _ => throw UnsupportedError(
          'Cannot safely parse Item instance: $instance',
        ),
      },
  };
}

Future<void> treeshakeImages(
  Iterable<DataAsset> dataAssets,
  Recordings usages,
  Set<String> usedItems,
  LinkInput input,
  LinkOutputBuilder output,
) async {
  final imageAssets = _imageAssets(dataAssets);
  if (imageTreeShakingLevel == imageTreeShakingNone) {
    output.assets.data.addAll(imageAssets);
    output.dependencies.addAll(imageAssets.map((e) => e.file));
    return;
  }

  final usedStaticImages = _usedStaticImages(usages);
  final idsPerCategory = {_itemCategory: usedItems};
  final usedDynamicImages = _usedDynamicImages(usages, idsPerCategory);
  final usedImages = {...usedStaticImages, ...usedDynamicImages};
  final (filteredImages, imageDeps) = await _filterAndResizeImages(
    imageAssets,
    usedImages,
    input.outputDirectoryShared,
  );
  output.assets.data.addAll(filteredImages);
  output.dependencies.addAll(imageDeps);
}

Iterable<DataAsset> _imageAssets(Iterable<DataAsset> assets) =>
    assets.where((a) => a.name.startsWith('assets/images/'));

const _imagesLib = Library('package:idle_pirate/assets/images.dart');

Map<String, double> _usedStaticImages(Recordings usages) {
  const staticIconDef = Class('StaticIcon', _imagesLib);

  final staticInstances = usages.instances[staticIconDef];
  if (staticInstances == null) {
    throw ArgumentError(
      'No recordings found for $staticIconDef. You need to handle this in the link hook.',
    );
  }

  return {
    for (final instance in staticInstances)
      ...switch (instance) {
        InstanceConstantReference(
          instanceConstant: InstanceConstant(
            fields: {
              'id': StringConstant(value: final id),
              'size': DoubleConstant(value: final size),
            },
          ),
        ) =>
          {id: size},
        InstanceCreationReference(
          positionalArguments: [
            StringConstant(value: final id),
            DoubleConstant(value: final size),
          ],
        ) =>
          {id: size},
        _ => throw UnsupportedError(
          'Cannot safely parse StaticIcon instance: $instance',
        ),
      },
  };
}

Map<String, double> _usedDynamicImages(
  Recordings usages,
  Map<String, Set<String>> idsPerCategory,
) {
  const dynamicIconDef = Class('DynamicIcon', _imagesLib);
  final dynamicInstances = usages.instances[dynamicIconDef];
  if (dynamicInstances == null) {
    throw ArgumentError(
      'No recordings found for $dynamicIconDef. You need to handle this in the link hook.',
    );
  }

  final parsed = [
    for (final instance in dynamicInstances)
      switch (instance) {
        InstanceCreationReference(
          positionalArguments: [
            _,
            DoubleConstant(value: final size),
            StringConstant(value: final category),
          ],
        ) =>
          (category: category, size: size),
        InstanceConstantReference(
          instanceConstant: InstanceConstant(
            fields: {
              'size': DoubleConstant(value: final size),
              'category': StringConstant(value: final category),
            },
          ),
        ) =>
          (category: category, size: size),
        _ => throw UnsupportedError(
          'Cannot safely parse DynamicIcon instance: $instance',
        ),
      },
  ];

  _checkCategories(parsed.map((e) => e.category).toSet(), '$dynamicIconDef');

  for (final p in parsed) {
    if (!idsPerCategory.containsKey(p.category)) {
      throw UnsupportedError(
        'Unknown category in DynamicIcon: ${p.category}. You need to handle this in the link hook.',
      );
    }
  }

  return {
    for (final p in parsed)
      for (final id in idsPerCategory[p.category] ?? <String>{}) id: p.size,
  };
}

Future<(List<DataAsset>, Set<Uri>)> _filterAndResizeImages(
  Iterable<DataAsset> assets,
  Map<String, double> usedImages,
  Uri outputDirectoryShared,
) async {
  // Check for missing image assets
  final assetNames = assets.map((a) => a.name).toSet();
  final missingImages = [
    for (final id in usedImages.keys)
      if (!assetNames.contains('assets/images/$id.png'))
        'assets/images/$id.png',
  ];
  if (missingImages.isNotEmpty) {
    throw ArgumentError('Missing image assets: $missingImages');
  }

  final outputDir = Directory.fromUri(outputDirectoryShared.resolve('images/'));
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outputAssets = <DataAsset>[];
  final dependencies = <Uri>{};
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
      const devicePixelRatio = 3.0;
      final targetSize = (logicalSize * devicePixelRatio).toInt();
      final sizeStr = '${targetSize}x$targetSize';

      final sourceFile = File.fromUri(asset.file);
      final outputFile = File.fromUri(outputDir.uri.resolve(filename));

      if (await _shouldResize(sourceFile, outputFile)) {
        await _resizeIcon(sourceFile, outputFile, sizeStr);
      } else {
        // Asset ${asset.name} is up to date, skipping resize.
      }

      outputAssets.add(
        DataAsset(
          package: asset.package,
          name: asset.name,
          file: outputFile.uri,
        ),
      );
    } else {
      // Filtering out icon: ${asset.name}
    }
  }
  return (outputAssets, dependencies);
}

Future<void> _resizeIcon(File source, File target, String sizeStr) async {
  // Resizing asset: ${source.path} to $sizeStr
  final result = await Process.run('magick', [
    source.path,
    '-resize',
    sizeStr,
    target.path,
  ]);

  if (result.exitCode != 0) {
    throw UnsupportedError(
      'ImageMagick "magick" command execution failed. Please verify that ImageMagick is installed and available in your system PATH.\n'
      'Error details: Failed to resize asset: ${source.path}\n${result.stderr}',
    );
  }
}

Future<bool> _shouldResize(File source, File target) async {
  if (!target.existsSync()) return true;

  final sourceTime = await source.lastModified();
  final targetTime = await target.lastModified();

  return sourceTime.isAfter(targetTime) ||
      sourceTime.isAtSameMomentAs(targetTime);
}

Future<void> treeshakeTranslations(
  Set<String> usedItems,
  LinkOutputBuilder output,
  LinkInput input,
) async {
  // Produce and route category IDs to pirate_speak!
  final categoryIds = PirateSpeakCategoryIds({
    _itemCategory: [...usedItems],
  });
  await categoryIds.sendToLinkHook(output, input.outputDirectoryShared);
}

const _itemCategory = 'item';

void _checkCategories(Iterable<String> categories, String sourceName) {
  final unknown = categories.where((k) => k != _itemCategory).toList();
  if (unknown.isNotEmpty) {
    throw UnsupportedError(
      'Unknown categories in $sourceName: $unknown. You need to handle these in the link hook.',
    );
  }
}

void _handleOtherAssets(Iterable<DataAsset> assets, LinkOutputBuilder output) {
  final otherAssets = assets.where(
    (a) =>
        !a.name.startsWith('assets/images/') &&
        !a.name.startsWith('assets/sounds/'),
  );

  for (final asset in otherAssets) {
    // Unknown asset type: ${asset.name}
    output.assets.data.add(asset);
  }
}
