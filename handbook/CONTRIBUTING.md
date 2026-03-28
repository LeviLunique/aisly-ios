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
- clean code fundamentals

Core engineering rules:

- keep views thin
- keep view models focused
- use repositories for persistence boundaries
- use services for reusable business rules
- add tests with each meaningful feature
- update docs after meaningful slices

## Validation Expectations

Minimum validation flow:

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' test
```

## Documentation Expectations

Update the handbook when you change:

- contributor workflow
- feature behavior
- architecture understanding
- local validation steps
- product positioning
