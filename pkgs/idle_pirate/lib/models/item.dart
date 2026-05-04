import 'dart:math' as math;
import 'package:meta/meta.dart';

extension type const Doubloon(int value) {
  Doubloon operator *(int multiplier) => Doubloon(value * multiplier);
  Doubloon operator +(Doubloon other) => Doubloon(value + other.value);

  String get compact {
    if (value < 1000) return '$value';
    if (value < 1000000) return '${(value / 1000).toStringAsFixed(1)}K';
    if (value < 1000000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value < 1000000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    return '${(value / 1000000000000).toStringAsFixed(1)}T';
  }
}

@RecordUse()
final class Item {
  final String id;
  final Doubloon baseCost;
  final Doubloon reward;
  final Duration? duration;

  const Item._({
    required this.id,
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

  bool get isGenerator => duration != null;

  static const sharperHooks = Item._(
    id: 'sharper_hooks',
    baseCost: Doubloon(5),
    reward: Doubloon(1),
  );
  static const betterShovels = Item._(
    id: 'better_shovels',
    baseCost: Doubloon(40),
    reward: Doubloon(4),
  );
  static const heavyBoots = Item._(
    id: 'heavy_boots',
    baseCost: Doubloon(200),
    reward: Doubloon(15),
  );

  static const cabinBoy = Item._(
    id: 'cabin_boy',
    baseCost: Doubloon(500),
    reward: Doubloon(40),
    duration: Duration(seconds: 2),
  );
  static const gunner = Item._(
    id: 'gunner',
    baseCost: Doubloon(1500),
    reward: Doubloon(250),
    duration: Duration(seconds: 5),
  );
  static const quartermaster = Item._(
    id: 'quartermaster',
    baseCost: Doubloon(8000),
    reward: Doubloon(1500),
    duration: Duration(seconds: 10),
  );

  static const sloop = Item._(
    id: 'sloop',
    baseCost: Doubloon(40000),
    reward: Doubloon(9000),
    duration: Duration(seconds: 20),
  );
  static const brigantine = Item._(
    id: 'brigantine',
    baseCost: Doubloon(200000),
    reward: Doubloon(60000),
    duration: Duration(minutes: 1),
  );
  static const frigate = Item._(
    id: 'frigate',
    baseCost: Doubloon(1000000),
    reward: Doubloon(400000),
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
