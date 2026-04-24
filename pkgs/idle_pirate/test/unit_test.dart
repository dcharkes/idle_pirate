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
    final controller = GameController(box: box, startTimer: false, enableAudio: false);

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

    final controller = GameController(box: box, startTimer: false, enableAudio: false);
    final upgrade = Upgrade(
      id: 'test_upgrade',
      name: 'Test',
      baseCost: 10,
      benefit: 1,
    );

    expect(controller.getMaxAffordable(upgrade), 1);

    // With 203 doubloons, max afford should be 10
    await box.put('doubloons', 204);
    final controller2 = GameController(box: box, startTimer: false, enableAudio: false);
    expect(controller2.getMaxAffordable(upgrade), 10);

    await box.close();
  });

  test('Passive Income: calculates correctly', () async {
    final box = await Hive.openBox('test_passive');
    await box.put('doubloons', 100);
    final controller = GameController(box: box, startTimer: false, enableAudio: false);

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

    final controller = GameController(box: box, startTimer: false, enableAudio: false);

    // Should have earned 10 doubloons (1/sec * 10 sec)
    expect(controller.state.doubloons, 10);

    await box.close();
  });

  test('Production Cycle: updates progress and awards income', () async {
    final box = await Hive.openBox('test_cycle');
    await box.put('generators', {'cabin_boy': 1});
    await box.put('doubloons', 0);

    final controller = GameController(box: box, startTimer: false, enableAudio: false);

    // Initial progress should be 0
    expect(controller.generatorsProgress['cabin_boy'] ?? 0.0, 0.0);

    // Tick once (33ms) -> Cabin Boy duration is 2s, so progress should be 0.033 / 2.0 = 0.0165
    controller.tick();
    expect(controller.generatorsProgress['cabin_boy'], closeTo(0.0165, 0.001));
    expect(controller.state.doubloons, 0);

    // Tick 60 more times (total 61 ticks = 2.013 seconds)
    for (int i = 0; i < 60; i++) {
      controller.tick();
    }

    // Progress should reset to 0 and doubloons should be awarded
    expect(controller.generatorsProgress['cabin_boy'], 0.0);
    expect(
      controller.state.doubloons,
      2,
    ); // 1 cabin boy * 1 benefit * 2s duration

    await box.close();
  });

  test('Fleet Production Cycle: updates progress and awards income', () async {
    final box = await Hive.openBox('test_fleet');
    await box.put('generators', {'sloop': 1});
    await box.put('doubloons', 0);

    final controller = GameController(box: box, startTimer: false, enableAudio: false);

    // Initial progress should be 0
    expect(controller.generatorsProgress['sloop'] ?? 0.0, 0.0);

    // Tick once (33ms) -> Sloop duration is 20s, so progress should be 0.033 / 20.0 = 0.00165
    controller.tick();
    expect(controller.generatorsProgress['sloop'], closeTo(0.00165, 0.0001));
    expect(controller.state.doubloons, 0);

    // Tick enough times to complete the cycle (20s / 0.033s = 606 ticks)
    for (int i = 0; i < 606; i++) {
      controller.tick();
    }

    // Progress should reset to 0 and doubloons should be awarded
    expect(controller.generatorsProgress['sloop'], 0.0);
    expect(
      controller.state.doubloons,
      10000,
    ); // 1 sloop * 500 benefit * 20s duration

    await box.close();
  });
}
