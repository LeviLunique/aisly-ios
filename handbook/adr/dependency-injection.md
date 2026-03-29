# ADR: Injeção de Dependência

## Status

Aceita

## Decisão

O Aisly usa injeção de dependência em fronteiras reais.

## O que isso significa

- view models recebem repositórios e serviços
- testes podem usar doubles e implementações falsas
- novas integrações podem ser adicionadas sem acoplar a interface a detalhes concretos

## O que evitar

- estado global mutável
- singletons como composição principal
- protocolos sem valor real de substituição
