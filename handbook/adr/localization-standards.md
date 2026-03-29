# ADR: Padrões de Localização

## Status

Aceita

## Decisão

O Aisly trata localização como requisito padrão.

## Regras principais

- textos visíveis ao usuário ficam em `Localizable.xcstrings`
- chaves de localização são centralizadas
- recursos localizados são acessados por uma camada semântica
- os idiomas padrão são inglês e português do Brasil
- datas, números e moeda usam APIs nativas com localidade

## Regras de teste

- testes devem ajudar a detectar textos visíveis hardcoded
- testes devem garantir que as chaves existam no catálogo
- previews e testes de interface devem respeitar a estratégia de localização

## Convenção de chaves

Prefira nomes orientados ao recurso, por exemplo:

- `feature.screen.element.action`
- `feature.section.element.label`
- `feature.state.element.message`
