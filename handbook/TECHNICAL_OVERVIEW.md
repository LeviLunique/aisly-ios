# Technical Overview

This document explains how Aisly should be structured and why.

## Product Context

Aisly is an offline-first shopping app.

Its first strong product promise is not "make a list".
It is:

- make recurring shopping faster
- help users see expected versus actual spend

## Architectural Style

The app uses a pragmatic feature-first MVVM architecture.

That means:

- views render state
- view models own presentation logic
- services hold reusable business rules
- repositories hide persistence and future remote boundaries
- dependencies are assembled explicitly

## Core Product Implication

The app is local-first now and backend-ready later.

That means:

- the first implementation stores data locally on device
- repository boundaries must exist from the start
- a future backend should be additive, not a rewrite

## Core Technical Priorities

The architecture should make these easy to evolve:

- multiple local lists
- totals and deltas
- shopping-mode interaction
- recurrence and templates
- price memory by store

## What the Architecture Should Avoid

- iCloud-only lock-in as the long-term collaboration story
- payment infrastructure before premium value exists
- feature sprawl before the local product is strong
- view models coupled directly to persistence frameworks everywhere

## Reference Decisions

For the reasoning behind this overview, see:

- [app-architecture.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/app-architecture.md)
- [dependency-injection.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/dependency-injection.md)
- [quality-and-testing.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/quality-and-testing.md)
- [product-positioning.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/product-positioning.md)
