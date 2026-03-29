# Technical Overview

This document explains how Aisly should be structured and why.

## Product Context

Aisly is an offline-first shopping app.

Its first strong product promise is not "make a list".
It is:

- make recurring shopping faster
- help users see expected versus actual spend

## Architectural Style

The app uses a pragmatic feature-first MVVM architecture.

That means:

- views render state
- view models own presentation logic
- services hold reusable business rules
- repositories hide persistence and future remote boundaries
- dependencies are assembled explicitly
- user-facing copy comes from `Localizable.xcstrings`, not Swift source literals

## Core Product Implication

The app is local-first now and backend-ready later.

That means:

- the first implementation stores data locally on device
- repository boundaries must exist from the start
- a future backend should be additive, not a rewrite

## Current Foundation

The current app base now includes:

- an `AppContainer` that assembles live dependencies
- a `ShoppingListRepository` boundary for shopping-list persistence
- a file-backed local persistence adapter for offline storage
- a centralized `Application Support` path for persistent shopping-list data
- a root `HomeViewModel` that now loads and mutates multiple local lists
- localized create, rename, and archive flows for the root local-list screen
- English and Brazilian Portuguese resources for the shipped root-screen copy

This is intentionally narrow.
It provides the minimum useful local-list product before item, category, and budget slices expand the domain further, without introducing backend or sync machinery early.

## Pattern Posture

Aisly does not adopt patterns by habit.

The preferred pattern set is:

- repositories for persistence boundaries
- adapters for Apple or infrastructure APIs
- factory functions in the app container or feature factories
- strategies when domain rules genuinely vary
- scoped observation for state propagation

The app uses these only when the slice proves the need:

- facades
- decorators
- builders
- delegates

The app avoids custom singletons and keeps app-lifetime state inside explicit dependency assembly.

## Localization Posture

Aisly localizes user-facing copy by default.

That means:

- String Catalog resources, not legacy `.strings`, are the default
- English and Brazilian Portuguese ship together
- raw localization keys stay centralized in one shared semantic key registry
- app-facing localized resources stay centralized in semantic helpers such as `AppStrings`
- locale-aware formatting is mandatory for visible values
- view models expose semantic state instead of raw UI copy
- previews and UI tests should not depend on hardcoded translated display strings

## Storage Posture

Aisly chooses storage by data classification.

That means:

- lightweight non-sensitive preferences belong in `UserDefaults` or `@AppStorage` only when a slice actually needs them
- sensitive data belongs in Keychain only
- persistent app-managed files belong under `Application Support`
- future structured relational persistence should prefer `SwiftData` when simple file-backed JSON stops being sufficient

## Core Technical Priorities

The architecture should make these easy to evolve:

- totals and deltas
- shopping-mode interaction
- recurrence and templates
- price memory by store

## What the Architecture Should Avoid

- iCloud-only lock-in as the long-term collaboration story
- payment infrastructure before premium value exists
- feature sprawl before the local product is strong
- view models coupled directly to persistence frameworks everywhere

## Reference Decisions

For the reasoning behind this overview, see:

- [app-architecture.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/app-architecture.md)
- [dependency-injection.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/dependency-injection.md)
- [design-pattern-adoption.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/design-pattern-adoption.md)
- [localization-standards.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/localization-standards.md)
- [quality-and-testing.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/quality-and-testing.md)
- [product-positioning.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/product-positioning.md)
- [storage-standards.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/storage-standards.md)
