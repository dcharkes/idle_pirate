import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';
import '../models/item.dart';

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

final Map<String, Sound> upgradeSounds = {
  Item.sharperHooks.id: Sound.hook,
  Item.betterShovels.id: Sound.shovel,
  Item.heavyBoots.id: Sound.boot,
  Item.gunner.id: Sound.gunner,
  Item.cabinBoy.id: Sound.yarr,
  Item.quartermaster.id: Sound.shiverMeTimbers,
  Item.sloop.id: Sound.raiseTheSails,
  Item.brigantine.id: Sound.raiseTheSails,
  Item.frigate.id: Sound.raiseTheSails,
};
