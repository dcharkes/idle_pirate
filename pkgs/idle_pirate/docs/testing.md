# Idle Pirate - Testing Strategy

This document outlines the strategy for testing the Idle Pirate game.

## Overview

Testing an idle game involves verifying that the mathematical formulas scale correctly, passive income accumulates as expected, and user interactions trigger the correct state changes.

We will use a combination of **Unit Tests** and **Widget Tests**.

## Unit Tests

Unit tests will focus on testing the core business logic without any UI.

*   **Models**: Verify that `GameState`, `CrewMember`, and `Upgrade` models initialize correctly and serialize/deserialize properly (important for Hive).
*   **Formulas**: Test the `P = B * 1.15^N` formula to ensure costs scale as expected. Test the bulk purchase formula.
*   **GameController**: Verify that manual clicks increase doubloons and that passive income is calculated correctly on ticks.

## Widget Tests

Widget tests will verify that the UI behaves correctly when the user interacts with it. This directly addresses your question:

> **Yes, we can use widget tests to verify that pressing a button increases doubloons.**

*   **Main Clicker**: We can create a test that pumps the `GameScreen`, finds the "Click" target (e.g., the Chest), simulates a tap, and verifies that the displayed Doubloon count increases.
*   **Purchasing**: We can test that tapping "Buy Crew" reduces Doubloons and updates the display.
*   **Reactivity**: Verify that the UI updates automatically when the state changes (e.g., when a tick happens).

## Example Widget Test Sketch

Here is a conceptual example of how a widget test for the clicker would look:

```dart
testWidgets('Clicking chest increases doubloons', (WidgetTester tester) async {
  // 1. Setup the state and controller
  final controller = GameController();
  
  // 2. Pump the widget
  await tester.pumpWidget(
    MaterialApp(
      home: GameScreen(controller: controller),
    ),
  );

  // 3. Verify initial state
  expect(find.text('Doubloons: 0'), findsOneWidget);

  // 4. Simulate interaction
  await tester.tap(find.byKey(ValueKey('chest_target')));
  await tester.pump(); // Re-render

  // 5. Verify result
  expect(find.text('Doubloons: 1'), findsOneWidget);
});
```
