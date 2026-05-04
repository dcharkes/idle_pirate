import 'dart:io';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    if (input.config.buildAssetTypes.contains('data_assets/data')) {
      final assets = [
        ..._discoverAssets(
          input.packageRoot,
          input.packageName,
          'assets/images',
        ),
        ..._discoverAssets(
          input.packageRoot,
          input.packageName,
          'assets/sounds',
        ),
      ];

      output.dependencies.addAll(assets.map((a) => a.file));
      output.dependencies.addAll([
        input.packageRoot.resolve('assets/images'),
        input.packageRoot.resolve('assets/sounds'),
      ]);

      for (final asset in assets) {
        output.assets.data.add(
          asset,
          routing: input.config.linkingEnabled
              ? ToLinkHook(input.packageName)
              : const ToAppBundle(),
        );
      }
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
      if (file is File) {
        final filename = file.uri.pathSegments.last;
        assets.add(
          DataAsset(
            package: packageName,
            name: '$path/$filename',
            file: file.uri,
          ),
        );
      }
    }
  }
  return assets;
}
