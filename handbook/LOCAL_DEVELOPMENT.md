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

## Run the CI Unit-Test Lane

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyTests test
```

## Create the CD Archive Locally

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -configuration Release -destination 'generic/platform=iOS' -archivePath build/Aisly.xcarchive CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' archive
```

## GitHub Actions Workflows

- pull requests and pushes to `main` run [ios-ci.yml](/Users/levilunique/Workspace/Swift/Aisly/.github/workflows/ios-ci.yml)
- pushes to `main` and manual dispatches run [ios-cd.yml](/Users/levilunique/Workspace/Swift/Aisly/.github/workflows/ios-cd.yml)
- CI uploads the `xcresult` bundle for unit-test inspection
- CD uploads an unsigned `.xcarchive` artifact for release validation

## Full Scheme Tests

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' test
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
