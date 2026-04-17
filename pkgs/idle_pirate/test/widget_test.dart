
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_pirate/main.dart';
import 'package:idle_pirate/state/game_controller.dart';

void main() {
  testWidgets('Clicking chest increases doubloons', (
    WidgetTester tester,
  ) async {
    // 1. Setup the state and controller
    final controller = GameController();

    // 2. Pump the widget
    await tester.pumpWidget(MyApp(controller: controller));

    // 3. Verify that our counter starts at 0.
    expect(find.text('Doubloons: 0'), findsOneWidget);

    // 4. Tap the 'Click Chest' button and trigger a frame.
    await tester.tap(find.text('Click Chest'));
    await tester.pump();

    // 5. Verify that our counter has incremented.
    expect(find.text('Doubloons: 1'), findsOneWidget);
  });

  testWidgets('Playing through game simulation', (WidgetTester tester) async {
    final controller = GameController();
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
  });
}
