import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:idle_pirate/state/game_controller.dart';
import 'package:idle_pirate/models/item.dart';
import 'package:idle_pirate/models/game_state.dart';

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

    final upgrade = Item.sharperHooks;

    // N = 0, K = 1 -> cost should be 10
    expect(upgrade.getBulkCost(0, 1), 10);

    // N = 0, K = 10 -> cost should be 10 * (1.15^10 - 1) / 0.15
    // 10 * (4.0455 - 1) / 0.15 = 10 * 3.0455 / 0.15 = 203.03 -> 203
    expect(upgrade.getBulkCost(0, 10), 203);

    await box.close();
  });

  test('Formula: getMaxAffordable calculates correctly', () async {
    final box = await Hive.openBox('test_max');
    await box.put('state', {
      'doubloons': 10,
      'items': <String, int>{},
      'progress': <String, double>{},
    });

    final controller = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );
    final upgrade = Item.sharperHooks;

    expect(controller.state.getMaxAffordable(upgrade), 1);

    // With 203 doubloons, max afford should be 10
    await box.put('state', {
      'doubloons': 204,
      'items': <String, int>{},
      'progress': <String, double>{},
    });
    final controller2 = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );
    expect(controller2.state.getMaxAffordable(upgrade), 10);

    await box.close();
  });

  test('Passive Income: calculates correctly', () async {
    final box = await Hive.openBox('test_passive');
    await box.put('state', {
      'doubloons': 100,
      'items': <String, int>{},
      'progress': <String, double>{},
    });
    final controller = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );

    // Initial income should be 0
    expect(controller.state.passiveIncomePerSecond, 0);

    // Buy a Cabin Boy (id: 'cabin_boy', reward: 1)
    controller.buyUpgrades(Item.cabinBoy, 1);

    expect(controller.state.passiveIncomePerSecond, 1);

    await box.close();
  });

  test('Offline Earnings: calculates correctly', () async {
    final box = await Hive.openBox('test_offline');

    // Set up state with 1 Cabin Boy
    await box.put('state', {
      'doubloons': 0,
      'items': {'cabin_boy': 1},
      'progress': <String, double>{},
    });

    // Set last saved to 10 seconds ago
    final now = DateTime.now().millisecondsSinceEpoch;
    await box.put('last_saved', now - 10000);

    final controller = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );

    // Should have earned 10 doubloons (1/sec * 10 sec)
    expect(controller.state.doubloons.value, 10);

    await box.close();
  });

  test('Production Cycle: updates progress and awards income', () async {
    final box = await Hive.openBox('test_cycle');
    await box.put('state', {
      'doubloons': 0,
      'items': {'cabin_boy': 1},
      'progress': <String, double>{},
    });

    final controller = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );

    // Initial progress should be 0
    expect(controller.state.progress[Item.cabinBoy] ?? 0.0, 0.0);

    // Tick once (33ms) -> Cabin Boy duration is 2s, so progress should be 0.033 / 2.0 = 0.0165
    controller.tick();
    expect(
      controller.state.progress[Item.cabinBoy],
      closeTo(0.0165, 0.001),
    );
    expect(controller.state.doubloons, 0);

    // Tick 60 more times (total 61 ticks = 2.013 seconds)
    for (int i = 0; i < 60; i++) {
      controller.tick();
    }

    // Progress should reset to 0 and doubloons should be awarded
    expect(
      controller.state.progress[Item.cabinBoy],
      closeTo(0.0, 0.02),
    );
    expect(
      controller.state.doubloons,
      2,
    ); // 1 cabin boy * 1 reward * 2s duration

    await box.close();
  });

  test('Fleet Production Cycle: updates progress and awards income', () async {
    final box = await Hive.openBox('test_fleet');
    await box.put('state', {
      'doubloons': 0,
      'items': {'sloop': 1},
      'progress': <String, double>{},
    });

    final controller = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );

    // Initial progress should be 0
    expect(controller.state.progress[Item.sloop] ?? 0.0, 0.0);

    // Tick once (33ms) -> Sloop duration is 20s, so progress should be 0.033 / 20.0 = 0.00165
    controller.tick();
    expect(
      controller.state.progress[Item.sloop],
      closeTo(0.00165, 0.0001),
    );
    expect(controller.state.doubloons, 0);

    // Tick enough times to complete the cycle (20s / 0.033s = 606 ticks)
    for (int i = 0; i < 606; i++) {
      controller.tick();
    }

    // Progress should reset to 0 and doubloons should be awarded
    expect(controller.state.progress[Item.sloop], closeTo(0.0, 0.02));
    expect(
      controller.state.doubloons,
      10000,
    ); // 1 sloop * 500 reward * 20s duration

    await box.close();
  });

  test('GameState: toJson and fromJson work', () {
    final state = GameState(
      doubloons: Doubloon(100),
      items: {Item.cabinBoy: 1},
      progress: {Item.cabinBoy: 0.5},
    );

    final json = state.toJson();
    expect(json['doubloons'], 100);
    expect(json['items']['cabin_boy'], 1);
    expect(json['progress']['cabin_boy'], 0.5);

    final loadedState = GameState.fromJson(json);
    expect(loadedState.doubloons.value, 100);
    expect(loadedState.items[Item.cabinBoy], 1);
    expect(loadedState.progress[Item.cabinBoy], 0.5);
  });
}
