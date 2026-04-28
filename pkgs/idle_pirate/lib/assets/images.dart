import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

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

IconData _getIconForId(String id) {
  switch (id) {
    case 'sharper_hooks':
      return Icons.fitness_center;
    case 'better_shovels':
      return Icons.agriculture;
    case 'heavy_boots':
      return Icons.directions_walk;
    case 'cabin_boy':
      return Icons.person;
    case 'gunner':
      return Icons.security;
    case 'quartermaster':
      return Icons.star;
    case 'sloop':
    case 'brigantine':
    case 'frigate':
      return Icons.directions_boat;
    case 'doubloon':
      return Icons.monetization_on;
    case 'chest':
      return Icons.archive;
    default:
      return Icons.help_outline;
  }
}
