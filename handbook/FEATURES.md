# Features and Roadmap Status

This document summarizes the current direction of Aisly.

## Current Status

The repository scaffold, GitHub Actions workflow baseline, offline architecture foundation, and multiple-local-lists slice are complete.

The current shipped UI also now sits on an Aisly-native SwiftUI design-system foundation for colors, typography, spacing, motion, reusable state views and controls, reusable list-screen components, and shared logo assets.

The next real product work is now the local items and categories slice.

## What Should Be Built First

### Offline Foundation

Completed:

- app container
- repository boundaries
- local persistence
- centralized persistent storage-path policy for app-managed files
- core shopping-list domain model
- root MVVM loading flow
- localized root-screen copy in a String Catalog for English and Brazilian Portuguese
- locale smoke coverage in UI tests
- direct persistence, storage-audit, and view-model tests

### Multiple Local Lists

Completed:

- create list
- edit list
- archive list
- manage more than one active list
- shared SwiftUI design-system tokens, motion, and reusable root-screen components for the local-lists flow

### Local Items and Categories

Planned:

- item CRUD
- quantity support
- categories
- ordering

### Budget Core

Planned:

- planned total
- actual total
- delta visibility

### Recurring Shopping Convenience

Planned:

- quick entry from history
- templates
- recurring list regeneration

### Price Memory

Planned:

- store model
- last price memory
- store-specific price records

### Shopping Mode

Planned:

- in-store optimized interaction
- check-off flow
- actual-price-first editing

### Apple-First Convenience

Planned:

- widgets
- App Intents
- Siri shortcuts

## What Should Wait

Explicitly deferred:

- backend
- shared cloud lists
- purchases
- barcode scanning
- OCR
- recipes
- advanced support tooling

## Detailed Slice History

For the stage-by-stage status, see:

- [HISTORY.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/HISTORY.md)
- [local-lists.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/features/local-lists.md)
