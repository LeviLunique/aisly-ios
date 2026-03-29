# Quick Entry and History

This page summarizes the Stage 5 slice that makes repeated item entry faster.

## What It Does

The app now lets users:

- reuse past local items while adding a new item
- see quick-entry suggestions inside the add-item sheet
- get suggestions ranked by frequency and recency
- tap one suggestion to prefill name, quantity, category, and planned price

## Why It Matters

This slice starts turning Aisly into a recurring-shopping assistant instead of a plain editor.

It improves the real repeated-use workflow by reducing typing for common items and creates the right base for later templates, recurrence, and stronger shopping routines.

## How To Verify

1. Run `xcodegen generate`.
2. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build`.
3. Add a few items to one list.
4. Open another list and start the add-item flow.
5. Confirm a quick-entry section appears in create mode.
6. Tap one suggestion and confirm the draft pre-fills.
7. Type into the item-name field and confirm the suggestions filter.
