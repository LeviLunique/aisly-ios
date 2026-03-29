# Design System Standards

Aisly uses a shared SwiftUI design system under [Aisly/DesignSystem](/Users/levilunique/Workspace/Swift/Aisly/Aisly/DesignSystem).

## Why

The app needs a consistent visual foundation that:

- feels native to iOS
- feels like premium household utility rather than a generic checklist app
- stays calm and utility-focused
- scales into future list, item, budget, template, recurrence, store, and shopping-mode slices
- maps cleanly to SwiftUI without importing web interaction patterns

The current standard is informed by the local high-fidelity prototype, but adapted to Aisly's real brand and roadmap rather than copied directly from a React implementation.

## What Is Shared

The current source of truth includes:

- semantic color tokens
- semantic spacing tokens
- semantic typography tokens
- semantic corner-radius tokens
- semantic motion tokens
- shared brand assets such as the Aisly logo, app icon rendering, and compact mark
- reusable SwiftUI components and styles for repeated patterns

Examples:

- `AislyColor.surfacePrimary`
- `AislySpacing.large`
- `AislyTypography.rowTitle`
- `AislySectionHeader`
- `AislyListRowCard`
- `AislyButtonStyle`
- `AislyEmptyState`
- `AislyLoadingState`
- `AislyProgressBar`
- `AislyLogo`
- `AislyMark`

## Rules

- Prefer design-system tokens over inline color, spacing, font, and radius values when the token already exists.
- Keep reference designs adapted to native iOS behavior and Apple HIG patterns.
- Keep the visual direction aligned with "soft editorial utility": premium, calm, clear, and practical.
- Use layered neutral surfaces and semantic accents that fit the existing Aisly brand instead of copying prototype colors literally.
- Use the shared 4/8/12/16/20/24/32/40 spacing ladder and the shared rounded-corner scale unless a real new system need appears.
- Prefer the shared motion posture for press feedback, progress transitions, and sheet/state animation instead of one-off animation constants.
- Add a shared component only when the pattern is genuinely reused or clearly needed by the near-term roadmap.
- Use the shared brand assets before drawing new branded symbols inline.
- Let the roadmap shape component growth: item rows, budget summaries, delta badges, quantity controls, price inputs, and shopping-mode surfaces are valid shared-component targets when those slices land.
- Keep names semantic and product-facing, not tied to raw design-tool terminology.
- Document whether a meaningful feature slice adopted the design system and why.

## What To Avoid

- floating action buttons by default
- web-style panel systems
- ad hoc color choices repeated across screens
- custom layout hacks when a native SwiftUI pattern already fits
- prototype-only product surfaces that are not real roadmap priorities yet

See the local ADR for the full project rule: `.ai/docs/adr/0008-design-system-standards.md`.
