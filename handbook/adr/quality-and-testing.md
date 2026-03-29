# Quality and Testing ADR

## Status

Accepted

## Decision

Aisly keeps a minimum baseline of 5 unit tests, localizes user-facing copy, and updates shared docs for meaningful slices.

## What This Means

- meaningful slices add direct tests
- user-facing text belongs in `Localizable.xcstrings`, not Swift source
- raw localization keys stay centralized instead of being scattered through feature files and tests
- visible locale-sensitive values should use platform formatting APIs
- storage choices should be tested when a slice introduces or changes persistence
- newly introduced patterns must stay justified and testable
- public handbook pages stay aligned with shipped behavior
- delivery history remains explicit instead of tribal knowledge
