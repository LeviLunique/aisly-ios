# Budget Core

This page summarizes the Stage 4 slice that adds the first real spend signal to Aisly.

## What It Does

The app now lets users:

- store a planned price for each item
- store an actual price for each item
- see planned and actual totals for one list
- see when the list is under, over, or still waiting for actual prices
- keep all of that pricing data local and persistent across launches

## Why It Matters

This is the first slice that starts delivering on Aisly’s real product promise.

The app is no longer only organizing what to buy.
It is starting to show:

- what the shopping trip was expected to cost
- what it is actually costing
- whether the user is staying on budget

That gives later stages a clean base for price memory, shopping mode, and recurring budget-aware routines.

## How To Verify

1. Run `xcodegen generate`.
2. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build`.
3. Launch the app and open an active list.
4. Add an item with a planned price and confirm the budget card updates.
5. Edit that item and add an actual price.
6. Confirm the actual total and delta state update.
7. Relaunch the app and confirm the prices and totals persist.
