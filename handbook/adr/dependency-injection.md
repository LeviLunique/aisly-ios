# Dependency Injection ADR

## Status

Accepted

## Decision

Aisly uses dependency injection at real boundaries.

## What This Means

- view models receive repositories and services
- tests can inject fakes
- previews can inject lightweight sample dependencies

## What To Avoid

- hidden global mutable state
- singletons as the default composition model
- protocols with no real substitution value
