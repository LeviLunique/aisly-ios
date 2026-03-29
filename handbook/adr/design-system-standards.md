# ADR: Padrões do Design System

## Status

Aceita

## Decisão

O Aisly usa um design system compartilhado em SwiftUI.

## Objetivo

Garantir uma base visual que seja:

- nativa do iOS
- consistente
- reutilizável
- escalável para as próximas etapas do produto

## O que faz parte do design system

- tokens de cor
- tokens de espaçamento
- tokens de tipografia
- tokens de raio
- tokens de movimento
- componentes compartilhados
- ativos de marca, como logo e símbolo

## Regras

- prefira tokens e componentes existentes antes de criar estilos inline
- mantenha aderência ao comportamento nativo do iOS
- evite copiar padrões visuais da web sem adaptação
- adicione novos componentes compartilhados apenas quando houver reutilização clara

## Exemplos

- `AislyColor`
- `AislySpacing`
- `AislyTypography`
- `AislySectionHeader`
- `AislyEmptyState`
- `AislyLoadingState`
- `AislyProgressBar`
- `AislyLogo`
