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
