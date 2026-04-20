import 'dart:convert';
import 'dart:io';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';
// ignore: experimental_member_use
import 'package:record_use/record_use.dart';

void main(List<String> args) async {
  await link(args, (LinkInput input, LinkOutputBuilder output) async {
    // Fallback to reading recordedUsagesFile manually
    // ignore: experimental_member_use
    final usesUri = input.recordedUsagesFile;
    
    if (usesUri == null) {
      print('No recorded uses file found. Bailing on treeshaking and including all assets.');
      output.assets.data.addAll(input.assets.data);
      return;
    }

    final usesJson = await File.fromUri(usesUri).readAsString();
    final usages = Recordings.fromJson(
      jsonDecode(usesJson) as Map<String, Object?>,
    );

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
            stderr.writeln('Cannot safely treeshake GameIcon instances, bailing on treeshaking.');
            output.assets.data.addAll(input.assets.data);
            return;
        }
      }
    }

    print('Used icon IDs: $usedIconIds');

    // Filter assets
    for (final asset in input.assets.data) {
      final filename = asset.name.split('/').last;
      // Assume filename is like 'doubloon.png' and id is 'doubloon'
      final id = filename.split('.').first;
      
      if (usedIconIds.contains(id)) {
        output.assets.data.add(asset);
      } else {
        print('Filtering out asset: ${asset.name}');
      }
    }
  });
}
