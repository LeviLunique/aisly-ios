# Visão Técnica

Este documento explica como o Aisly está estruturado.

## Contexto do produto

O Aisly é um aplicativo offline-first para listas de compras.

Sua proposta principal é:

- acelerar compras recorrentes
- mostrar a diferença entre valor planejado e valor real

## Estilo de arquitetura

O projeto usa uma arquitetura pragmática baseada em:

- SwiftUI
- MVVM
- injeção de dependência
- repositórios para persistência

Na prática:

- as views renderizam estado e eventos
- as view models concentram lógica de apresentação
- os repositórios isolam acesso aos dados
- a montagem de dependências acontece de forma explícita

## Estado atual da base

Hoje o app já inclui:

- `AppContainer` para composição das dependências
- `ShoppingListRepository` como fronteira de persistência
- persistência local em arquivo
- múltiplas listas
- itens, categorias e ordenação
- orçamento planejado e real
- histórico de itens
- templates e recorrência
- memória de loja e preço
- modo de compra
- widget e App Intents
- suporte a inglês e português do Brasil

## Postura arquitetural

O projeto evita:

- singletons como estratégia principal
- persistência dentro das views
- acoplamento direto entre interface e armazenamento
- complexidade sem necessidade imediata

## Localização

Todo texto visível para o usuário deve:

- sair de `Localizable.xcstrings`
- usar chaves semânticas centralizadas
- respeitar formatação por localidade para datas, números e moeda

## Design system

O app usa um design system compartilhado para:

- cores
- tipografia
- espaçamento
- componentes reutilizáveis
- identidade visual da marca

## Persistência

As decisões de armazenamento seguem a classificação dos dados:

- preferências simples: `UserDefaults` ou `@AppStorage`
- dados sensíveis: Keychain
- dados persistentes do app: sistema de arquivos
- dados estruturados mais complexos: possibilidade futura de `SwiftData`

## Leituras relacionadas

- [Arquitetura](adr/app-architecture.md)
- [Injeção de dependência](adr/dependency-injection.md)
- [Padrões de projeto](adr/design-pattern-adoption.md)
- [Design system](adr/design-system-standards.md)
- [Localização](adr/localization-standards.md)
- [Qualidade e testes](adr/quality-and-testing.md)
- [Posicionamento de produto](adr/product-positioning.md)
- [Armazenamento](adr/storage-standards.md)
