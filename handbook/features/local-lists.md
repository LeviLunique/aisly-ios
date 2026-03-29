# Multiple Local Lists

This page summarizes the first real local-product slice on top of the offline foundation.

## What It Does

The app now lets users:

- create more than one shopping list
- rename an active list
- archive a list without deleting it
- see active and archived lists separately
- keep those lists persisted locally across launches

## Why It Matters

This is the first slice that makes Aisly useful for real household shopping routines instead of just proving the architecture.

It also creates the right base for the next product layers:

- items and categories can now attach to real list entities
- budget logic can later attach totals to multiple distinct local lists
- recurring shopping flows can later build on archived and active list history

## How To Verify

1. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyTests test`.
2. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyUITests test`.
3. Launch the app and create at least two local lists.
4. Rename one list and confirm the new name persists.
5. Archive one list and confirm it moves to the archived section.
6. Relaunch the app and confirm both sections still reflect the saved local state.
