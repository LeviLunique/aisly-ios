# Apple-First Convenience

This page summarizes the Stage 9 slice that makes Aisly easier to reach from native Apple surfaces.

## What It Does

The app now lets users:

- add an active-list widget to the home screen
- open the app to the list root from an App Intent or Siri shortcut
- jump directly into shopping mode for a selected list from an App Intent
- deep-link into list detail or shopping mode through the custom `aisly://` route

## Why It Matters

This slice improves convenience without changing the core product scope.

The earlier stages already covered:

- local list management
- item details and categories
- budget visibility
- quick entry
- templates
- store-specific price memory
- shopping-mode execution

Apple-first convenience makes those existing local workflows faster to reach from the places iPhone users already use: the home screen and Shortcuts.

## How To Verify

1. Run `jq empty Aisly/Localizable.xcstrings`.
2. Run `xcodegen generate`.
3. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build`.
4. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=Aisly iPhone 16' -only-testing:AislyTests test`.
5. Add the Aisly widget on the simulator and confirm it renders an active local list.
6. Tap the widget and confirm the app opens into the relevant list detail or shopping-mode flow.
7. Trigger the open-lists App Intent and confirm the app opens to the home screen.
8. Trigger the open-shopping-mode App Intent and confirm the app opens directly into shopping mode for the selected list.
