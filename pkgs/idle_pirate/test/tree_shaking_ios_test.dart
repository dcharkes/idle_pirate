// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'iOS app native assets tree shaking integration test',
    () async {
      // 1. Clean the previous build artifacts
      print('Running flutter clean...');
      final cleanResult = await Process.run('flutter', ['clean']);
      expect(
        cleanResult.exitCode,
        0,
        reason: 'flutter clean failed: ${cleanResult.stderr}',
      );

      // 2. Build the iOS application bundle without codesigning
      print('Running flutter build ios --no-codesign...');
      final buildResult = await Process.run('flutter', [
        'build',
        'ios',
        '--no-codesign',
      ]);
      expect(
        buildResult.exitCode,
        0,
        reason: 'flutter build ios failed: ${buildResult.stderr}',
      );

      // 3. Verify the bundle directory exists
      final appDir = Directory('build/ios/iphoneos/Runner.app');
      expect(
        appDir.existsSync(),
        true,
        reason: 'Runner.app bundle does not exist at ${appDir.path}',
      );

      // 4. Calculate the total size of the app bundle recursively
      int totalSizeBytes = 0;
      for (final entity in appDir.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          totalSizeBytes += entity.lengthSync();
        }
      }

      final double totalSizeMB = totalSizeBytes / 1000000;
      print(
        'Built Runner.app size: ${totalSizeMB.toStringAsFixed(1)}MB ($totalSizeBytes bytes)',
      );

      // Expect the app size to be exactly 17217870 bytes. If the app grows/shrinks, this can be updated.
      const int expectedSizeBytes = 17217870;
      expect(
        totalSizeBytes,
        expectedSizeBytes,
        reason:
            'App bundle size changed. Expected $expectedSizeBytes bytes, got $totalSizeBytes bytes.',
      );

      // 5. Verify the tree-shaken flutter assets directory
      final imagesDir = Directory(
        'build/ios/iphoneos/Runner.app/Frameworks/App.framework/flutter_assets/packages/idle_pirate/assets/images',
      );
      expect(
        imagesDir.existsSync(),
        true,
        reason: 'Tree-shaken images directory not found at ${imagesDir.path}',
      );

      final imageFiles = imagesDir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList();

      print('Tree-shaken images count: ${imageFiles.length}');
      print('Included image assets: $imageFiles');

      // Assert exactly 11 images remain out of the original 31 image assets
      expect(
        imageFiles.length,
        11,
        reason:
            'Expected exactly 11 tree-shaken images, found ${imageFiles.length}',
      );

      // Verify specific expected inclusions (used in the game)
      expect(
        imageFiles.contains('better_shovels.png'),
        true,
        reason: 'better_shovels.png should be included',
      );
      expect(
        imageFiles.contains('sloop.png'),
        true,
        reason: 'sloop.png should be included',
      );
      expect(
        imageFiles.contains('cabin_boy.png'),
        true,
        reason: 'cabin_boy.png should be included',
      );

      // Verify specific expected exclusions (unused in the game, successfully tree-shaken)
      expect(
        imageFiles.contains('anchor.png'),
        false,
        reason: 'anchor.png should be tree-shaken out',
      );
      expect(
        imageFiles.contains('barrel.png'),
        false,
        reason: 'barrel.png should be tree-shaken out',
      );
      expect(
        imageFiles.contains('kraken.png'),
        false,
        reason: 'kraken.png should be tree-shaken out',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
    skip: !Platform.isMacOS
        ? 'iOS builds can only be performed on macOS hosts'
        : false,
  );
}
