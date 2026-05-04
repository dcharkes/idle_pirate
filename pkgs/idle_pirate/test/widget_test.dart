import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:idle_pirate/main.dart';
import 'package:idle_pirate/state/game_controller.dart';
import 'package:pirate_speak/pirate_speak.dart';

class FakeBox implements Box {
  final Map<dynamic, dynamic> _data = {};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _data[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<void> close() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    setTranslationsForTesting({
      'doubloons': 'Doubloons',
      'click_power': 'Click Power',
      'per_second': 'per second',
      'click_chest': 'Open Chest',
      'gain_doubloons': 'Gain {count} doubloons',
      'max': 'Max',
      'equipment': 'Equipment',
      'crew_members': 'Crew Members',
      'fleet': 'Fleet',
      'sharper_hooks': 'Sharper Hooks',
      'better_shovels': 'Better Shovels',
      'heavy_boots': 'Heavy Boots',
      'cabin_boy': 'Cabin Boy',
      'gunner': 'Gunner',
      'quartermaster': 'Quartermaster',
      'sloop': 'Sloop',
      'brigantine': 'Brigantine',
      'frigate': 'Frigate',
    });
  });

  testWidgets('Clicking chest increases doubloons', (
    WidgetTester tester,
  ) async {
    // 1. Setup the state and controller
    final box = FakeBox();
    final controller = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );

    // 2. Pump the widget
    await tester.pumpWidget(MyApp(controller: controller));

    // 3. Verify that our counter starts at 0.
    expect(find.text('Doubloons: 0'), findsOneWidget);

    // 4. Tap the 'Open Chest' button and trigger a frame.
    await tester.tap(find.text('Open Chest'));
    await tester.pump();

    // 5. Verify that our counter has incremented.
    expect(find.text('Doubloons: 1'), findsOneWidget);

    await box.close();
  });

  testWidgets('Playing through game simulation', (WidgetTester tester) async {
    final box = FakeBox();
    final controller = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );
    await tester.pumpWidget(MyApp(controller: controller));

    expect(find.text('Doubloons: 0'), findsOneWidget);

    // Click 10 times
    for (int i = 0; i < 10; i++) {
      await tester.tap(find.text('Open Chest'));
    }
    await tester.pump();
    expect(find.text('Doubloons: 10'), findsOneWidget);

    // Buy Sharper Hooks (cost 5)
    await tester.tap(find.text('5'));
    await tester.pump();

    // Doubloons should be 5
    expect(find.text('Doubloons: 5'), findsOneWidget);
    expect(find.text('Gain 2 doubloons'), findsOneWidget);

    // Click once, should get 2 doubloons
    await tester.tap(find.text('Open Chest'));
    await tester.pump();
    expect(find.text('Doubloons: 7'), findsOneWidget);

    await box.close();
  });
  testWidgets('Max purchase refined behavior', (WidgetTester tester) async {
    final box = FakeBox();
    final controller = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );
    await tester.pumpWidget(MyApp(controller: controller));

    expect(find.text('Doubloons: 0'), findsOneWidget);

    // Select Max
    await tester.tap(find.text('Max'));
    await tester.pump();

    // With 0 doubloons, button should show price of 1 item: "5"
    expect(find.text('5'), findsOneWidget);

    // Gain 10 doubloons
    for (int i = 0; i < 10; i++) {
      await tester.tap(find.text('Open Chest'));
    }
    await tester.pump();
    expect(find.text('Doubloons: 10'), findsOneWidget);

    // Now button should show "5" and a suffix " (1)"
    expect(find.text('5'), findsOneWidget);
    expect(find.text(' (1)'), findsOneWidget);

    // Buy it
    await tester.tap(find.text('5'));
    await tester.pump();

    expect(find.text('Doubloons: 5'), findsOneWidget);

    await box.close();
  });

  testWidgets('Generators generate income and update UI', (
    WidgetTester tester,
  ) async {
    final box = FakeBox();
    await box.put('state', {
      'doubloons': 1000,
      'items': {'heavy_boots': 1},
      'progress': <String, double>{},
    });
    final controller = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );

    await tester.pumpWidget(MyApp(controller: controller));

    expect(find.text('Doubloons: 1.0K'), findsOneWidget);

    // Buy Cabin Boy (cost 500)
    await tester.ensureVisible(find.text('500'));
    await tester.tap(find.text('500'));
    await tester.pump();

    // Doubloons should be 500
    expect(find.text('Doubloons: 500'), findsOneWidget);

    // Advance time by 1 tick (33ms) -> Cabin Boy duration is 2s
    controller.tick();
    await tester.pump();

    // Doubloons should still be 500, but progress should be 0.0165
    expect(find.text('Doubloons: 500'), findsOneWidget);

    final cabinBoyTile = find.ancestor(
      of: find.textContaining('Cabin Boy'),
      matching: find.byType(Card),
    );
    final progressFinder = find.descendant(
      of: cabinBoyTile,
      matching: find.byType(LinearProgressIndicator),
    );
    expect(progressFinder, findsOneWidget);
    final progressWidget = tester.widget<LinearProgressIndicator>(
      progressFinder,
    );
    expect(progressWidget.value, closeTo(0.0165, 0.001));

    // Tick 60 more times (total 61 ticks = 2.013 seconds)
    for (int i = 0; i < 60; i++) {
      controller.tick();
    }
    await tester.pump();

    // Doubloons should be 580 (500 + 80)
    expect(find.text('Doubloons: 580'), findsOneWidget);

    await box.close();
  });

  testWidgets('Fleet generates income and update UI', (
    WidgetTester tester,
  ) async {
    final box = FakeBox();
    await box.put('state', {
      'doubloons': 50000,
      'items': {'cabin_boy': 1, 'gunner': 1, 'quartermaster': 1},
      'progress': <String, double>{},
    });
    final controller = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );
    await tester.pumpWidget(MyApp(controller: controller));

    expect(find.text('Doubloons: 50.0K'), findsOneWidget);

    // Buy Sloop (cost 40000)
    await tester.ensureVisible(find.text('40.0K'));
    await tester.tap(find.text('40.0K'));
    await tester.pump();

    // Doubloons should be 10.0K
    expect(find.text('Doubloons: 10.0K'), findsOneWidget);

    // Advance time by 1 tick (33ms) -> Sloop duration is 20s
    controller.tick();
    await tester.pump();

    // Doubloons should still be 10.0K, but progress should be 0.00165
    expect(find.text('Doubloons: 10.0K'), findsOneWidget);

    final sloopTile = find.ancestor(
      of: find.textContaining('Sloop'),
      matching: find.byType(Card),
    );
    final progressFinder = find.descendant(
      of: sloopTile,
      matching: find.byType(LinearProgressIndicator),
    );
    expect(progressFinder, findsOneWidget);
    final progressWidget = tester.widget<LinearProgressIndicator>(
      progressFinder,
    );
    expect(progressWidget.value, closeTo(0.00165, 0.0001));

    await box.close();
  });

  testWidgets('Switching language updates UI', (WidgetTester tester) async {
    final box = FakeBox();
    final controller = GameController(
      box: box,
      startTimer: false,
      enableAudio: false,
    );

    setTranslationsForTesting({'doubloons': 'Doubloons'});

    await tester.pumpWidget(MyApp(controller: controller));

    expect(find.text('Doubloons: 0'), findsOneWidget);

    // Mock new translations for Spanish
    setTranslationsForTesting({'doubloons': 'Doblones'});

    // Re-pump widget to force rebuild with new translations
    await tester.pumpWidget(MyApp(controller: controller));

    expect(find.text('Doblones: 0'), findsOneWidget);

    await box.close();
  });
}
