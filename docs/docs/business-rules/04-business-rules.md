# 04 — Regras de Negócio

## 1. Regras gerais

### RB-001 — Backend como autoridade

Estados, valores financeiros e permissões críticas devem ser validados no backend.

### RB-002 — Proximidade

Uma entrega deve ser disponibilizada prioritariamente aos motoboys elegíveis que estejam próximos da origem segundo a distância operacional configurada.

### RB-003 — Região de atuação do motoboy

O motoboy não fica limitado ao município cadastrado. A proximidade atual é o principal fator para oferta no MVP.

### RB-004 — Múltiplas entregas

Um motoboy pode possuir várias entregas ativas simultaneamente.

### RB-005 — Itens

Uma entrega pode conter vários itens.

### RB-006 — Localização de destino

Destino deve possuir endereço e coordenadas.

### RB-007 — Capacidade

O motoboy é responsável por avaliar se consegue transportar a carga com base nas informações apresentadas.

### RB-008 — Timeout configurável

Prazos de oferta e negociação não devem ser hardcoded.

## 2. Regras de oferta

### RB-OFFER-001

Uma entrega aberta gera uma oportunidade de serviço para motoboys elegíveis próximos.

### RB-OFFER-002

O aceite é uma operação concorrente.

### RB-OFFER-003

Somente um motoboy pode vencer a atribuição de uma entrega.

### RB-OFFER-004

Ao efetivar a atribuição, ofertas concorrentes devem ser encerradas.

### RB-OFFER-005

A atribuição deve ocorrer atomicamente.

## 3. Contrapropostas

### RB-NEG-001

Contrapropostas ficam disponíveis somente após o período configurado sem aceite direto, salvo configuração futura diferente.

### RB-NEG-002

Uma contraproposta pertence a um motoboy e a uma entrega.

### RB-NEG-003

O comércio pode aceitar qualquer contraproposta ainda válida.

### RB-NEG-004

A recusa de uma contraproposta não encerra toda a negociação.

### RB-NEG-005

O mesmo motoboy pode fazer nova contraproposta enquanto a negociação estiver aberta.

### RB-NEG-006

Ao aceitar uma contraproposta, todas as demais propostas ficam sem efeito.

## 4. Preço

### RB-PRICE-001

O comércio pode optar por preço calculado ou preço manual, conforme configuração do produto.

### RB-PRICE-002

O valor efetivamente contratado deve ser persistido como snapshot.

### RB-PRICE-003

Regras de preço são configuráveis pelo Admin.

### RB-PRICE-004

O Flutter não calcula sozinho o valor financeiro oficial.

## 5. Pagamentos

### RB-PAY-001

O comércio deve realizar o pagamento/reserva antes da execução final do serviço, conforme integração com PSP.

### RB-PAY-002

O motoboy não recebe o repasse definitivo antes da conclusão da entrega, salvo regra financeira futura explicitamente aprovada.

### RB-PAY-003

Comissão da plataforma deve ser registrada separadamente.

### RB-PAY-004

Estornos devem possuir referência ao pagamento original.

### RB-PAY-005

Valores financeiros devem ser armazenados com precisão monetária adequada e sem usar float para cálculos de domínio.

## 6. Cancelamentos

### RB-CANCEL-001

Cancelamento depende do estado da entrega.

### RB-CANCEL-002

Cancelamento após coleta exige fluxo de devolução.

### RB-CANCEL-003

Toda solicitação de cancelamento deve registrar motivo.

### RB-CANCEL-004

Quando exigido, cancelamentos precisam de evidência.

## 7. Falhas

### RB-FAIL-001

Toda falha possui motivo padronizado.

### RB-FAIL-002

Evidências são exigidas segundo o tipo de falha.

### RB-FAIL-003

Falhas devem ser auditáveis.

## 8. Devolução

### RB-RETURN-001

Mercadoria coletada não pode simplesmente desaparecer do fluxo quando houver cancelamento.

### RB-RETURN-002

O motoboy deve devolver ao local de origem quando a regra exigir.

### RB-RETURN-003

O comércio deve confirmar o recebimento da devolução.

## 9. Offline

### RB-OFF-001

O aplicativo do motoboy deve suportar execução offline para entregas já sincronizadas.

### RB-OFF-002

O aplicativo do comércio não cria novas solicitações enquanto offline no MVP.

### RB-OFF-003

Eventos offline devem ser persistidos antes de confirmação ao usuário.

### RB-OFF-004

Sincronização deve ser idempotente.

## 10. Auditoria

### RB-AUD-001

Mudanças relevantes de estado devem gerar eventos de histórico.

### RB-AUD-002

Intervenções administrativas devem registrar operador, motivo e data/hora.

## 11. Regras configuráveis

Devem ser configuráveis, sem hardcode de negócio:

- timeout de aceite;
- timeout de negociação;
- distância de oferta;
- preço base;
- valor por km;
- mínimo;
- adicionais;
- comissão;
- critérios operacionais;
- políticas de cancelamento quando apropriado.
