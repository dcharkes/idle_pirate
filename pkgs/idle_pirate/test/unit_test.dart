import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:idle_pirate/state/game_controller.dart';
import 'package:idle_pirate/models/upgrade.dart';

void main() {
  setUpAll(() async {
    final dir = Directory('test/hive_data');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    Hive.init(dir.path);
  });

  tearDownAll(() async {
    final dir = Directory('test/hive_data');
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('Formula: getBulkCost calculates correctly', () async {
    final box = await Hive.openBox('test_cost');
    final controller = GameController(box: box, startTimer: false);

    final upgrade = Upgrade(
      id: 'test_upgrade',
      name: 'Test',
      baseCost: 10,
      benefit: 1,
    );

    // N = 0, K = 1 -> cost should be 10
    expect(controller.getBulkCost(upgrade, 1), 10);

    // N = 0, K = 10 -> cost should be 10 * (1.15^10 - 1) / 0.15
    // 10 * (4.0455 - 1) / 0.15 = 10 * 3.0455 / 0.15 = 203.03 -> 203
    expect(controller.getBulkCost(upgrade, 10), 203);

    await box.close();
  });

  test('Formula: getMaxAffordable calculates correctly', () async {
    final box = await Hive.openBox('test_max');
    await box.put('doubloons', 10);

    final controller = GameController(box: box, startTimer: false);
    final upgrade = Upgrade(
      id: 'test_upgrade',
      name: 'Test',
      baseCost: 10,
      benefit: 1,
    );

    expect(controller.getMaxAffordable(upgrade), 1);

    // With 203 doubloons, max afford should be 10
    await box.put('doubloons', 204);
    final controller2 = GameController(box: box, startTimer: false);
    expect(controller2.getMaxAffordable(upgrade), 10);

    await box.close();
  });

  test('Passive Income: calculates correctly', () async {
    final box = await Hive.openBox('test_passive');
    await box.put('doubloons', 100);
    final controller = GameController(box: box, startTimer: false);

    // Initial income should be 0
    expect(controller.passiveIncomePerSecond, 0);

    // Buy a Cabin Boy (id: 'cabin_boy', benefit: 1)
    final cabinBoy = initialGenerators.firstWhere((g) => g.id == 'cabin_boy');
    controller.buyUpgrades(cabinBoy, 1);

    expect(controller.passiveIncomePerSecond, 1);

    await box.close();
  });

  test('Offline Earnings: calculates correctly', () async {
    final box = await Hive.openBox('test_offline');

    // Set up state with 1 Cabin Boy
    await box.put('generators', {'cabin_boy': 1});
    await box.put('doubloons', 0);

    // Set last saved to 10 seconds ago
    final now = DateTime.now().millisecondsSinceEpoch;
    await box.put('last_saved', now - 10000);

    final controller = GameController(box: box, startTimer: false);

    // Should have earned 10 doubloons (1/sec * 10 sec)
    expect(controller.state.doubloons, 10);

    await box.close();
  });
}
