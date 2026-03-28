# Local Development

This guide explains how to work on Aisly locally.

## Open the Project

```bash
open Aisly.xcodeproj
```

## Build from the Command Line

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build
```

## Run Tests

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' test
```

## Before Starting Work

Read:

- [TECHNICAL_OVERVIEW.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/TECHNICAL_OVERVIEW.md)
- [PRODUCT_STRATEGY.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/PRODUCT_STRATEGY.md)
- [FEATURES.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/FEATURES.md)
