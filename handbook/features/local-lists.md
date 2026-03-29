# Multiple Local Lists

This page summarizes the first real local-product slice on top of the offline foundation.

The multiple-local-lists workflow is now present on the remote `main` branch.
The remote repository also contains a separate `feat/swiftui-design-system` branch that deepens the shared visual layer around this slice.

## What It Does

The app now lets users:

- create more than one shopping list
- rename an active list
- archive a list without deleting it
- see active and archived lists separately
- keep those lists persisted locally across launches
- render the root-screen states through the shared Aisly SwiftUI design-system foundation already merged into the lists flow

The related remote design-system branch extends that base further with:

- broader reusable controls and summary surfaces
- shared Aisly logo assets for branded app surfaces
- additional shared motion and component coverage for future item and budget screens

## Why It Matters

This is the first slice that makes Aisly useful for real household shopping routines instead of just proving the architecture.

It also creates the right base for the next product layers:

- items and categories can now attach to real list entities
- budget logic can later attach totals to multiple distinct local lists
- recurring shopping flows can later build on archived and active list history

The slice establishes the first real product utility layer and the first native visual foundation for later item, budget, and shopping-mode work. A separate remote design-system branch extends that visual foundation further without changing the product flow or roadmap order.

## How To Verify

1. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyTests test`.
2. Run `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyUITests test`.
3. Launch the app and create at least two local lists.
4. Rename one list and confirm the new name persists.
5. Archive one list and confirm it moves to the archived section.
6. Confirm the list sections, buttons, list rows, loading state, and state layouts use the shared Aisly visual language in both light and dark mode.
7. Relaunch the app and confirm both sections still reflect the saved local state.
