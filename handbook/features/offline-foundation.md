# Offline Foundation

This page summarizes the first real architecture slice shipped in Aisly.

The offline-foundation slice is now present on the remote `main` branch.

## What It Does

The app now starts with:

- an explicit `AppContainer`
- a `ShoppingList` domain model
- a `ShoppingListRepository` persistence boundary
- a file-backed local repository implementation
- a centralized `Application Support` path for persistent shopping-list data
- a root MVVM screen that loads local list state
- localized root-screen copy through a String Catalog, a shared semantic key registry, and centralized `AppStrings` access for English and Brazilian Portuguese

## Why It Matters

This turns Aisly from a scaffold into a local-first app base that future list, budget, and shopping-mode features can build on without rewriting the app shell.

It also sets the baseline rule that user-facing copy lives in localization resources instead of Swift source.
It now also sets the baseline rule that locale coverage is verified in both tests and previews.
It now also sets the baseline rule that previews and locale UI tests do not hardcode translated app UI text.
It now also sets the baseline rule that preview tooling labels may remain simple local strings.
It now also sets the baseline rule that preview fixture values that can render on screen come from a centralized semantic boundary.
It now also sets the baseline rule that raw localization keys are shared from one registry instead of being redefined in app or UI-test files.
It also sets the baseline rule that persistent app-managed files live under `Application Support`, not ad hoc locations.

## How To Verify

1. Run `xcodegen generate`.
2. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyTests test`.
3. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyUITests test`.
4. Launch the app and confirm the root screen loads the local empty state instead of the old placeholder text.
5. Switch the simulator between English and Portuguese (Brazil) and confirm the root copy changes automatically.
6. Confirm malformed `shopping-lists.json` data surfaces a failure path instead of silently corrupting app state.
