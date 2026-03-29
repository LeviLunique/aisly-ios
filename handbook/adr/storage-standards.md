# ADR: Padrões de Armazenamento

## Status

Aceita

## Decisão

O Aisly classifica os dados antes de escolher onde armazená-los.

## O que isso significa

- `UserDefaults` ou `@AppStorage` apenas para preferências simples e não sensíveis
- Keychain para dados sensíveis
- sistema de arquivos para payloads serializados e persistentes do app
- `SwiftData` pode ser adotado no futuro para dados relacionais mais complexos
- views não devem acessar persistência diretamente
- mudanças de persistência devem vir acompanhadas de testes
