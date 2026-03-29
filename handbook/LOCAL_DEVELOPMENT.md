# Local Development

This guide explains how to work on Aisly locally.

## Open the Project

If you added or moved source files, regenerate the project first:

```bash
xcodegen generate
```

Then open the project:

```bash
open Aisly.xcodeproj
```

## Branch Naming

Use the standard conventional branch prefixes:

- `feat/` for feature slices
- `fix/` for bugs
- `chore/` for maintenance or documentation
- `refactor/` for non-behavioral code cleanup
- `test/` for test-only changes

Prefer lowercase, hyphenated names such as `feat/offline-architecture-foundation`.

## Build from the Command Line

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build
```

## Run the CI Unit-Test Lane

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyTests test
```

## Run the Locale UI-Test Lane

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyUITests test
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

Localization is also mandatory by default.

Storage classification is also mandatory by default.

Shared design-system tokens and components are also mandatory by default when a feature changes UI.

Shared motion tokens and native-feeling design-system animation patterns are also mandatory by default when a feature changes interaction styling.

That means current development should use:

- `Localizable.xcstrings`
- semantic string access through `AppStrings` or an equally explicit text boundary
- locale-aware formatting APIs
- locale previews and UI checks when a screen changes
- catalog-backed expectations in UI tests instead of hardcoded translated copy
- semantic UI styling through `Aisly/DesignSystem` when the tokens or components already fit the screen
- shared motion styling through `Aisly/DesignSystem` when the app already has a matching animation posture for the interaction
- `Application Support` for persistent app-managed files
- Keychain only for future sensitive data
- `UserDefaults` or `@AppStorage` only for lightweight non-sensitive settings

That means current development should focus on:

- local persistence
- local list behavior
- budget calculations
- shopping interaction quality

Not on:

- backend integration
- purchases
- cloud support workflows
