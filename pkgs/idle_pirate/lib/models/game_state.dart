import 'item.dart';

class GameState {
  static const _doubloonsKey = 'doubloons';
  static const _itemsKey = 'items';
  static const _progressKey = 'progress';

  final Doubloon doubloons;
  final Map<Item, int> items;
  final Map<Item, double> progress;

  GameState({
    this.doubloons = const Doubloon(0),
    this.items = const {},
    this.progress = const {},
  });

  GameState _copyWith({
    Doubloon? doubloons,
    Map<Item, int>? items,
    Map<Item, double>? progress,
  }) {
    return GameState(
      doubloons: doubloons ?? this.doubloons,
      items: items ?? this.items,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      _doubloonsKey: doubloons.value,
      _itemsKey: items.map((item, count) => MapEntry(item.id, count)),
      _progressKey: progress.map(
        (item, progress) => MapEntry(item.id, progress),
      ),
    };
  }

  static GameState fromJson(Map<String, dynamic> json) {
    final doubloons = Doubloon(json[_doubloonsKey] as int? ?? 0);

    final itemsJson = json[_itemsKey] as Map? ?? {};
    final items = <Item, int>{};
    itemsJson.forEach((key, value) {
      final item = Item.all.firstWhere((u) => u.id == key);
      items[item] = value as int;
    });

    final progressJson = json[_progressKey] as Map? ?? {};
    final progress = <Item, double>{};
    progressJson.forEach((key, value) {
      final item = Item.all.firstWhere((u) => u.id == key);
      progress[item] = value as double;
    });

    return GameState(
      doubloons: doubloons,
      items: items,
      progress: progress,
    );
  }

  GameState buyUpgrades(Item item, int count) {
    final currentCount = items[item] ?? 0;
    final cost = item.getBulkCost(currentCount, count);

    if (doubloons.value >= cost && count > 0) {
      final newItems = Map<Item, int>.from(items);
      newItems[item] = currentCount + count;
      return _copyWith(
        doubloons: Doubloon(doubloons.value - cost),
        items: newItems,
      );
    }
    return this; // Return current state if cannot afford
  }

  GameState elapseTime(Duration elapsed) {
    final elapsedSeconds = elapsed.inMilliseconds.toDouble() / 1000.0;
    int totalEarnings = 0;
    final newProgress = Map<Item, double>.from(progress);
    bool stateChanged = false;

    for (final item in items.keys) {
      final count = items[item] ?? 0;
      if (count > 0) {
        if (item.isGenerator) {
          final duration = item.duration!.inSeconds.toDouble();
          final progress = this.progress[item] ?? 0.0;

          final totalElapsedWithCurrentProgress =
              elapsedSeconds + (progress * duration);
          final fullCycles = (totalElapsedWithCurrentProgress / duration)
              .floor();
          final remainderSeconds = totalElapsedWithCurrentProgress % duration;
          final cycleReward = item.reward.value * count * duration;

          totalEarnings += (fullCycles * cycleReward).toInt();

          newProgress[item] = remainderSeconds / duration;
          stateChanged = true;
        }
      }
    }

    final newState = stateChanged || totalEarnings > 0
        ? _copyWith(
            doubloons: Doubloon(doubloons.value + totalEarnings),
            progress: newProgress,
          )
        : this;

    return newState;
  }

  int getMaxAffordable(Item item) {
    final currentCount = items[item] ?? 0;

    return item.getMaxAffordable(currentCount, doubloons.value);
  }

  int get clickPower {
    int power = 1; // Base power
    for (final item in items.keys) {
      final count = items[item] ?? 0;
      if (!item.isGenerator) {
        power += item.reward.value * count;
      }
    }
    return power;
  }

  int get passiveIncomePerSecond {
    int income = 0;
    for (final item in items.keys) {
      final count = items[item] ?? 0;
      if (item.isGenerator) {
        income += item.reward.value * count;
      }
    }
    return income;
  }

  GameState clickChest() {
    return _copyWith(doubloons: Doubloon(doubloons.value + clickPower));
  }
}
