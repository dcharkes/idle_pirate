import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:idle_pirate/main.dart';
import 'package:idle_pirate/state/game_controller.dart';

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
  testWidgets('Clicking chest increases doubloons', (
    WidgetTester tester,
  ) async {
    // 1. Setup the state and controller
    final box = FakeBox();
    final controller = GameController(box: box, startTimer: false);

    // 2. Pump the widget
    await tester.pumpWidget(MyApp(controller: controller));

    // 3. Verify that our counter starts at 0.
    expect(find.text('Doubloons: 0'), findsOneWidget);

    // 4. Tap the 'Click Chest' button and trigger a frame.
    await tester.tap(find.text('Click Chest'));
    await tester.pump();

    // 5. Verify that our counter has incremented.
    expect(find.text('Doubloons: 1'), findsOneWidget);

    await box.close();
  });

  testWidgets('Playing through game simulation', (WidgetTester tester) async {
    final box = FakeBox();
    final controller = GameController(box: box, startTimer: false);
    await tester.pumpWidget(MyApp(controller: controller));

    expect(find.text('Doubloons: 0'), findsOneWidget);

    // Click 10 times
    for (int i = 0; i < 10; i++) {
      await tester.tap(find.text('Click Chest'));
    }
    await tester.pump();
    expect(find.text('Doubloons: 10'), findsOneWidget);

    // Buy Sharper Hooks
    await tester.tap(find.text('10 D'));
    await tester.pump();

    // Doubloons should be 0
    expect(find.text('Doubloons: 0'), findsOneWidget);
    expect(find.text('Click Power: 2'), findsOneWidget);

    // Click once, should get 2 doubloons
    await tester.tap(find.text('Click Chest'));
    await tester.pump();
    expect(find.text('Doubloons: 2'), findsOneWidget);

    await box.close();
  });
  testWidgets('Max purchase refined behavior', (WidgetTester tester) async {
    final box = FakeBox();
    final controller = GameController(box: box, startTimer: false);
    await tester.pumpWidget(MyApp(controller: controller));

    expect(find.text('Doubloons: 0'), findsOneWidget);

    // Select Max
    await tester.tap(find.text('Max'));
    await tester.pump();

    // With 0 doubloons, button should show price of 1 item: "10 D"
    expect(find.text('10 D'), findsOneWidget);

    // Gain 10 doubloons
    for (int i = 0; i < 10; i++) {
      await tester.tap(find.text('Click Chest'));
    }
    await tester.pump();
    expect(find.text('Doubloons: 10'), findsOneWidget);

    // Now button should show "10 D (1)"
    expect(find.text('10 D (1)'), findsOneWidget);

    // Buy it
    await tester.tap(find.text('10 D (1)'));
    await tester.pump();

    expect(find.text('Doubloons: 0'), findsOneWidget);

    await box.close();
  });

  testWidgets('Generators generate income and update UI', (
    WidgetTester tester,
  ) async {
    final box = FakeBox();
    final controller = GameController(box: box, startTimer: false);
    await tester.pumpWidget(MyApp(controller: controller));

    expect(find.text('Doubloons: 0'), findsOneWidget);
    expect(find.text('Income: 0/sec'), findsOneWidget);

    // Gain 15 doubloons to buy a Cabin Boy
    for (int i = 0; i < 15; i++) {
      await tester.tap(find.text('Click Chest'));
    }
    await tester.pump();
    expect(find.text('Doubloons: 15'), findsOneWidget);

    // Buy Cabin Boy (cost 15)
    await tester.ensureVisible(find.text('15 D'));
    await tester.tap(find.text('15 D'));
    await tester.pump();

    // Doubloons should be 0, income should be 1/sec
    expect(find.text('Doubloons: 0'), findsOneWidget);
    expect(find.text('Income: 1/sec'), findsOneWidget);

    // Advance time by 1 second
    controller.tick();
    await tester.pump();

    // Doubloons should be 1
    expect(find.text('Doubloons: 1'), findsOneWidget);

    await box.close();
  });
}
