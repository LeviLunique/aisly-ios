# Localization Standards ADR

## Status

Accepted

## Decision

Aisly treats localization as a default requirement for user-facing features.

## Core Rules

- user-facing copy belongs in `Localizable.xcstrings`
- raw localization keys stay in one shared semantic key registry
- app-facing localized resources stay behind semantic helpers such as `AppStrings`
- the default shipped locales are `en` and `pt-BR`
- visible numbers, dates, currency, and measurements must use locale-aware APIs
- view models expose semantic state or localization keys, not hardcoded UI strings
- tooling-only strings should stay simple unless they are actually rendered in the shipped UI

## Testing Rules

- unit tests should validate the catalog and catch hardcoded localized UI literals
- unit tests should protect centralized localization access and missing-key coverage
- unit tests should protect the shared raw-key registry from duplication in app and UI-test files
- previews should cover multiple locales when practical
- preview tooling labels may stay hardcoded when they are only for development use
- previews should stay simple and stable instead of being abstracted for non-user-facing text
- preview fixture data that can render on screen should come from centralized semantic text access such as `AppStrings.Mock`
- UI tests should verify locale launch behavior for visible screens without hardcoded translated expectations or test-local key definitions

## Documentation Rule

- feature READMEs should state whether the slice adopts the text and localization rules and explain any exception

## Key Naming

Prefer feature-oriented keys such as:

- `feature.screen.element.action`
- `feature.section.element.label`
- `feature.state.element.message`
