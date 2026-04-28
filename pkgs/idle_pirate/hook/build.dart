import 'dart:io';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    if (input.config.buildAssetTypes.contains('data_assets/data')) {
      final assetsDir = Directory.fromUri(
        input.packageRoot.resolve('assets/images'),
      );
      if (assetsDir.existsSync()) {
        final files = assetsDir.listSync();
        for (final file in files) {
          if (file is File) {
            final filename = file.uri.pathSegments.last;
            output.assets.data.add(
              DataAsset(
                package: input.packageName,
                name: 'assets/images/$filename',
                file: file.uri,
              ),
              routing: input.config.linkingEnabled
                  ? ToLinkHook(input.packageName)
                  : const ToAppBundle(),
            );
          }
        }
      }

      final soundsDir = Directory.fromUri(
        input.packageRoot.resolve('assets/sounds'),
      );
      if (soundsDir.existsSync()) {
        final files = soundsDir.listSync();
        for (final file in files) {
          if (file is File) {
            final filename = file.uri.pathSegments.last;
            output.assets.data.add(
              DataAsset(
                package: input.packageName,
                name: 'assets/sounds/$filename',
                file: file.uri,
              ),
              routing: input.config.linkingEnabled
                  ? ToLinkHook(input.packageName)
                  : const ToAppBundle(),
            );
          }
        }
      }

      final translationsDir = Directory.fromUri(
        input.packageRoot.resolve('assets/translations'),
      );
      if (translationsDir.existsSync()) {
        output.dependencies.add(translationsDir.uri);
        final requestedLanguages = _getRequestedLanguages(input);
        final files = translationsDir.listSync();
        for (final file in files) {
          if (file is File) {
            output.dependencies.add(file.uri);
            final filename = file.uri.pathSegments.last;
            final lang = filename.split('.').first;

            if (requestedLanguages != null &&
                !requestedLanguages.contains(lang)) {
              // ignore: avoid_print
              print('Skipping translation file not requested: $filename');
              continue;
            }

            output.assets.data.add(
              DataAsset(
                package: input.packageName,
                name: 'assets/translations/$filename',
                file: file.uri,
              ),
              routing: input.config.linkingEnabled
                  ? ToLinkHook(input.packageName)
                  : const ToAppBundle(),
            );
          }
        }
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
