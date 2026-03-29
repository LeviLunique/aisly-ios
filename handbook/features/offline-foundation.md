# Fundação Offline

Esta página resume a primeira etapa importante da arquitetura do Aisly.

## O que foi entregue

- `AppContainer`
- modelo `ShoppingList`
- protocolo `ShoppingListRepository`
- persistência local em arquivo
- tela inicial em MVVM
- suporte a inglês e português do Brasil

## Por que isso importa

Essa etapa transformou o projeto em uma base real para evolução do produto, permitindo crescimento sem reescrever a estrutura principal.

## Como validar

1. Rode `xcodegen generate`.
2. Rode `xcodebuild -scheme Aisly -project Aisly.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AislyTests test`.
3. Abra o app.
4. Confirme que a tela inicial carrega estado local.
