# Desenvolvimento Local

Este guia mostra como trabalhar no Aisly localmente.

## Regenerar o projeto

Se você adicionou ou moveu arquivos:

```bash
xcodegen generate
```

Depois:

```bash
open Aisly.xcodeproj
```

## Convenção de branches

Use:

- `feat/` para recursos
- `fix/` para correções
- `chore/` para manutenção e documentação
- `refactor/` para reorganizações internas
- `test/` para mudanças focadas em testes

## Build pela linha de comando

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'generic/platform=iOS Simulator' build
```

## Testes unitários

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyTests test
```

## Testes de interface

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyUITests test
```

## Gerar archive local

```bash
xcodebuild -scheme Aisly -project Aisly.xcodeproj -configuration Release -destination 'generic/platform=iOS' -archivePath build/Aisly.xcarchive CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' archive
```

## Workflows públicos

- [CI iOS](../.github/workflows/ios-ci.yml)
- [CD iOS](../.github/workflows/ios-cd.yml)

## Foco atual do desenvolvimento

Hoje o projeto prioriza:

- persistência local
- listas e itens
- orçamento
- compras recorrentes
- experiência nativa de iOS

Evite antecipar:

- backend
- nuvem
- monetização
- suporte avançado
