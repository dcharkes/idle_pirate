# Idle Pirate - Testing

This document describes the testing approach and tests implemented for the Idle Pirate game.

## Overview

Testing verified that mathematical formulas scale correctly, passive income accumulates as expected, and user interactions trigger the correct state changes.

We use a combination of **Unit Tests** and **Widget Tests**.

## Unit Tests

Unit tests focus on testing the core business logic without any UI.

*   **Models**: Verified that `GameState` and `Item` models initialize correctly and serialize/deserialize properly for Hive.
*   **Formulas**: Tested the scaling formula to ensure costs scale as expected. Tested the bulk purchase formula and "Max" affordable calculation.
*   **GameController**: Verified that manual clicks increase doubloons and that passive income is calculated correctly.

## Widget Tests

Widget tests verify that the UI behaves correctly when the user interacts with it.

*   **Main Clicker**: Verified that tapping the "Open Chest" button increases doubloons and updates the display.
*   **Purchasing**: Verified that tapping buy buttons reduces doubloons and updates the display.
*   **Reactivity**: Verified that the UI updates automatically when generators complete a cycle.
*   **Language Switching**: Verified that switching the language updates the text elements on the screen.

To run all tests:
```bash
flutter test
```

## Verifying Asset Treeshaking

The link hook that performs asset treeshaking and checks for missing assets ONLY runs during the build process. Running `flutter test` does NOT trigger the link hook!

To verify that asset treeshaking works and that all referenced assets are present, run a build:

```bash
flutter build ios
```
