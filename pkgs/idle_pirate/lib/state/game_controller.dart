import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/upgrade.dart';

class GameController extends ChangeNotifier {
  GameState _state = GameState();

  GameState get state => _state;

  int get clickPower {
    int power = 1; // Base power
    for (final upgradeId in _state.upgrades.keys) {
      final count = _state.upgrades[upgradeId] ?? 0;
      final upgrade = initialUpgrades.firstWhere((u) => u.id == upgradeId);
      power += upgrade.benefit * count;
    }
    return power;
  }

  void clickChest() {
    _state = _state.copyWith(doubloons: _state.doubloons + clickPower);
    notifyListeners();
  }

  void buyUpgrade(Upgrade upgrade) {
    final currentCount = _state.upgrades[upgrade.id] ?? 0;
    final cost = (upgrade.baseCost * math.pow(1.15, currentCount)).toInt();

    if (_state.doubloons >= cost) {
      final newUpgrades = Map<String, int>.from(_state.upgrades);
      newUpgrades[upgrade.id] = currentCount + 1;
      _state = _state.copyWith(
        doubloons: _state.doubloons - cost,
        upgrades: newUpgrades,
      );
      notifyListeners();
    }
  }
}
