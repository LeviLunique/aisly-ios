# Local Items and Categories

This page summarizes the Stage 3 slice that completes the first real local shopping-list core.

## What It Does

The app now lets users:

- open an active shopping list into a local detail screen
- add items inside a list
- edit item name, quantity, and category
- delete items
- reorder items locally
- persist all of that item data across launches

## Why It Matters

This is the slice that turns Aisly from a multi-list shell into a usable local shopping workflow.

It also creates the right base for the next product layers:

- budget work can now attach planned and actual prices to real persistent items
- shopping mode can later reuse local item order and quantity
- recurrence and templates can later duplicate real item collections instead of empty list shells

## How To Verify

1. Run `xcodegen generate`.
2. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build`.
3. Launch the app and create a list if needed.
4. Open an active list and add at least two items with different categories.
5. Edit one item and delete another.
6. Reorder the remaining items in edit mode.
7. Relaunch the app and confirm the list detail still reflects the saved local items and order.
