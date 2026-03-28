# Dependency Injection ADR

## Status

Accepted

## Decision

Aisly uses dependency injection at real boundaries.

## What This Means

- view models receive repositories and services
- tests can inject fakes
- future backend and billing clients can be added without rewriting feature code

## What To Avoid

- hidden global mutable state
- singletons as the main composition strategy
- protocols with no real substitution value
