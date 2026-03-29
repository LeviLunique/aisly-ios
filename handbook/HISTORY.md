# Delivery History

This document summarizes the roadmap progress already completed for Aisly.

## Stage Status

- Stage 0: completed
- Stage 0B: completed
- Stage 1: completed
- Stage 2: completed
- Stage 3: completed locally
- Stage 4: completed locally
- Stage 5: completed locally
- Stage 6: completed locally
- Stage 7: completed locally
- Stage 8: completed locally
- Stage 9: pending
- Stage 10: pending
- Stage 11: pending

## Completed Slices

### Stage 0

Delivered:

- public repository scaffold
- Xcode project scaffold
- app, test, and UI-test targets
- public handbook baseline

### Stage 0B

Delivered:

- GitHub Actions CI for the shared scheme
- a 5-test unit-test baseline for project and scheme integrity
- GitHub Actions CD that uploads an unsigned release archive artifact

### Stage 1

Delivered:

- `AppContainer` dependency assembly for the root feature
- `ShoppingList` domain model plus `ShoppingListRepository`
- file-backed local persistence through `ShoppingListFileStore` and `LocalShoppingListRepository`
- centralized `Application Support` path selection through `AppStoragePaths`
- a root home feature that loads local state through MVVM
- localized root-screen copy through a String Catalog, shared localization keys, and centralized `AppStrings` access for English and Brazilian Portuguese
- locale-aware previews and UI launch checks for the root screen without hardcoded translated expectations or duplicated raw keys
- 17 tests covering repository persistence, storage compliance, localization compliance, centralized text management, shared key governance, and view-model state transitions

### Stage 2

Delivered:

- multiple active and archived local shopping lists on the root screen
- localized create-list, rename-list, and archive-list flows
- sheet-based list-name editing with trimmed-name validation
- persisted local list mutations through the existing repository boundary
- a shared SwiftUI design-system foundation for colors, typography, spacing, motion, reusable state views, form controls, summary surfaces, and reusable list-screen components
- expanded regression coverage for storage compliance, localization compliance, design-system guardrails, multiple-list view-model behavior, and locale UI launch checks

### Stage 3

Delivered locally:

- active lists now open a dedicated local detail screen
- shopping lists now persist local shopping items with quantity, category, timestamps, and explicit local order
- the detail feature supports item create, edit, delete, and reorder flows through MVVM
- the file-backed persistence layer stays backward-compatible with Stage 2 JSON that does not yet contain items
- the new detail UI stays localized through the shared String Catalog and semantic text boundary
- the detail workflow reuses the shared design-system layer for state views, inputs, item rows, badges, and actions
- regression coverage now includes Stage 2 persistence compatibility plus list-detail item behavior

### Stage 4

Delivered locally:

- shopping items now persist optional planned and actual prices
- the list-detail feature now derives planned total, actual total, actual-price coverage, and budget delta locally
- the detail screen now shows a shared budget summary card above the item list
- the item editor now supports optional planned and actual price entry
- the file-backed persistence layer stays backward-compatible with Stage 3 item payloads that do not yet contain budget fields
- regression coverage now includes Stage 3 persistence compatibility plus budget totals and price-draft validation

### Stage 5

Delivered locally:

- add-item flow now derives quick-entry suggestions from local item history across lists
- repeated items are grouped by normalized name and ranked by draft match, usage frequency, and recency
- tapping a suggestion pre-fills the create-item draft with name, quantity, category, and planned price
- the quick-entry UI stays inside the existing list-detail editor instead of introducing a new screen or persistence layer
- the new section title stays localized through the shared String Catalog and semantic text boundary
- regression coverage now includes history aggregation, live filtering, prefilling behavior, and detail-screen source-audit compliance

### Stage 6

Delivered locally:

- active lists can now be saved as reusable local templates
- templates persist recurrence metadata for weekly, biweekly, and monthly reuse
- the home screen now renders templates separately from active and archived lists
- tapping a template generates a fresh active list through the existing repository boundary
- generated lists preserve reusable item data while clearing actual prices
- the file-backed persistence layer stays backward-compatible with Stage 5 JSON that does not yet contain template metadata
- regression coverage now includes persistence compatibility, template snapshot separation, template draft prefilling, and generated-list reset behavior

### Stage 7

Delivered locally:

- shopping items now persist an optional store name
- the item editor now suggests recent stores from existing non-template local history
- the detail workflow now shows a remembered last price for the same item at the same store
- remembered prices can prefill planned price with one tap inside the existing editor
- the file-backed persistence layer stays backward-compatible with older JSON that does not yet contain store names
- regression coverage now includes store suggestion ranking, store-specific price memory, editor prefills, and persistence compatibility

### Stage 8

Delivered locally:

- added a dedicated shopping-mode screen reachable from list detail
- added persistent local completion state for shopping items
- added fast check-off interactions during the shopping session
- added actual-price editing inside the shopping flow
- surfaced shopping-session progress and running totals with the shared design-system layer
- kept the file-backed persistence layer backward-compatible with older JSON that does not yet contain completion state
- regression coverage now includes session loading, completion persistence, actual-price editing, and backward-compatible item decoding

### Supporting Remote Branch Work

The remote repository also contains additional implemented work that is not yet part of the numbered product-stage history on `main`.

#### SwiftUI Design System Foundation

Delivered on remote branch `feat/swiftui-design-system`:

- expanded the shared token layer with semantic colors, radii, and a broader component-ready motion posture
- added reusable SwiftUI components for badges, inputs, toggles, progress, page headers, list summary cards, budget summary cards, and item rows
- added shared Aisly logo and mark assets to the design system
- aligned the root local-lists UI with the broader shared design-system layer

## Planned Next Work

The next correct work is:

- Apple-first convenience

Not:

- backend
- subscriptions
- paid support tooling
