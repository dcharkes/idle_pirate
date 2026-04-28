import 'upgrade.dart';

class GameState {
  final int doubloons;
  final Map<String, int> upgrades;
  final Map<String, int> generators;
  final Map<String, double> generatorsProgress;

  GameState({
    this.doubloons = 0,
    this.upgrades = const {},
    this.generators = const {},
    this.generatorsProgress = const {},
  });

  GameState _copyWith({
    int? doubloons,
    Map<String, int>? upgrades,
    Map<String, int>? generators,
    Map<String, double>? generatorsProgress,
  }) {
    return GameState(
      doubloons: doubloons ?? this.doubloons,
      upgrades: upgrades ?? this.upgrades,
      generators: generators ?? this.generators,
      generatorsProgress: generatorsProgress ?? this.generatorsProgress,
    );
  }

  GameState buyUpgrades(Upgrade upgrade, int count) {
    final allGens = Upgrade.allGenerators;
    final isGenerator = allGens.any((g) => g.id == upgrade.id);
    final currentCount = isGenerator
        ? (generators[upgrade.id] ?? 0)
        : (upgrades[upgrade.id] ?? 0);
    final cost = upgrade.getBulkCost(currentCount, count);

    if (doubloons >= cost && count > 0) {
      if (isGenerator) {
        final newGenerators = Map<String, int>.from(generators);
        newGenerators[upgrade.id] = currentCount + count;
        return _copyWith(
          doubloons: doubloons - cost,
          generators: newGenerators,
        );
      } else {
        final newUpgrades = Map<String, int>.from(upgrades);
        newUpgrades[upgrade.id] = currentCount + count;
        return _copyWith(
          doubloons: doubloons - cost,
          upgrades: newUpgrades,
        );
      }
    }
    return this; // Return current state if cannot afford
  }

  GameState elapseTime(Duration elapsed) {
    final elapsedSeconds = elapsed.inMilliseconds.toDouble() / 1000.0;
    int totalEarnings = 0;
    final newProgress = Map<String, double>.from(generatorsProgress);
    bool stateChanged = false;

    for (final generatorId in generators.keys) {
      final count = generators[generatorId] ?? 0;
      if (count > 0) {
        final allGens = Upgrade.allGenerators;
        final generator = allGens.firstWhere((g) => g.id == generatorId);
        final duration = generator.duration!.inSeconds.toDouble();
        final progress = generatorsProgress[generatorId] ?? 0.0;

        final totalElapsedWithCurrentProgress =
            elapsedSeconds + (progress * duration);
        final fullCycles = (totalElapsedWithCurrentProgress / duration).floor();
        final remainderSeconds = totalElapsedWithCurrentProgress % duration;
        final cycleReward = generator.reward.value * count * duration;

        totalEarnings += (fullCycles * cycleReward).toInt();

        newProgress[generatorId] = remainderSeconds / duration;
        stateChanged = true;
      }
    }

    final newState = stateChanged || totalEarnings > 0
        ? _copyWith(
            doubloons: doubloons + totalEarnings,
            generatorsProgress: newProgress,
          )
        : this;

    return newState;
  }

  int getMaxAffordable(Upgrade upgrade) {
    final allGens = Upgrade.allGenerators;
    final isGenerator = allGens.any((g) => g.id == upgrade.id);
    final currentCount = isGenerator
        ? (generators[upgrade.id] ?? 0)
        : (upgrades[upgrade.id] ?? 0);

    return upgrade.getMaxAffordable(currentCount, doubloons);
  }

  int get clickPower {
    int power = 1; // Base power
    for (final upgradeId in upgrades.keys) {
      final count = upgrades[upgradeId] ?? 0;
      final upgrade = Upgrade.equipment.firstWhere((u) => u.id == upgradeId);
      power += upgrade.reward.value * count;
    }
    return power;
  }

  int get passiveIncomePerSecond {
    int income = 0;
    for (final generatorId in generators.keys) {
      final count = generators[generatorId] ?? 0;
      final allGens = Upgrade.allGenerators;
      final generator = allGens.firstWhere((g) => g.id == generatorId);
      income += generator.reward.value * count;
    }
    return income;
  }

  GameState clickChest() {
    return _copyWith(doubloons: doubloons + clickPower);
  }
}
