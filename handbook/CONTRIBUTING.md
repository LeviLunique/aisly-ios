# Contributing

This guide explains how to make safe changes to Aisly.

## Recommended Reading Order

Before changing code, read:

1. [TECHNICAL_OVERVIEW.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/TECHNICAL_OVERVIEW.md)
2. [PRODUCT_STRATEGY.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/PRODUCT_STRATEGY.md)
3. [adr/README.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/README.md)
4. [FEATURES.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/FEATURES.md)

## Project Rules

Aisly uses:

- SwiftUI
- MVVM
- dependency injection
- local-first persistence
- clean code fundamentals

Core engineering rules:

- keep views thin
- keep view models focused
- use repositories for persistence boundaries
- use services for reusable business rules
- add tests with each meaningful feature
- update docs after meaningful slices

## Product Rules

Before implementing a feature, ask:

1. Does this strengthen recurring shopping speed?
2. Does this improve budget clarity?
3. Is this necessary before backend and premium work?

If the answer is no, it is probably not the right next slice.

## Validation Expectations

Minimum validation flow:

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyTests test
```

Repository automation now mirrors that flow:

- pull requests and pushes to `main` run the shared unit-test workflow in [ios-ci.yml](/Users/levilunique/Workspace/Swift/Aisly/.github/workflows/ios-ci.yml)
- pushes to `main` and manual dispatches create an unsigned release archive in [ios-cd.yml](/Users/levilunique/Workspace/Swift/Aisly/.github/workflows/ios-cd.yml)
