import 'dart:convert';
import 'dart:io';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';

class PirateSpeakCategoryIds {
  static const _assetName = 'pirate_speak_category_ids';
  static const _fileName = 'category_ids.json';
  static const _packageName = 'pirate_speak';

  final Map<String, List<String>> categoryIds;

  PirateSpeakCategoryIds(this.categoryIds);

  Map<String, dynamic> _toJson() => categoryIds;

  factory PirateSpeakCategoryIds._fromJson(Map<String, dynamic> json) {
    return PirateSpeakCategoryIds(
      json.map((key, value) => MapEntry(key, List<String>.from(value))),
    );
  }

  Future<void> sendToLinkHook(
    LinkOutputBuilder output,
    Uri baseOutputDir,
  ) async {
    final file = File.fromUri(baseOutputDir.resolve(_fileName));
    await file.writeAsString(json.encode(_toJson()));

    output.assets.data.add(
      DataAsset(
        package: _packageName,
        name: _assetName,
        file: file.uri,
      ),
      routing: ToLinkHook(_packageName),
    );
  }

  static Future<List<PirateSpeakCategoryIds>> fromInput(LinkInput input) async {
    final assets = input.assets.assetsFromLinking
        .where((e) => e.isDataAsset)
        .map(DataAsset.fromEncoded)
        .where((a) => a.name == _assetName);

    final results = <PirateSpeakCategoryIds>[];
    for (final asset in assets) {
      final file = File.fromUri(asset.file);
      if (file.existsSync()) {
        final jsonStr = await file.readAsString();
        results.add(PirateSpeakCategoryIds._fromJson(json.decode(jsonStr)));
      }
    }
    return results;
  }
}
