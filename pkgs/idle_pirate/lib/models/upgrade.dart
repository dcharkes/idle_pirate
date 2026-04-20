import 'package:meta/meta.dart';

// ignore: experimental_member_use
@RecordUse()
class GameIcon {
  final String id;
  // ignore: experimental_member_use
  const GameIcon(@mustBeConst this.id);
}

class Upgrade {
  final GameIcon id;
  final String name;
  final int baseCost;
  final int benefit;

  const Upgrade({
    required this.id,
    required this.name,
    required this.baseCost,
    required this.benefit,
  });
}

// Initial upgrades for Milestone 1
const List<Upgrade> initialUpgrades = [
  Upgrade(
    id: GameIcon('sharper_hooks'),
    name: 'Sharper Hooks',
    baseCost: 10,
    benefit: 1,
  ),
  Upgrade(
    id: GameIcon('better_shovels'),
    name: 'Better Shovels',
    baseCost: 500,
    benefit: 5,
  ),
  Upgrade(
    id: GameIcon('heavy_boots'),
    name: 'Heavy Boots',
    baseCost: 5000,
    benefit: 25,
  ),
];

// Passive Generators (The Crew) for Milestone 3
const List<Upgrade> initialGenerators = [
  Upgrade(
    id: GameIcon('cabin_boy'),
    name: 'Cabin Boy',
    baseCost: 15,
    benefit: 1,
  ),
  Upgrade(id: GameIcon('gunner'), name: 'Gunner', baseCost: 500, benefit: 15),
  Upgrade(
    id: GameIcon('quartermaster'),
    name: 'Quartermaster',
    baseCost: 8000,
    benefit: 100,
  ),
];

// Passive Generators (The Fleet) for Milestone 4 (or extension)
const List<Upgrade> initialFleet = [
  Upgrade(id: GameIcon('sloop'), name: 'Sloop', baseCost: 50000, benefit: 500),
  Upgrade(
    id: GameIcon('brigantine'),
    name: 'Brigantine',
    baseCost: 250000,
    benefit: 3000,
  ),
  Upgrade(
    id: GameIcon('frigate'),
    name: 'Frigate',
    baseCost: 1000000,
    benefit: 15000,
  ),
];
