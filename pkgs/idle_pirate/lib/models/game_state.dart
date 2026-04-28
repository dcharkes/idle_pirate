import 'item.dart';

class GameState {
  final int doubloons;
  final Map<String, int> items;
  final Map<String, double> progress;

  GameState({
    this.doubloons = 0,
    this.items = const {},
    this.progress = const {},
  });

  GameState _copyWith({
    int? doubloons,
    Map<String, int>? items,
    Map<String, double>? progress,
  }) {
    return GameState(
      doubloons: doubloons ?? this.doubloons,
      items: items ?? this.items,

      progress: progress ?? this.progress,
    );
  }

  GameState buyUpgrades(Item item, int count) {
    final currentCount = items[item.id] ?? 0;
    final cost = item.getBulkCost(currentCount, count);

    if (doubloons >= cost && count > 0) {
      final newItems = Map<String, int>.from(items);
      newItems[item.id] = currentCount + count;
      return _copyWith(
        doubloons: doubloons - cost,
        items: newItems,
      );
    }
    return this; // Return current state if cannot afford
  }

  GameState elapseTime(Duration elapsed) {
    final elapsedSeconds = elapsed.inMilliseconds.toDouble() / 1000.0;
    int totalEarnings = 0;
    final newProgress = Map<String, double>.from(progress);
    bool stateChanged = false;

    for (final itemId in items.keys) {
      final count = items[itemId] ?? 0;
      if (count > 0) {
        final item = Item.all.firstWhere((u) => u.id == itemId);
        if (item.isGenerator) {
          final duration = item.duration!.inSeconds.toDouble();
          final progress = this.progress[itemId] ?? 0.0;

          final totalElapsedWithCurrentProgress =
              elapsedSeconds + (progress * duration);
          final fullCycles = (totalElapsedWithCurrentProgress / duration)
              .floor();
          final remainderSeconds = totalElapsedWithCurrentProgress % duration;
          final cycleReward = item.reward.value * count * duration;

          totalEarnings += (fullCycles * cycleReward).toInt();

          newProgress[itemId] = remainderSeconds / duration;
          stateChanged = true;
        }
      }
    }

    final newState = stateChanged || totalEarnings > 0
        ? _copyWith(
            doubloons: doubloons + totalEarnings,
            progress: newProgress,
          )
        : this;

    return newState;
  }

  int getMaxAffordable(Item item) {
    final currentCount = items[item.id] ?? 0;

    return item.getMaxAffordable(currentCount, doubloons);
  }

  int get clickPower {
    int power = 1; // Base power
    for (final itemId in items.keys) {
      final count = items[itemId] ?? 0;
      final item = Item.all.firstWhere((u) => u.id == itemId);
      if (!item.isGenerator) {
        power += item.reward.value * count;
      }
    }
    return power;
  }

  int get passiveIncomePerSecond {
    int income = 0;
    for (final itemId in items.keys) {
      final count = items[itemId] ?? 0;
      final item = Item.all.firstWhere((u) => u.id == itemId);
      if (item.isGenerator) {
        income += item.reward.value * count;
      }
    }
    return income;
  }

  GameState clickChest() {
    return _copyWith(doubloons: doubloons + clickPower);
  }
}
