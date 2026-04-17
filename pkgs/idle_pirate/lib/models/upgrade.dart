class Upgrade {
  final String id;
  final String name;
  final int baseCost;
  final int benefit;

  Upgrade({
    required this.id,
    required this.name,
    required this.baseCost,
    required this.benefit,
  });
}

// Initial upgrades for Milestone 1
final List<Upgrade> initialUpgrades = [
  Upgrade(id: 'sharper_hooks', name: 'Sharper Hooks', baseCost: 10, benefit: 1),
  Upgrade(
    id: 'better_shovels',
    name: 'Better Shovels',
    baseCost: 500,
    benefit: 5,
  ),
  Upgrade(id: 'heavy_boots', name: 'Heavy Boots', baseCost: 5000, benefit: 25),
];

// Passive Generators (The Crew) for Milestone 3
final List<Upgrade> initialGenerators = [
  Upgrade(id: 'cabin_boy', name: 'Cabin Boy', baseCost: 15, benefit: 1),
  Upgrade(id: 'gunner', name: 'Gunner', baseCost: 500, benefit: 15),
  Upgrade(
    id: 'quartermaster',
    name: 'Quartermaster',
    baseCost: 8000,
    benefit: 100,
  ),
];

// Passive Generators (The Fleet) for Milestone 4 (or extension)
final List<Upgrade> initialFleet = [
  Upgrade(id: 'sloop', name: 'Sloop', baseCost: 50000, benefit: 500),
  Upgrade(
    id: 'brigantine',
    name: 'Brigantine',
    baseCost: 250000,
    benefit: 3000,
  ),
  Upgrade(id: 'frigate', name: 'Frigate', baseCost: 1000000, benefit: 15000),
];
