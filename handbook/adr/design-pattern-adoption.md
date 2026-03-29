# Design Pattern Adoption ADR

## Status

Accepted

## Decision

Aisly uses design patterns only when they solve a concrete problem in the current slice.

The project prefers Swift-friendly, composition-based implementations over textbook inheritance-heavy versions.

## Approved First Choices

- repositories for persistence and external boundaries
- adapters for Apple and infrastructure APIs
- factory functions through the app container or feature factories
- strategies when the domain truly needs interchangeable rules
- scoped observation through SwiftUI-friendly state propagation

## Conditional Patterns

Use only when the slice clearly needs them:

- facades for simplifying multi-step subsystems
- decorators for logging, caching, metrics, retry, or fallback around a stable contract
- builders for genuinely complex configuration assembly
- delegates for UIKit or system API integration

## Avoid By Default

- custom singletons

Use the app container for app-lifetime dependencies instead of global mutable objects.

## Pattern Notes

- `Factory Method` is expressed in Aisly as factory functions or factory structs, not subclass hierarchies.
- `Observer` should stay scoped. Do not turn `NotificationCenter` into a global feature-event bus.
- `Delegate` belongs mostly at framework edges because Aisly is SwiftUI-first.
- `Strategy` is a strong fit for recurrence, totals, sorting, price suggestion, and future merge policies.
