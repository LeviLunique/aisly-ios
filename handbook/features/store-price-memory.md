# Store and Price Memory

This page summarizes the Stage 7 slice that starts remembering where items were bought and what they last cost there.

## What It Does

The app now lets users:

- store an optional store name for each item
- see recent-store suggestions while editing an item
- reuse the last local price remembered for the same item at the same store
- keep all of that store and price-memory data local and persistent across launches

## Why It Matters

This slice deepens Aisly's real product promise.

The app is no longer only organizing what to buy and what it cost in one list.
It is starting to remember:

- where the user usually buys something
- what that item last cost at that store
- how to make repeated shopping faster without cloud infrastructure

That gives later stages a cleaner base for shopping mode and stronger local budget intelligence.

## How To Verify

1. Run `jq empty Aisly/Localizable.xcstrings`.
2. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build`.
3. Launch the app and open an active list.
4. Add an item with a store name and planned price.
5. Add another item with the same name and confirm recent-store suggestions appear.
6. Select the same store and confirm a remembered price suggestion appears.
7. Tap that suggestion and confirm it prefills the planned price.
8. Relaunch the app and confirm the store name persists.
