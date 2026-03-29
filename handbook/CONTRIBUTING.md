# Contribuindo com o Aisly

Este guia explica como fazer alterações seguras no projeto.

## Leitura recomendada antes de alterar código

1. [Visão técnica](TECHNICAL_OVERVIEW.md)
2. [Estratégia de produto](PRODUCT_STRATEGY.md)
3. [ADRs](adr/README.md)
4. [Recursos e roadmap](FEATURES.md)

## Princípios do projeto

O Aisly usa:

- SwiftUI
- MVVM
- injeção de dependência
- persistência local
- foco em código legível e testável

## Regras de engenharia

- mantenha as views leves
- concentre a lógica de apresentação nas view models
- use repositórios para isolar persistência
- adicione testes em mudanças relevantes
- prefira mudanças pequenas e coesas
- atualize o handbook quando um recurso mudar de forma relevante

## Convenção de branches

Use nomes curtos, em minúsculas e com hífens:

- `feat/<nome-do-recurso>`
- `fix/<nome-do-problema>`
- `chore/<nome-da-tarefa>`
- `refactor/<escopo>`
- `test/<escopo>`

Exemplos:

- `feat/local-lists`
- `fix/home-loading-state`
- `chore/update-handbook`

## Como validar mudanças

Fluxo mínimo recomendado:

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyTests test
```

## Fluxos automatizados

Os workflows públicos do repositório ficam em:

- [CI iOS](../.github/workflows/ios-ci.yml)
- [CD iOS](../.github/workflows/ios-cd.yml)
