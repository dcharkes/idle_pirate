import 'dart:math' as math;
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
  final Doubloon reward;
  final Duration? duration;

  const Upgrade({
    // ignore: experimental_member_use
    @mustBeConst required this.id,
    required this.baseCost,
    required this.reward,
    this.duration,
  });

  int getBulkCost(int currentCount, int count) {
    if (count <= 0) return 0;
    final r = 1.15;
    final cost =
        baseCost.value *
        (math.pow(r, currentCount) * (math.pow(r, count) - 1)) /
        (r - 1);
    return cost.toInt();
  }

  int getMaxAffordable(int currentCount, int doubloons) {
    final c = doubloons;
    final b = baseCost.value;
    final r = 1.15;
    final n = currentCount;

    final value = (c * (r - 1)) / (b * math.pow(r, n)) + 1;
    if (value <= 0) return 0;
    final k = (math.log(value) / math.log(r)).floor();
    return math.max(0, k);
  }

  static const sharperHooks = Upgrade(
    id: 'sharper_hooks',
    baseCost: Doubloon(10),
    reward: Doubloon(1),
  );
  static const betterShovels = Upgrade(
    id: 'better_shovels',
    baseCost: Doubloon(500),
    reward: Doubloon(5),
  );
  static const heavyBoots = Upgrade(
    id: 'heavy_boots',
    baseCost: Doubloon(5000),
    reward: Doubloon(25),
  );

  static const cabinBoy = Upgrade(
    id: 'cabin_boy',
    baseCost: Doubloon(15),
    reward: Doubloon(1),
    duration: Duration(seconds: 2),
  );
  static const gunner = Upgrade(
    id: 'gunner',
    baseCost: Doubloon(500),
    reward: Doubloon(15),
    duration: Duration(seconds: 5),
  );
  static const quartermaster = Upgrade(
    id: 'quartermaster',
    baseCost: Doubloon(8000),
    reward: Doubloon(100),
    duration: Duration(seconds: 10),
  );

  static const sloop = Upgrade(
    id: 'sloop',
    baseCost: Doubloon(50000),
    reward: Doubloon(500),
    duration: Duration(seconds: 20),
  );
  static const brigantine = Upgrade(
    id: 'brigantine',
    baseCost: Doubloon(250000),
    reward: Doubloon(3000),
    duration: Duration(minutes: 1),
  );
  static const frigate = Upgrade(
    id: 'frigate',
    baseCost: Doubloon(1000000),
    reward: Doubloon(15000),
    duration: Duration(minutes: 2),
  );

  static const equipment = [
    sharperHooks,
    betterShovels,
    heavyBoots,
  ];

  static const personnel = [
    cabinBoy,
    gunner,
    quartermaster,
  ];

  static const fleet = [
    sloop,
    brigantine,
    frigate,
  ];

  static const allGenerators = [
    ...personnel,
    ...fleet,
  ];

  static const all = [
    ...equipment,
    ...allGenerators,
  ];
}
