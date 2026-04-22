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

    final usedIconIds = <String>{};

    // Find the class ID for GameIcon
    dynamic gameIconKey;
    for (final key in usages.instances.keys) {
      if (key.toString().contains('GameIcon')) {
        gameIconKey = key;
        break;
      }
    }

    if (gameIconKey != null) {
      final instances = usages.instances[gameIconKey] ?? [];
      for (final instance in instances) {
        switch (instance) {
          case InstanceConstantReference(
            instanceConstant: InstanceConstant(
              fields: {'id': StringConstant(value: final id)},
            ),
          ):
            usedIconIds.add(id);
          case _:
            stderr.writeln(
              'Cannot safely treeshake GameIcon instances, bailing on treeshaking.',
            );
            output.assets.data.addAll(input.assets.data);
            return;
        }
      }
    }

    print('Used icon IDs: $usedIconIds');

    await _processAssets(input, output, usedIconIds);
  });
}

Future<void> _processAssets(
  LinkInput input,
  LinkOutputBuilder output,
  Set<String> usedIconIds,
) async {
  // Extract maxLogicalIconSize from game_screen.dart
  final gameScreenFile = File.fromUri(
    input.packageRoot.resolve('lib/ui/screens/game_screen.dart'),
  );
  final content = await gameScreenFile.readAsString();
  final match = RegExp(r'maxLogicalIconSize\s*=\s*(\d+\.?\d*)').firstMatch(content);
  if (match == null) {
    throw StateError('Could not find maxLogicalIconSize in game_screen.dart');
  }
  final maxLogicalSize = double.parse(match.group(1)!);
  final targetSize = (maxLogicalSize * 3.0).toInt();
  final sizeStr = '${targetSize}x$targetSize';

  // Use a known subdirectory of outputDirectoryShared
  final assetsDir = Directory.fromUri(input.outputDirectoryShared.resolve('icons/'));
  if (!assetsDir.existsSync()) {
    assetsDir.createSync(recursive: true);
  }

  for (final asset in input.assets.data) {
    final filename = asset.name.split('/').last;
    final id = filename.split('.').first;

    if (usedIconIds.contains(id)) {
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
