# Idle Pirate - Milestones

This document outlines the planned milestones for implementing the Idle Pirate game, ordered by priority.

## Milestone 1: Core Mechanics (MVP - Text & Basic UI)
The goal is to get the basic game loop working without any visual or audio polish. Just the pure mechanics.

*   **Setup**: Project structure and basic files.
*   **Models**: Implement `GameState`, `CrewMember`, and `Upgrade` models.
*   **State Management**: Create `GameController` with a basic loop that generates income passively.
*   **UI**: Simple text displays and standard buttons for actions.
    *   Target to click (button).
    *   Display total Doubloons and Doubloons/sec.
    *   Buttons to hire crew members.
*   **Constraints**: **No icons, no sounds, no complex graphics.**

## Milestone 2: Persistence and Economy
Adding persistence and implementing the requested math formulas.

*   **Persistence**: Integrate the `hive` package to save and load game progress.
*   **Economy Formula**: Apply the $P = B \times 1.15^N$ scaling rule to prices.
*   **Bulk Purchase**: Implement the sum formula for "Buy 10" and "Buy Max" options.

## Milestone 3: Graphics and Animations (The Visual Upgrade)
Transforming the text-based game into a rich, premium experience.

*   **Theming**: Curated, premium dark color palette.
*   **Visual Assets**: Add custom graphics for ships, crew, and the main click target (Chest).
*   **Animations**: Smooth transitions, coin-pop effects on click, and movement on elements to create a lively interface.
*   **UI Layout**: Premium visual design prioritizing excellent scannability and aesthetics.

## Milestone 4: Audio and Polish
Adding the final layers of sensory feedback.

*   **Sound Effects**: Cues for clicks, successful purchases, and achievements.
*   **Atmosphere**: Add a ambient background music loop fitting the pirate theme.
*   **Optimization**: Performance profile and UI responsiveness improvements.

## Milestone 5: The Prestige System (End Game)
Adding the long-term progression layer.

*   **Reset Mechanics**: The option to "Bury the Hoard" for a hard reset.
*   **Meta Currency**: Grant Infamy based on the magnitude of the reset.
*   **Meta-Upgrades**: A dedicated store for permanent multipliers unlocked with Infamy.
