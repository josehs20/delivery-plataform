# Fechamento do Domínio — MVP

## Status

Baseline v1 — Approved for technical modeling.

## O que foi fechado

1. Agregado `Delivery` como núcleo operacional.
2. Usuários: Comércio, Motoboy e Admin.
3. Motoboy pode atuar em qualquer região.
4. Oferta prioriza motoboys próximos da origem.
5. Comércio pode usar preço calculado ou manual.
6. Motoboys podem aceitar diretamente.
7. Contrapropostas ficam disponíveis após timeout configurável sem aceite.
8. O comércio pode recusar uma contraproposta e o mesmo motoboy pode fazer outra enquanto a negociação estiver aberta.
9. Motoboy pode possuir múltiplas entregas ativas.
10. Entrega contém múltiplos itens.
11. Destino exige endereço e coordenadas.
12. Motoboy recebe os dados da carga antes de aceitar e decide se consegue transportá-la.
13. Cancelamentos após coleta exigem fluxo de devolução quando aplicável.
14. Comércio confirma recebimento da devolução.
15. Pagamento da taxa da entrega é eletrônico no MVP e realizado antes da execução final conforme PSP.
16. Repasse ao motoboy ocorre após conclusão e validações financeiras.
17. Prova mínima: nome do recebedor, foto, GPS, data/hora e observação opcional.
18. Motoboy pode executar entrega já sincronizada offline.
19. Comércio não cria nova entrega offline no MVP.
20. Operações críticas devem ser idempotentes.
21. Aceitação/atribuição deve ser protegida contra concorrência.
22. Fornecedores externos devem ser abstraídos.

## Assuntos deliberadamente configuráveis

Ainda não são valores hardcoded:

- timeout de aceite;
- timeout de negociação;
- distância de oferta;
- preço base;
- preço por km;
- valor mínimo;
- adicionais;
- comissão;
- frequência de GPS;
- política detalhada de cancelamento por estado;
- política detalhada de evidência por motivo de falha.

## Gate para banco e API

O domínio está suficientemente definido para iniciar:

1. ERD conceitual;
2. modelo relacional;
3. dicionário de dados;
4. contratos de API.

Antes de migrations de produção, validar o ERD contra cardinalidades e constraints.
