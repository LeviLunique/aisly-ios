# Recursos e Roadmap

Este documento resume o que já existe no Aisly e o que ainda deve vir.

## Situação atual

O projeto já possui:

- base offline com arquitetura MVVM
- múltiplas listas locais
- itens e categorias
- orçamento por lista
- entrada rápida baseada em histórico
- templates e recorrência
- memória de loja e preço
- modo de compra
- conveniência nativa do ecossistema Apple

Também existe uma branch dedicada para evolução do design system:

- `feat/swiftui-design-system`

## Recursos já implementados

### Fundamentos offline

- container de dependências
- repositório para listas
- persistência local em arquivo
- tela inicial com carregamento de estado local

### Múltiplas listas locais

- criar lista
- renomear lista
- arquivar lista
- separar listas ativas e arquivadas

### Itens e categorias

- criar item
- editar item
- excluir item
- reordenar itens
- categorias e quantidade

### Núcleo de orçamento

- preço planejado por item
- preço real por item
- total planejado
- total real
- diferença de orçamento

### Entrada rápida e histórico

- sugestões de itens recorrentes
- preenchimento automático de nome, categoria, quantidade e preço planejado

### Templates e recorrência

- salvar lista como template
- definir recorrência
- gerar nova lista a partir de template

### Memória de loja e preço

- associar item a uma loja
- sugerir lojas recentes
- recuperar último preço conhecido por loja

### Modo de compra

- marcar itens como concluídos
- editar preço real durante a compra
- acompanhar progresso e totais

### Conveniência Apple

- widget
- App Intents
- atalhos via Siri e Shortcuts
- deep links internos

## O que ainda deve esperar

Itens adiados de propósito:

- backend
- sincronização em nuvem
- listas compartilhadas
- compras dentro do app
- OCR
- leitura de código de barras
- suporte avançado

## Leitura complementar

- [Histórico](HISTORY.md)
- [Fundação offline](features/offline-foundation.md)
- [Listas locais](features/local-lists.md)
- [Itens e categorias](features/items-and-categories.md)
- [Orçamento](features/budget-core.md)
- [Entrada rápida](features/quick-entry-history.md)
- [Templates](features/templates-and-recurrence.md)
- [Memória de preço](features/store-price-memory.md)
- [Modo de compra](features/shopping-mode.md)
- [Conveniência Apple](features/apple-surface.md)
