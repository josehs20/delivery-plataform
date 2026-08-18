# 03 — Casos de Uso

## Convenção

Cada caso de uso contém:

- objetivo;
- ator;
- pré-condições;
- fluxo principal;
- alternativas/exceções;
- pós-condições.

## UC-001 — Cadastrar comércio

**Ator:** Comércio

**Objetivo:** criar uma conta comercial.

**Pré-condições:** dados ainda não cadastrados para o identificador utilizado.

**Fluxo:** informar dados → validar → criar conta → estado inicial.

**Pós-condição:** conta criada e disponível para completar cadastro do estabelecimento.

## UC-002 — Cadastrar motoboy

**Ator:** Motoboy

**Fluxo:** informar dados pessoais → informar veículo → enviar documentos → aguardar análise.

**Pós-condição:** motoboy criado com status de aprovação pendente.

## UC-003 — Aprovar motoboy

**Ator:** Admin

**Fluxo:** consultar cadastro → analisar documentação → aprovar/reprovar → registrar auditoria.

## UC-004 — Criar entrega

**Ator:** Comércio

**Pré-condições:** comércio autenticado e apto a solicitar.

**Fluxo:** informar origem → informar destino com coordenadas → selecionar múltiplos itens → informar destinatário → informar prazo limite quando aplicável → escolher precificação → revisar → publicar.

## UC-005 — Calcular preço da entrega

**Ator:** Comércio/Sistema

**Fluxo:** sistema recebe origem/destino e parâmetros → aplica configuração vigente → devolve valor sugerido.

O valor sugerido não é necessariamente o valor final contratado.

## UC-006 — Definir preço manual

**Ator:** Comércio

**Fluxo:** comércio informa valor → sistema valida limites/regras → armazena oferta inicial.

## UC-007 — Publicar entrega

**Ator:** Comércio

**Fluxo:** validar conteúdo → criar estado OPEN → identificar motoboys elegíveis/próximos → emitir notificações.

## UC-008 — Receber oferta

**Ator:** Motoboy

O motoboy recebe informações necessárias para decidir se aceita, incluindo o que será transportado, origem, destino, preço, prazo e demais dados relevantes.

## UC-009 — Aceitar oferta

**Ator:** Motoboy

**Regra:** o primeiro aceite válido que vencer a disputa de concorrência recebe a atribuição.

**Pós-condição:** entrega atribuída; outras ofertas encerradas.

## UC-010 — Recusar oferta

**Ator:** Motoboy

A recusa não deve atribuir a entrega e pode alimentar indicadores operacionais.

## UC-011 — Iniciar contrapropostas

**Ator:** Sistema

Após o timeout configurável sem aceite, habilitar negociação quando a configuração permitir.

## UC-012 — Fazer contraproposta

**Ator:** Motoboy

**Fluxo:** informar valor → validar negociação aberta → registrar contraproposta.

## UC-013 — Recusar contraproposta

**Ator:** Comércio

Uma recusa encerra aquela proposta específica. O motoboy poderá enviar outra enquanto a janela de negociação estiver aberta.

## UC-014 — Aceitar contraproposta

**Ator:** Comércio

**Fluxo:** selecionar contraproposta → validar que ainda está disponível → transação → atribuir entrega → encerrar demais propostas.

## UC-015 — Ter múltiplas entregas

**Ator:** Motoboy

O motoboy pode ter mais de uma entrega ativa simultaneamente, desde que as regras operacionais permitam.

## UC-016 — Ir para coleta

**Ator:** Motoboy

Visualizar origem → navegar → registrar localização → chegar.

## UC-017 — Confirmar chegada à coleta

**Ator:** Motoboy

Registrar evento de chegada. Pode funcionar offline.

## UC-018 — Confirmar coleta

**Ator:** Motoboy

Registrar que a mercadoria foi recebida. Pode exigir evidência futura conforme regra específica.

## UC-019 — Atualizar localização

**Ator:** Motoboy

Enviar posição periódica durante entrega ativa, ou armazenar localmente quando offline.

## UC-020 — Chegar ao destino

**Ator:** Motoboy

Registrar chegada ao destino.

## UC-021 — Registrar prova de entrega

**Ator:** Motoboy

Informar recebedor → capturar foto → registrar GPS → registrar data/hora → salvar evidência.

## UC-022 — Finalizar entrega

**Ator:** Motoboy

Validar requisitos de prova → validar estado → transação → estado DELIVERED → gerar evento → iniciar fluxo financeiro.

## UC-023 — Registrar falha

**Ator:** Motoboy/Admin

Selecionar motivo → fornecer evidência obrigatória conforme motivo → registrar localização → registrar evento.

## UC-024 — Solicitar cancelamento pelo comércio

**Ator:** Comércio

Validar estado → motivo → confirmação → aplicar regra financeira → se já coletado, iniciar devolução.

## UC-025 — Cancelar pelo motoboy

**Ator:** Motoboy

Informar motivo → registrar impacto operacional → se houver mercadoria, iniciar devolução.

## UC-026 — Devolver mercadoria

**Ator:** Motoboy + Comércio

Motoboy leva o item ao ponto de origem → registra devolução → comércio confirma recebimento → estado RETURNED.

## UC-027 — Processar pagamento

**Ator:** Sistema/PSP

Registrar transação → confirmar/reservar → manter referência externa → após entrega concluída, liberar fluxo de repasse.

## UC-028 — Estornar pagamento

**Ator:** Sistema/Admin

Determinar política → solicitar estorno → acompanhar retorno → atualizar estado financeiro.

## UC-029 — Sincronizar dados offline

**Ator:** Aplicativo

Ler fila local → enviar eventos pendentes → tratar resposta → marcar sincronizado → repetir com backoff em falhas.

## UC-030 — Intervenção administrativa

**Ator:** Admin

Consultar contexto → executar ação permitida → registrar motivo → registrar auditoria → emitir notificações necessárias.

## UC-031 — Consultar histórico

**Atores:** Comércio, Motoboy, Admin

Exibir somente escopo autorizado.

## UC-032 — Receber notificações

**Atores:** Comércio/Motoboy

Push e/ou atualização em tempo real conforme evento.

## Casos de uso adicionais que devem ser detalhados posteriormente

- recuperação de senha;
- logout e gestão de sessão;
- bloqueio/desbloqueio;
- atualização cadastral;
- troca de veículo;
- expiração de documentos;
- gestão de endereços;
- configuração operacional;
- relatórios administrativos.
