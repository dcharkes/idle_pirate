import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../models/item.dart';

@RecordUse()
final class StaticIcon {
  final String id;
  final double size;

  const StaticIcon(@mustBeConst this.id, @mustBeConst this.size);

  Widget get image => Image.asset(
    'assets/images/$id.png',
    package: 'idle_pirate',
    width: size,
    height: size,
    errorBuilder: (context, error, stackTrace) {
      return Icon(_getIconForId(id));
    },
  );
}

@RecordUse()
final class DynamicIcon {
  final String id;
  final double size;
  final String category;

  const DynamicIcon(
    this.id,

    @mustBeConst this.size,

    @mustBeConst this.category,
  );

  Widget get image => Image.asset(
    'assets/images/$id.png',
    package: 'idle_pirate',
    width: size,
    height: size,
    errorBuilder: (context, error, stackTrace) {
      return Icon(_getIconForId(id));
    },
  );
}

final Map<String, IconData> _iconData = {
  Item.sharperHooks.id: Icons.fitness_center,
  Item.betterShovels.id: Icons.agriculture,
  Item.heavyBoots.id: Icons.directions_walk,
  Item.cabinBoy.id: Icons.person,
  Item.gunner.id: Icons.security,
  Item.quartermaster.id: Icons.star,
  Item.sloop.id: Icons.directions_boat,
  Item.brigantine.id: Icons.directions_boat,
  Item.frigate.id: Icons.directions_boat,
  'doubloon': Icons.monetization_on,
  'chest': Icons.archive,
};

IconData _getIconForId(String id) {
  return _iconData[id] ?? Icons.help_outline;
}
