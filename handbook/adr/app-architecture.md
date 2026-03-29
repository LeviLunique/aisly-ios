# ADR: Arquitetura do Aplicativo

## Status

Aceita

## Decisão

O Aisly adota SwiftUI com arquitetura MVVM.

## Implicações

- views cuidam de layout e interação
- view models concentram estado de apresentação
- repositórios isolam persistência
- dependências são montadas explicitamente
- padrões são usados apenas quando o problema pede

## Regra adicional

O produto é local-first agora e preparado para backend depois.

Isso significa:

- persistência local vem primeiro
- fronteiras de repositório são obrigatórias desde o início
- infraestrutura online é adicionada depois, sem reescrever a base

## Leitura complementar

- [Padrões de projeto](design-pattern-adoption.md)
