// ignore_for_file: avoid_print

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

    // 1. Process StaticIcon records
    dynamic staticIconKey;
    for (final key in usages.instances.keys) {
      if (key.toString().contains('StaticIcon')) {
        staticIconKey = key;
        break;
      }
    }
    if (staticIconKey != null) {
      final instances = usages.instances[staticIconKey] ?? [];
      for (final instance in instances) {
        if (instance is InstanceConstantReference) {
          final fields = (instance.instanceConstant as InstanceConstant).fields;
          final id = (fields['id'] as StringConstant).value;
          final size = (fields['size'] as DoubleConstant).value;
          iconSizes[id] = size;
        }
      }
    }

    // 2. Process DynamicIcon records to get category sizes
    final categorySizes = <String, double>{};
    dynamic dynamicIconKey;
    for (final key in usages.instances.keys) {
      if (key.toString().contains('DynamicIcon')) {
        dynamicIconKey = key;
        break;
      }
    }
    if (dynamicIconKey != null) {
      final instances = usages.instances[dynamicIconKey] ?? [];
      for (final instance in instances) {
        if (instance is InstanceCreationReference) {
          final sizeArg = instance.positionalArguments[1];
          final categoryArg = instance.positionalArguments[2];
          if (sizeArg is DoubleConstant && categoryArg is StringConstant) {
            final size = sizeArg.value;
            final category = categoryArg.value;
            categorySizes[category] = size;
          }
        }
      }
    }

    // 3. Process Upgrade records to know which upgrades are used
    final usedUpgradeIds = <String>{};
    dynamic upgradeKey;
    for (final key in usages.instances.keys) {
      if (key.toString().contains('Upgrade')) {
        upgradeKey = key;
        break;
      }
    }
    if (upgradeKey != null) {
      final instances = usages.instances[upgradeKey] ?? [];
      for (final instance in instances) {
        if (instance is InstanceConstantReference) {
          final fields = (instance.instanceConstant as InstanceConstant).fields;
          final id = (fields['id'] as StringConstant).value;
          usedUpgradeIds.add(id);
        }
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

    await _processAssets(input, output, iconSizes);
  });
}

Future<void> _processAssets(
  LinkInput input,
  LinkOutputBuilder output,
  Map<String, double> iconSizes,
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
      print('Filtering out asset: ${asset.name}');
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
