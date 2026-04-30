# Idle Pirate - Economy and Math

This document outlines the mathematical formulas and baseline economy for the Idle Pirate game.

## The Standard Scaling Formula

The pricing for basic passive generators and equipment relies on an exponential formula to ensure costs grow appropriately as the player progresses.

$$ P = B \times R^N $$

*   $P$: The new price.
*   $B$: The base price of the item.
*   $R$: The growth rate multiplier (Standard: **1.15**).
*   $N$: The number of that specific item the player already owns.

Setting the $R$ value to **1.15** means every purchase increases the cost of the next one by exactly 15%.

## Base Prices and Rewards

### Equipment (Manual Click Upgrades)
These items increase the click power. They also use the exponential scaling formula!
*   **Sharper Hooks**: Base Cost 10 Doubloons, +1 per click.
*   **Better Shovels**: Base Cost 500 Doubloons, +5 per click.
*   **Heavy Boots**: Base Cost 5000 Doubloons, +25 per click.

### Crew Members (Passive Generators)
These items generate doubloons automatically over a specific duration.
*   **Cabin Boy**: Base Cost 15 Doubloons, 1 Doubloon every 2s.
*   **Gunner**: Base Cost 500 Doubloons, 15 Doubloons every 5s.
*   **Quartermaster**: Base Cost 8000 Doubloons, 100 Doubloons every 10s.

### Fleet (Large Passive Generators)
These items generate large amounts of doubloons over longer durations.
*   **Sloop**: Base Cost 50,000 Doubloons, 500 Doubloons every 20s.
*   **Brigantine**: Base Cost 250,000 Doubloons, 3000 Doubloons every 60s.
*   **Frigate**: Base Cost 1,000,000 Doubloons, 15000 Doubloons every 120s.

## Bulk Purchasing (The "Buy 10" and "Max" Buttons)

To calculate the cost of buying multiple items at once, we use the geometric series sum formula:

$$ C = B \times \frac{R^N \times (R^M - 1)}{R - 1} $$

*   $C$: The total cumulative cost.
*   $B$: The base price.
*   $R$: The growth rate (1.15).
*   $N$: The number currently owned.
*   $M$: The amount the player wants to buy.

For the "Max" button, we calculate how many items $M$ the player can afford with their current doubloons $C$:

$$ M = \lfloor \log_R \left( \frac{C \times (R - 1)}{B \times R^N} + 1 \right) \rfloor $$
