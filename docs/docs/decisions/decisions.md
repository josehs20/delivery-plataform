# Registro de Decisões e Pendências

## Decisões aprovadas

1. Plataforma B2B2C de intermediação de entregas.
2. Operação on-demand.
3. Atores: Comércio, Motoboy e Admin.
4. Destino informado pelo comércio.
5. Destino exige endereço e coordenadas.
6. Entrega aceita múltiplos itens.
7. Motoboy vê itens antes de aceitar.
8. Motoboy decide se consegue transportar.
9. Sistema pode calcular preço.
10. Comércio pode definir preço manual.
11. Oferta é enviada a motoboys próximos/elegíveis.
12. Motoboy pode atuar em qualquer região.
13. Prazo de aceite é configurável.
14. Contraproposta aparece após timeout sem aceite, conforme configuração.
15. Motoboy pode fazer nova contraproposta se a anterior for recusada e a negociação estiver aberta.
16. Comércio pode escolher contraproposta.
17. Motoboy pode possuir múltiplas entregas.
18. Entrega possui máquina de estados.
19. Pagamento da corrida ocorre antes/na contratação conforme fluxo do PSP.
20. Repasse ao motoboy ocorre após entrega concluída.
21. Cancelamento e falha precisam de políticas próprias.
22. Cancelamento após coleta exige devolução.
23. Comércio confirma recebimento da devolução.
24. Prova de entrega no MVP: nome + foto + GPS + data/hora.
25. GPS será obtido via solução integrada a fornecedor externo.
26. Motoboy deve executar entrega offline.
27. Comércio não cria nova entrega offline no MVP.
28. Eventos offline são sincronizados automaticamente.
29. Backend Laravel.
30. Mobile Flutter.
31. Documentação compartilhada é a fonte de verdade.

## Decisões pendentes

### D-001 — Provedor de pagamentos

Ainda não foi fechado qual PSP será usado no MVP.

**Recomendação:** abstrair o provedor e decidir após requisitos comerciais/KYC/repasse.

### D-002 — Percentual/valor de comissão

A fórmula é configurável, mas o percentual/valor padrão não foi definido.

**Recomendação:** não hardcodar; criar configuração administrativa.

### D-003 — Frequência exata de GPS

Ainda não foi definido o intervalo exato.

**Recomendação:** começar com configuração adaptável e testar consumo de bateria/dados.

### D-004 — Provedor de mapas/rotas

A preferência inicial é utilizar uma API externa; o fornecedor não foi congelado.

**Recomendação:** usar abstração de provider para facilitar troca.

### D-005 — Política completa de cancelamento

Já está definido que depende do estado e que após coleta exige devolução. As tarifas exatas por estado ainda precisam de configuração.

### D-006 — Política de documentação de motoboy

Documentos específicos e critérios legais devem ser definidos com validação jurídica/operacional.

### D-007 — Limites operacionais

Ainda precisam ser definidos:

- distância máxima de oferta;
- quantidade máxima de entregas simultâneas;
- peso máximo padrão;
- valores mínimos/máximos;
- timeout padrão de aceite;
- timeout padrão de negociação.

### D-008 — Agendamento tradicional

Não entra no MVP. Existe somente a necessidade de um `pickup_deadline`.

### D-009 — Avaliação/reputação

Cancelamento pode gerar indicadores de reputação, mas a fórmula de score não está definida.

### D-010 — Multiusuário de comércio

A arquitetura deve suportar, mas o nível de permissões internas pode ser simplificado no MVP.

## Regra para pendências

Nenhuma IA ou desenvolvedor deve transformar uma pendência em decisão silenciosa. A pendência deve continuar visível até ser formalmente decidida.
