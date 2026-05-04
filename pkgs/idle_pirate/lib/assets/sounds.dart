import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';
import '../models/item.dart';

@RecordUse()
final class Sound {
  final String id;
  const Sound._(@mustBeConst this.id);

  static const areYouLooking = Sound._('are you looking at me treasure');
  static const boot = Sound._('boot');
  static const coin = Sound._('coin');
  static const gunner = Sound._('gunner');
  static const hook = Sound._('hook');
  static const musicLoop = Sound._('pirate music loop');
  static const raiseTheSails = Sound._('raise the sails');
  static const shiverMeTimbers = Sound._('shiver me timbers');
  static const shovel = Sound._('shovel');
  static const yarr = Sound._('yarr');

  static final used = {
    ...itemSounds.values,
    coin,
  };

  Future<ByteData> load() {
    return rootBundle.load('assets/sounds/$id.mp3');
  }
}

final Map<String, Sound> itemSounds = {
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
