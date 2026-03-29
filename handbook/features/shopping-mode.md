# Shopping Mode

This page summarizes the Stage 8 slice that makes Aisly useful during the real shopping trip.

## What It Does

The app now lets users:

- open a dedicated shopping-mode screen from list detail
- check items off while shopping
- enter actual item prices inside the shopping flow
- watch progress and running totals update during the session

## Why It Matters

This slice turns Aisly from planning utility into in-store utility.

The earlier stages already covered:

- local list management
- item details
- budget totals
- quick entry
- store-specific price memory

Shopping mode is where those pieces start working together during real execution, when the user needs fast interactions and clear totals instead of editor-heavy screens.

## How To Verify

1. Run `jq empty Aisly/Localizable.xcstrings`.
2. Run `xcodegen generate`.
3. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build`.
4. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=Aisly iPhone 16' -only-testing:AislyTests test`.
5. Launch the app and open an active list with items.
6. Enter shopping mode from the list-detail toolbar.
7. Check off one item and confirm it moves into the completed section.
8. Edit an actual price and confirm the session totals update.
