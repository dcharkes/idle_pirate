# Idle Pirate - Economy and Math

This document outlines the mathematical formulas and baseline economy for the Idle Pirate game.

## The Standard Scaling Formula

The pricing for basic passive generators relies on an exponential formula to ensure costs grow appropriately as the player progresses.

$$ P = B \times R^N $$

*   $P$: The new price.
*   $B$: The base price of the item.
*   $R$: The growth rate multiplier (Standard: **1.15**).
*   $N$: The number of that specific item the player already owns.

Setting the $R$ value to **1.15** means every purchase increases the cost of the next one by exactly 15%.

## Suggested Base Prices

### Phase 1: Manual Click Upgrades
These are tiered, one-time purchases and do not need the exponential formula.
*   **Sharper Hook (+1 per click):** 50 Doubloons
*   **Heavy Boots (+5 per click):** 500 Doubloons
*   **Golden Shovel (+25 per click):** 5,000 Doubloons

### Phase 2: Passive Generators (The Crew)
These items can be bought infinitely and use the $P = B \times 1.15^N$ formula. 

*   **Cabin Boy (1 Doubloon/sec)**
    *   Base Price ($B$): 15 Doubloons
*   **Gunner (15 Doubloons/sec)**
    *   Base Price ($B$): 500 Doubloons
*   **Quartermaster (100 Doubloons/sec)**
    *   Base Price ($B$): 8,000 Doubloons

## Bulk Purchasing (The "Buy 10" Button)

To calculate the cost of buying multiple items at once, we use the geometric series sum formula:

$$ C = B \times \frac{R^N \times (R^M - 1)}{R - 1} $$

*   $C$: The total cumulative cost.
*   $B$: The base price.
*   $R$: The growth rate (1.15).
*   $N$: The number currently owned.
*   $M$: The amount the player wants to buy.
