// ignore_for_file: avoid_print

import 'dart:io';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    print('linkingEnabled: ${input.config.linkingEnabled}');

    final requestedLanguages = _getRequestedLanguages(input);

    final allAssets = _discoverAssets(
      input.packageRoot,
      input.packageName,
      'assets/translations',
    );

    final assets = _filterByLanguage(allAssets, requestedLanguages);

    output.dependencies.addAll(assets.map((a) => a.file));

    for (final asset in assets) {
      output.assets.data.add(
        asset,
        routing: input.config.linkingEnabled
            ? ToLinkHook(input.packageName)
            : const ToAppBundle(),
      );
    }
  });
}

List<DataAsset> _discoverAssets(
  Uri packageRoot,
  String packageName,
  String path,
) {
  final assets = <DataAsset>[];
  final dir = Directory.fromUri(
    packageRoot.resolve(path),
  );
  if (dir.existsSync()) {
    final files = dir.listSync();
    for (final file in files) {
      if (file is File && file.path.endsWith('.json')) {
        final filename = file.uri.pathSegments.last;
        assets.add(
          DataAsset(
            package: packageName,
            name: '$path/$filename',
            file: file.absolute.uri,
          ),
        );
      }
    }
  }
  return assets;
}

List<DataAsset> _filterByLanguage(
  List<DataAsset> assets,
  Set<String>? requestedLanguages,
) {
  return assets.where((a) {
    final lang = a.name.split('/').last.split('.').first;
    if (requestedLanguages != null && !requestedLanguages.contains(lang)) {
      print('Skipping translation file not requested: ${a.name}');
      return false;
    }
    return true;
  }).toList();
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
