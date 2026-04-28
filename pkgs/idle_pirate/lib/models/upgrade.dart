import 'package:meta/meta.dart';

extension type const Doubloon(int value) {
  Doubloon operator *(int multiplier) => Doubloon(value * multiplier);
  Doubloon operator +(Doubloon other) => Doubloon(value + other.value);
}

// ignore: experimental_member_use
@RecordUse()
final class Upgrade {
  final String id;
  final Doubloon baseCost;
  final Doubloon benefit;
  final Duration? duration;

  const Upgrade({
    // ignore: experimental_member_use
    @mustBeConst required this.id,
    required this.baseCost,
    required this.benefit,
    this.duration,
  });
}

const List<Upgrade> initialUpgrades = [
  Upgrade(
    id: 'sharper_hooks',
    baseCost: Doubloon(10),
    benefit: Doubloon(1),
  ),
  Upgrade(
    id: 'better_shovels',
    baseCost: Doubloon(500),
    benefit: Doubloon(5),
  ),
  Upgrade(
    id: 'heavy_boots',
    baseCost: Doubloon(5000),
    benefit: Doubloon(25),
  ),
];

const List<Upgrade> initialGenerators = [
  Upgrade(
    id: 'cabin_boy',
    baseCost: Doubloon(15),
    benefit: Doubloon(1),
    duration: Duration(seconds: 2),
  ),
  Upgrade(
    id: 'gunner',
    baseCost: Doubloon(500),
    benefit: Doubloon(15),
    duration: Duration(seconds: 5),
  ),
  Upgrade(
    id: 'quartermaster',
    baseCost: Doubloon(8000),
    benefit: Doubloon(100),
    duration: Duration(seconds: 10),
  ),
];

const List<Upgrade> initialFleet = [
  Upgrade(
    id: 'sloop',
    baseCost: Doubloon(50000),
    benefit: Doubloon(500),
    duration: Duration(seconds: 20),
  ),
  Upgrade(
    id: 'brigantine',
    baseCost: Doubloon(250000),
    benefit: Doubloon(3000),
    duration: Duration(minutes: 1),
  ),
  Upgrade(
    id: 'frigate',
    baseCost: Doubloon(1000000),
    benefit: Doubloon(15000),
    duration: Duration(minutes: 2),
  ),
];
