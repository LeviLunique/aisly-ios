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

## Current Development Rule

The app is offline-first for now.

That means current development should focus on:

- local persistence
- local list behavior
- budget calculations
- shopping interaction quality

Not on:

- backend integration
- purchases
- cloud support workflows
