# Flutter — 06. Banco Local

## Objetivo

Persistir dados necessários para operação offline e fila de sincronização.

## Dados candidatos

- sessão/configuração segura conforme estratégia;
- entregas sincronizadas;
- itens;
- ofertas;
- contrapropostas;
- status e eventos locais;
- localização pendente;
- mídia pendente;
- sync queue.

## Requisitos

- migrations/versionamento;
- transações locais;
- índices adequados;
- limpeza/retenção conforme política;
- criptografia para dados que exigirem maior proteção.

## Fonte

Não assumir que todo dado local é verdadeiro para sempre. A API pode reconciliar o estado durante sincronização.
