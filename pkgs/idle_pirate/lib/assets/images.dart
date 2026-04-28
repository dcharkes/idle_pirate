import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../models/upgrade.dart';

// ignore: experimental_member_use
@RecordUse()
final class StaticIcon {
  final String id;
  final double size;
  // ignore: experimental_member_use
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

// ignore: experimental_member_use
@RecordUse()
final class DynamicIcon {
  final String id;
  final double size;
  final String category;
  // ignore: experimental_member_use
  const DynamicIcon(
    this.id,
    // ignore: experimental_member_use
    @mustBeConst this.size,
    // ignore: experimental_member_use
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
  Upgrade.sharperHooks.id: Icons.fitness_center,
  Upgrade.betterShovels.id: Icons.agriculture,
  Upgrade.heavyBoots.id: Icons.directions_walk,
  Upgrade.cabinBoy.id: Icons.person,
  Upgrade.gunner.id: Icons.security,
  Upgrade.quartermaster.id: Icons.star,
  Upgrade.sloop.id: Icons.directions_boat,
  Upgrade.brigantine.id: Icons.directions_boat,
  Upgrade.frigate.id: Icons.directions_boat,
  'doubloon': Icons.monetization_on,
  'chest': Icons.archive,
};

IconData _getIconForId(String id) {
  return _iconData[id] ?? Icons.help_outline;
}
