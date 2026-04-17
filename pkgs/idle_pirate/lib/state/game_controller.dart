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
      final generator = initialGenerators.firstWhere(
        (g) => g.id == generatorId,
      );
      income += generator.benefit * count;
    }
    return income;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      tick();
    });
  }

  void tick() {
    final income = passiveIncomePerSecond;
    if (income > 0) {
      _state = _state.copyWith(doubloons: _state.doubloons + income);
      _saveState();
      notifyListeners();
    }
  }

  void _calculateOfflineEarnings() {
    final lastSaved = _box.get('last_saved') as int?;
    if (lastSaved != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedSeconds = (now - lastSaved) ~/ 1000;
      if (elapsedSeconds > 0) {
        final income = passiveIncomePerSecond;
        final offlineEarnings = income * elapsedSeconds;
        if (offlineEarnings > 0) {
          _state = _state.copyWith(
            doubloons: _state.doubloons + offlineEarnings,
          );
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
    final isGenerator = initialGenerators.any((g) => g.id == upgrade.id);
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
      final isGenerator = initialGenerators.any((g) => g.id == upgrade.id);
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
    final isGenerator = initialGenerators.any((g) => g.id == upgrade.id);
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
