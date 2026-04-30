// ignore_for_file: avoid_print

import 'dart:io';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    print('linkingEnabled: ${input.config.linkingEnabled}');
    final dir = Directory('assets/translations/');
    if (!dir.existsSync()) {
      print('Translations directory not found: ${dir.path}');
      return;
    }

    final requestedLanguages = _getRequestedLanguages(input);

    for (final file in dir.listSync()) {
      if (file is File && file.path.endsWith('.json')) {
        final filename = file.uri.pathSegments.last;
        final name = 'assets/translations/$filename';
        final lang = filename.split('.').first;

        if (requestedLanguages != null && !requestedLanguages.contains(lang)) {
          print('Skipping translation file not requested: $filename');
          continue;
        }

        print('Reporting asset: $name');
        output.assets.data.add(
          DataAsset(
            package: 'pirate_speak',
            name: name,
            file: file.absolute.uri,
          ),
          routing: input.config.linkingEnabled
              ? ToLinkHook(input.packageName)
              : const ToAppBundle(),
        );
      }
    }
  });
}

Set<String>? _getRequestedLanguages(BuildInput input) {
  final requestedLanguages = input.userDefines['translations'];
  if (requestedLanguages == null) return null;

  final list = <String>{};
  if (requestedLanguages is List) {
    list.addAll(requestedLanguages.cast<String>());
  } else if (requestedLanguages is String) {
    list.addAll(requestedLanguages.split(',').map((e) => e.trim()));
  }
  return list;
}
