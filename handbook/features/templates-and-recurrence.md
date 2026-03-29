# Templates and Recurrence

This page summarizes the Stage 6 slice that makes repeated shopping lists reusable.

## What It Does

The app now lets users:

- save an active shopping list as a reusable template
- choose a recurrence cadence for that template
- see templates in their own home-screen section
- generate a fresh active list from a saved template

## Why It Matters

This slice moves Aisly further toward recurring household-shopping utility instead of one-off list editing.

It reduces repeated setup work, keeps routines easy to restart, and creates the right base for later store memory and shopping-mode improvements.

## How To Verify

1. Run `xcodegen generate`.
2. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build`.
3. Save one active list as a template from the home screen.
4. Confirm the templates section appears.
5. Generate a list from that template.
6. Open the new list and confirm reusable item data copied across while actual prices were reset.
