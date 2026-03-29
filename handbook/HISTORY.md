# Delivery History

This document summarizes the roadmap progress already completed for Aisly.

## Stage Status

- Stage 0: completed
- Stage 0B: completed
- Stage 1: completed
- Stage 2: completed
- Stage 3: pending
- Stage 4: pending
- Stage 5: pending
- Stage 6: pending
- Stage 7: pending
- Stage 8: pending
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
- shared Aisly logo assets inside the design system, including the compact mark used by the root empty state
- expanded regression coverage for storage compliance, localization compliance, design-system guardrails, logo component coverage, shared motion/component availability, multiple-list view-model behavior, and locale UI launch checks

## Planned Next Work

The next correct work is:

- local items and categories
- budget core

Not:

- backend
- subscriptions
- paid support tooling
