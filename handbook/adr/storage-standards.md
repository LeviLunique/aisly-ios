# Storage Standards ADR

## Status

Accepted

## Decision

Aisly classifies data before choosing a local storage mechanism.

## What This Means

- use `UserDefaults` or `@AppStorage` only for lightweight non-sensitive preferences
- use Keychain for tokens, passwords, credentials, and any sensitive data
- use the file system for large or serialized payloads, with `Application Support` for persistent app-managed data and `Caches` for discardable data
- prefer `SwiftData` for future structured relational persistence on iOS 17+, and use `Core Data` only with a clear compatibility or capability reason
- keep storage APIs behind repositories or services instead of touching them from views
- add tests when persistence rules or storage classifications change
