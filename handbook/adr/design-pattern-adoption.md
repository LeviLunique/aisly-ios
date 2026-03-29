# ADR: Adoção de Padrões de Projeto

## Status

Aceita

## Decisão

O Aisly utiliza padrões de projeto apenas quando eles resolvem um problema concreto da etapa atual.

## Primeiras escolhas aprovadas

- Repository para persistência e fronteiras externas
- Adapter para APIs da Apple e infraestrutura
- funções de fábrica no container
- Strategy quando regras de domínio realmente variam
- observação de estado compatível com SwiftUI

## Padrões condicionais

Use apenas quando necessário:

- Facade
- Decorator
- Builder
- Delegate

## O que evitar por padrão

- singletons personalizados
- hierarquias complexas sem ganho prático

## Observação

O projeto prefere composição e soluções idiomáticas de Swift em vez de versões excessivamente acadêmicas dos padrões.
