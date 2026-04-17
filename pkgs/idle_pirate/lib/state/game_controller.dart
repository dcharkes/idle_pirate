import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/game_state.dart';
import '../models/upgrade.dart';

class GameController extends ChangeNotifier {
  final Box _box;
  GameState _state = GameState();
  Timer? _timer;
  final Map<String, double> _generatorsProgress = {};
  final Map<String, double> _generatorDurations = {
    'cabin_boy': 2.0,
    'gunner': 5.0,
    'quartermaster': 10.0,
    'sloop': 20.0,
    'brigantine': 60.0,
    'frigate': 120.0,
  };

  Map<String, double> get generatorsProgress => _generatorsProgress;
  Map<String, double> get generatorDurations => _generatorDurations;

  GameController({required this._box, bool startTimer = true}) {
    _loadState();
    if (startTimer) {
      _startTimer();
    }
  }

  GameState get state => _state;

  void _loadState() {
    final doubloons = _box.get('doubloons', defaultValue: 0) as int;
    final upgrades = Map<String, int>.from(
      _box.get('upgrades', defaultValue: {}) as Map,
    );
    final generators = Map<String, int>.from(
      _box.get('generators', defaultValue: {}) as Map,
    );
    _state = GameState(
      doubloons: doubloons,
      upgrades: upgrades,
      generators: generators,
    );

    _calculateOfflineEarnings();
  }

  void _saveState() {
    _box.put('doubloons', _state.doubloons);
    _box.put('upgrades', _state.upgrades);
    _box.put('generators', _state.generators);
    _box.put('last_saved', DateTime.now().millisecondsSinceEpoch);
  }

  int get clickPower {
    int power = 1; // Base power
    for (final upgradeId in _state.upgrades.keys) {
      final count = _state.upgrades[upgradeId] ?? 0;
      final upgrade = initialUpgrades.firstWhere((u) => u.id == upgradeId);
      power += upgrade.benefit * count;
    }
    return power;
  }

  int get passiveIncomePerSecond {
    int income = 0;
    for (final generatorId in _state.generators.keys) {
      final count = _state.generators[generatorId] ?? 0;
      final allGens = [...initialGenerators, ...initialFleet];
      final generator = allGens.firstWhere((g) => g.id == generatorId);
      income += generator.benefit * count;
    }
    return income;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      tick();
    });
  }

  void tick() {
    bool stateChanged = false;

    for (final generatorId in _state.generators.keys) {
      final count = _state.generators[generatorId] ?? 0;
      if (count > 0) {
        final duration = _generatorDurations[generatorId] ?? 5.0;
        final currentProgress = _generatorsProgress[generatorId] ?? 0.0;
        final newProgress = currentProgress + (0.033 / duration);

        if (newProgress >= 1.0) {
          final allGens = [...initialGenerators, ...initialFleet];
          final generator = allGens.firstWhere((g) => g.id == generatorId);
          final cycleReward = generator.benefit * count * duration;
          _state = _state.copyWith(
            doubloons: _state.doubloons + cycleReward.toInt(),
          );
          _generatorsProgress[generatorId] = 0.0;
          stateChanged = true;
        } else {
          _generatorsProgress[generatorId] = newProgress;
        }
      }
    }

    notifyListeners();

    if (stateChanged) {
      _saveState();
    }
  }

  void _calculateOfflineEarnings() {
    final lastSaved = _box.get('last_saved') as int?;
    if (lastSaved != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedSeconds = (now - lastSaved) / 1000.0;
      if (elapsedSeconds > 0) {
        int totalOfflineEarnings = 0;
        bool stateChanged = false;

        for (final generatorId in _state.generators.keys) {
          final count = _state.generators[generatorId] ?? 0;
          if (count > 0) {
            final duration = _generatorDurations[generatorId] ?? 5.0;
            final currentProgress = _generatorsProgress[generatorId] ?? 0.0;

            final totalElapsedWithCurrentProgress =
                elapsedSeconds + (currentProgress * duration);
            final fullCycles = (totalElapsedWithCurrentProgress / duration)
                .floor();
            final remainderSeconds = totalElapsedWithCurrentProgress % duration;

            final allGens = [...initialGenerators, ...initialFleet];
            final generator = allGens.firstWhere((g) => g.id == generatorId);
            final cycleReward = generator.benefit * count * duration;

            totalOfflineEarnings += (fullCycles * cycleReward).toInt();

            _generatorsProgress[generatorId] = remainderSeconds / duration;
            stateChanged = true;
          }
        }

        if (totalOfflineEarnings > 0) {
          _state = _state.copyWith(
            doubloons: _state.doubloons + totalOfflineEarnings,
          );
        }

        if (stateChanged || totalOfflineEarnings > 0) {
          _saveState();
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void clickChest() {
    _state = _state.copyWith(doubloons: _state.doubloons + clickPower);
    _saveState();
    notifyListeners();
  }

  int getBulkCost(Upgrade upgrade, int count) {
    if (count <= 0) return 0;
    final allGens = [...initialGenerators, ...initialFleet];
    final isGenerator = allGens.any((g) => g.id == upgrade.id);
    final currentCount = isGenerator
        ? (_state.generators[upgrade.id] ?? 0)
        : (_state.upgrades[upgrade.id] ?? 0);
    final r = 1.15;
    final cost =
        upgrade.baseCost *
        (math.pow(r, currentCount) * (math.pow(r, count) - 1)) /
        (r - 1);
    return cost.toInt();
  }

  void buyUpgrades(Upgrade upgrade, int count) {
    final cost = getBulkCost(upgrade, count);
    if (_state.doubloons >= cost && count > 0) {
      final allGens = [...initialGenerators, ...initialFleet];
      final isGenerator = allGens.any((g) => g.id == upgrade.id);
      if (isGenerator) {
        final currentCount = _state.generators[upgrade.id] ?? 0;
        final newGenerators = Map<String, int>.from(_state.generators);
        newGenerators[upgrade.id] = currentCount + count;
        _state = _state.copyWith(
          doubloons: _state.doubloons - cost,
          generators: newGenerators,
        );
      } else {
        final currentCount = _state.upgrades[upgrade.id] ?? 0;
        final newUpgrades = Map<String, int>.from(_state.upgrades);
        newUpgrades[upgrade.id] = currentCount + count;
        _state = _state.copyWith(
          doubloons: _state.doubloons - cost,
          upgrades: newUpgrades,
        );
      }
      _saveState();
      notifyListeners();
    }
  }

  int getMaxAffordable(Upgrade upgrade) {
    final allGens = [...initialGenerators, ...initialFleet];
    final isGenerator = allGens.any((g) => g.id == upgrade.id);
    final currentCount = isGenerator
        ? (_state.generators[upgrade.id] ?? 0)
        : (_state.upgrades[upgrade.id] ?? 0);
    final c = _state.doubloons;
    final b = upgrade.baseCost;
    final r = 1.15;
    final n = currentCount;

    final value = (c * (r - 1)) / (b * math.pow(r, n)) + 1;
    if (value <= 0) return 0;
    final k = (math.log(value) / math.log(r)).floor();
    return math.max(0, k);
  }

  void buyUpgrade(Upgrade upgrade) {
    buyUpgrades(upgrade, 1);
  }
}
