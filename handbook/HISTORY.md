# Histórico de Entregas

Este documento resume a evolução do Aisly por etapas.

## Status das etapas

- Stage 0: concluída
- Stage 0B: concluída
- Stage 1: concluída
- Stage 2: concluída
- Stage 3: concluída
- Stage 4: concluída
- Stage 5: concluída
- Stage 6: concluída
- Stage 7: concluída
- Stage 8: concluída
- Stage 9: concluída
- Stage 10: pendente
- Stage 11: pendente

## Entregas concluídas

### Stage 0

- estrutura inicial do repositório
- projeto Xcode
- targets do app e de testes

### Stage 0B

- workflow de CI
- workflow de CD com archive sem assinatura
- baseline inicial de testes

### Stage 1. Offline Architecture Foundation

- `AppContainer`
- `ShoppingList`
- `ShoppingListRepository`
- persistência local em arquivo
- tela inicial em MVVM
- suporte a inglês e português do Brasil

### Stage 2. Multiple Local Lists

- múltiplas listas
- renomear e arquivar listas
- separação entre listas ativas e arquivadas
- primeira base compartilhada do design system

### Stage 3. Local Items and Categories

- detalhe da lista
- CRUD de itens
- quantidade
- categorias
- ordenação local

### Stage 4. Budget Core

- preço planejado
- preço real
- totais da lista
- diferença de orçamento

### Stage 5. Quick Entry and History

- histórico de itens
- sugestões rápidas
- preenchimento automático do rascunho de item

### Stage 6. Templates and Recurrence

- templates locais
- recorrência semanal, quinzenal e mensal
- geração de listas a partir de templates

### Stage 7. Store and Price Memory

- nome da loja por item
- sugestões de lojas recentes
- memória de último preço por loja

### Stage 8. Shopping Mode

- tela dedicada para a compra
- conclusão de itens
- edição de preço real durante a compra
- progresso e totais da sessão

### Stage 9. Apple-First Convenience

- widget
- App Intents
- atalhos de entrada rápida no app
- deep links para fluxos internos

## Trabalho complementar

Além das etapas principais, existe uma branch remota dedicada ao design system:

- `feat/swiftui-design-system`

Ela expande:

- tokens visuais
- componentes reutilizáveis
- identidade visual da marca

## Próxima prioridade

A próxima etapa correta é:

- online readiness
