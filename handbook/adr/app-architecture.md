# App Architecture ADR

## Status

Accepted

## Decision

Aisly uses a pragmatic feature-first MVVM architecture in SwiftUI.

## What This Means

- views render and forward intent
- view models own presentation logic
- services hold reusable business rules
- repositories encapsulate persistence and future remote boundaries
- dependencies are assembled explicitly
- design patterns are applied only when the current slice needs them

## Additional Rule

The app is local-first now and backend-ready later.

That means:

- local persistence comes first
- repository boundaries are required from the start
- backend infrastructure is deferred until the local product is strong

For the project-specific pattern rules, see [design-pattern-adoption.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/design-pattern-adoption.md).
