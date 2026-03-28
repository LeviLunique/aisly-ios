# Technical Overview

This document explains how Aisly should be structured and why.

## Product Context

Aisly is a shopping app focused on:

- shared shopping
- recurring shopping speed
- budget-aware decision support

## Architectural Style

The app uses a pragmatic feature-first MVVM architecture.

That means:

- views render state
- view models own presentation logic
- services hold reusable business rules
- repositories handle persistence and external boundaries
- dependencies are assembled explicitly

## Core Rules

- keep views thin
- keep business rules out of views
- keep persistence details out of view models
- inject dependencies at boundaries
- test view models and services directly

## Product-Specific Technical Priorities

The architecture should make these areas easy to evolve:

- totals and derived amounts
- recurring item generation
- price history
- store-aware price memory
- shared-list state changes

## Reference Decisions

For the reasoning behind this overview, see:

- [app-architecture.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/app-architecture.md)
- [dependency-injection.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/dependency-injection.md)
- [quality-and-testing.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/quality-and-testing.md)
- [product-positioning.md](/Users/levilunique/Workspace/Swift/Aisly/handbook/adr/product-positioning.md)
