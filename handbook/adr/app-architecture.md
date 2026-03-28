# App Architecture ADR

## Status

Accepted

## Decision

Aisly uses a pragmatic feature-first MVVM architecture in SwiftUI.

## What This Means

- views render and forward intent
- view models own presentation logic
- services hold reusable business rules
- repositories encapsulate persistence and external boundaries
- dependencies are assembled explicitly

## What To Avoid

- giant framework-coupled view models
- architecture added only for ceremony
- generic repositories with no domain value
