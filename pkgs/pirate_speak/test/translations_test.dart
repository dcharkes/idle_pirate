import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('All translation JSON files have exactly the same keys', () {
    // Locate the translations directory
    var dir = Directory('assets/translations');
    if (!dir.existsSync()) {
      dir = Directory('pkgs/pirate_speak/assets/translations');
    }

    expect(
      dir.existsSync(),
      isTrue,
      reason: 'Translations directory not found',
    );

    final jsonFiles = dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();

    expect(jsonFiles, isNotEmpty, reason: 'No translation JSON files found');

    // Load en.json first as the reference template
    final enFile = jsonFiles.firstWhere(
      (file) => file.path.endsWith('en.json'),
      orElse: () => jsonFiles.first,
    );

    final enContent = enFile.readAsStringSync();
    final enMap = json.decode(enContent) as Map<String, dynamic>;
    final referenceKeys = enMap.keys.toSet();

    for (final file in jsonFiles) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final content = file.readAsStringSync();
      final map = json.decode(content) as Map<String, dynamic>;
      final currentKeys = map.keys.toSet();

      // Check for missing keys
      final missingKeys = referenceKeys.difference(currentKeys);
      expect(
        missingKeys,
        isEmpty,
        reason:
            'File $fileName is missing keys found in ${enFile.path.split(Platform.pathSeparator).last}: $missingKeys',
      );

      // Check for extra keys
      final extraKeys = currentKeys.difference(referenceKeys);
      expect(
        extraKeys,
        isEmpty,
        reason:
            'File $fileName has extra keys not found in ${enFile.path.split(Platform.pathSeparator).last}: $extraKeys',
      );
    }
  });
}
