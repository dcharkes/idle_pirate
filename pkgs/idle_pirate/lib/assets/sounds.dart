import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';

// ignore: experimental_member_use
@RecordUse()
final class Sound {
  final String id;
  // ignore: experimental_member_use
  const Sound._(@mustBeConst this.id);

  static const hook = Sound._('hook');
  static const shovel = Sound._('shovel');
  static const boot = Sound._('boot');
  static const gunner = Sound._('gunner');
  static const yarr = Sound._('yarr');
  static const shiverMeTimbers = Sound._('shiver me timbers');
  static const raiseTheSails = Sound._('raise the sails');
  static const coin = Sound._('coin');

  static const all = [
    hook,
    shovel,
    boot,
    gunner,
    yarr,
    shiverMeTimbers,
    raiseTheSails,
    coin,
  ];

  Future<ByteData> load() {
    return rootBundle.load('assets/sounds/$id.mp3');
  }
}

const Map<String, Sound> upgradeSounds = {
  'sharper_hooks': Sound.hook,
  'better_shovels': Sound.shovel,
  'heavy_boots': Sound.boot,
  'gunner': Sound.gunner,
  'cabin_boy': Sound.yarr,
  'quartermaster': Sound.shiverMeTimbers,
  'sloop': Sound.raiseTheSails,
  'brigantine': Sound.raiseTheSails,
  'frigate': Sound.raiseTheSails,
};
