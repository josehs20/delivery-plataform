# Contexto Aprendido — Flutter (Delivery Platform)

> **Arquivo de trabalho.** Consolida o conhecimento extraído da leitura de `/docs`
> (fonte de verdade canônica de produto/negócio) antes do desenvolvimento do
> frontend em `./flutter`. Atualizar este arquivo se a arquitetura ou o
> comportamento mudarem materialmente.

**Criado em:** 2026-08-16
**Fontes principais:**
- Regras: `docs/flutter/.cursor/rules/*.mdc`
- Specs técnicas: `docs/flutter/docs/*.md`
- Contrato HTTP: `docs/docs/openapi/openapi.yaml`
- Docs de API: `docs/docs/api/*.md`
- Docs de domínio: `docs/docs/domain/*.md`

---

## 1. Contexto do projeto e fontes de verdade

- `/docs/**` é a fonte de verdade canônica de produto/negócio.
- `/flutter/docs/**` é a fonte de verdade técnica do Flutter.
- Nunca inventar regras de negócio, regras financeiras, estados de entrega,
  permissões ou comportamento de workflow. Requisitos marcados como `pending`
  não devem ter comportamento definido silenciosamente.

### Fronteira cliente/servidor
- **Flutter** = cliente + cache operacional local. **Não** é fonte de verdade
  para estado financeiro ou crítico de entrega.
- **Laravel** = autoridade para: autenticação, autorização, preço final, estado
  de entrega, negociação, pagamentos, refunds, payouts e aceite de sincronização.
- Flutter pode fornecer validação de UX, mas NUNCA é a única validação de regras
  críticas.

### Princípios de domínio
- Um motoboy pode ter **múltiplas entregas ativas**.
- Cada entrega tem seu próprio ciclo de vida e evidências.
- MVP não implementa otimização de rota futura.

---

## 2. Arquitetura (Clean Architecture orientada a features)

Camadas:
- **Presentation/UI** — widgets, telas, navegação.
- **Application/state** — BLoC/Cubit/controllers (orquestração).
- **Domain** — models de domínio, interfaces voltadas a use-cases.
- **Data** — repositories (coordenam local/remoto).
- **Data sources** — remotos (HTTP) e locais (banco).
- **Infra** — sync/offline, integrações externas (mapas, notificações).

Regras:
- Widgets NÃO fazem chamadas de API, SQL ou workflows de domínio complexos.
- Telas se comunicam via estado/controllers.
- Repositories escondem detalhes de persistência da UI.
- DTOs remotos ≠ entidades locais ≠ estado de UI; conversão em mappers/repositories.
- SDKs externos isolados atrás de interfaces próprias.
- Navegação separada de persistência.
- Organizar por domínio de produto (feature-first).

Estrutura alvo:
```text
lib/
├── core/         # network, storage, auth, errors, location, notifications
├── features/     # auth, business, driver, delivery, negotiation, tracking, payments, profile
│   └── <feature>/{presentation, domain, data}
└── app/          # bootstrap, rotas, tema
```

---

## 3. Estado e reatividade (BLoC/Cubit)

- Estratégia única de estado: **BLoC/Cubit** (não misturar com Riverpod etc.).
- Estado de servidor/domínio separado de estado transitório de UI.
- Estados explícitos: `local | sincronizando | sincronizado | falha de sync | conflito`.
- Toda tela operacional deve prever: loading, conteúdo, vazio, erro, offline, sincronizando, sucesso.
- Sem singletons globais mutáveis para estado de negócio.
- Não duplicar estado autoritativo de entrega em múltiplos controllers.
- Estado derivado de repository/dados de aplicação sempre que possível.
- Sem side effects em models/estados puros.

---

## 4. Offline-first

Princípios:
- App do motoboy é offline-first para entrega ativa.
- Persistir localmente ANTES de confirmar ação crítica offline como segura.
- UI diferencia `salvo localmente` de `confirmado pelo servidor`.
- Não fabricar confirmação do servidor quando só a persistência local ocorreu.
- Não assumir disponibilidade de rede; monitorar rede é sinal auxiliar.

Operações offline do motoboy (MVP):
- visualizar entrega sincronizada; registrar chegada; confirmar coleta;
- registrar localização; registrar chegada ao destino; prova de entrega;
- registrar falha; iniciar/registrar devolução; finalizar quando as regras permitirem.

Comércio (MVP): nova solicitação/oferta exige conectividade; histórico offline OK.
**Não criar nova oferta de marketplace offline no MVP.**

## 5. Cliente de API

- Cliente HTTP único e centralizado: base URL, headers, timeout, serialização,
  mapeamento de erros.
- Base do contrato: `/api/v1`, autenticação `bearerAuth` (token no header).
- Interceptors/middleware para autenticação.
- Retry somente quando seguro (idempotente).
- Tratar distintamente: 401, 403, 409, 422, 429, 5xx, timeout, falha de
  conectividade, expiração de auth, erros de validação.
- Serialização/deserialização tipada (DTOs).
- DTOs refletem o OpenAPI; campos desconhecidos devem ser ignorados com segurança.
- Operações críticas retryáveis carregam `Idempotency-Key` (min 8, max 255 chars).
- Nunca enviar valores financeiros autoritativos calculados só pela UI.
- Erros mapeados para domínio/apresentação; sem stack trace para o usuário.

---

## 6. Banco local

- Schema explícito com migrations/versionamento.
- Transações locais, índices adequados, política de limpeza/retensão.
- Criptografia para dados sensíveis; tokens em secure storage (nunca em plain text).
- Distinguir: **cache de estado do servidor** vs **comandos/eventos pendentes locais**.
- Guardar IDs estáveis para reconciliação após reconexão.
- Dados candidatos: sessão/config, entregas sincronizadas, itens, ofertas,
  contrapropostas, status/eventos locais, localização pendente, mídia pendente,
  sync queue.
- Índices: entregas ativas, sync queue, eventos recentes.
- Dado local não é autoridade financeira final.

---

## 7. Motor de sincronização

Componentes: `SyncQueue`, `SyncWorker`, `LocalRepository`, `RemoteRepository`,
`AttachmentUploader`, `SyncConflictHandler`.

### Contrato `POST /api/v1/sync/batch`
```json
{
  "device_id": "...",
  "operations": [{
    "operation_id": "...",
    "entity_type": "DELIVERY",
    "entity_id": "...",
    "operation_type": "CONFIRM_PICKUP",
    "client_created_at": "2026-08-16T12:10:00Z",
    "client_sequence": 42,
    "payload": {}
  }]
}
```
Resposta:
```json
{ "data": [{ "operation_id": "...", "status": "PROCESSED",
             "server_entity_version": 11, "server_timestamp": "..." }] }
```
Status: `PROCESSED | ALREADY_PROCESSED | CONFLICT | RETRY | FAILED`.

### Regras da fila
- Entrada durável: operation_id, entidade, entidade_id, tipo de operação, payload,
  criado_em, tentativas, próximo_retry, status, erro, versão de schema.
- Retry com backoff limitado; sem loop infinito agressivo.
- Mesmo operation_id pode ser reenviado sem duplicar efeito no servidor (idempotência).
- Respeitar dependências entre eventos (ex.: não concluir antes de criar/atribuir).
- Conflito deve ser explícito na UI/estado.
- Timestamps/estado do servidor prevalecem sobre os do cliente.
- Batch tolera sucesso parcial (falha de um item não bloqueia os outros).
- Sincronização sobrevive a restart do app.
- Upload de mídia resumável, separado do evento quando necessário; evento pode
  aguardar mídia se a regra exigir evidência antes da conclusão.

---

## 8. Domínio de entrega / máquina de estados

Estado renderizado SEMPRE a partir de estado sincronizado (server/local), nunca
de flags ad hoc de UI.

Fluxo nominal:
`DRAFT → OPEN → ASSIGNED → DRIVER_ACCEPTED → GOING_TO_PICKUP → AT_PICKUP → PICKED_UP → IN_TRANSIT → AT_DESTINATION → DELIVERED`

Negociação:
`OPEN → NEGOTIATING → ASSIGNED → DRIVER_ACCEPTED → ...`

Falha/devolução:
`PICKED_UP / IN_TRANSIT / AT_DESTINATION → DELIVERY_FAILED → RETURN_REQUIRED → RETURN_IN_PROGRESS → RETURNED → CANCELLED`

Cancelamento (antes da coleta):
`DRAFT / OPEN / NEGOTIATING / ASSIGNED / DRIVER_ACCEPTED → CANCELLED`

Regras:
- Tela não chama endpoint de mudança de status sem comando de negócio válido.
- Exibir histórico de ofertas/contrapropostas com precisão.
- Contramoeda apenas enquanto negociação aberta.
- Após coleta, cancelamento/devolução visivelmente distintos de cancelamento comum.
- Conclusão exige prova de entrega configurada; falha exige motivo e evidência.

## 9. Contratos DTO

DTOs principais: AuthResponse, BusinessDto, DriverDto, DeliveryDto,
DeliveryItemDto, OfferDto, CounterOfferDto, PaymentDto, TrackingPointDto,
NotificationDto, SyncOperationDto.

- DTOs espelham o OpenAPI e permanecem separados das entidades de domínio.
- Parsing tolerante a campos desconhecidos.
- DTO não decide regras de estado de domínio.
- Conversão DTO ↔ entidade em mappers/repositories.
- Referências já existentes em `docs/flutter/lib/`:
  - `core/models/delivery_dto.dart`
  - `core/network/api_client.dart` (interface ApiClient + ApiResponse)
  - `core/sync/sync_operation.dart` (SyncOperation)
  - `core/sync/sync_queue.dart` (interface SyncQueue)

Monetário: valores como string (ex.: `"25.00"`, currency `BRL`); nunca float
para cálculo autoritativo; formatação consistente.

---

## 10. UI/UX

- Estados explícitos em toda tela: loading, sucesso, vazio, erro, offline, retry.
- Ações críticas exigem confirmação/feedback visível.
- Nunca esconder falha de sincronização ou ação financeira atrás de sucesso genérico.
- Diferenciar estado local/pendente de estado confirmado pelo servidor.
- Terminologia de status conforme documentação de produto.
- Permissões de localização e estado de tracking comunicados claramente.
- Não expor dados privados de outro usuário.
- Usável em tamanhos comuns Android/iOS e acessibilidade.

Telas MVP (comércio): Splash/Bootstrap, Login, Cadastro, Dashboard,
Perfil/estabelecimento, Criar entrega, Seleção de itens, Destino no mapa,
Definição de preço, Revisão/pagamento, Ofertas/contrapropostas, Detalhes,
Rastreamento, Histórico, Cancelamento/devolução.

Telas MVP (motoboy): Splash/Bootstrap, Login/cadastro, Status online/offline,
Perfil, Documentos, Veículo/capacidade, Lista de ofertas, Detalhes da oferta,
Contraproposta, Minhas entregas, Mapa/rota, Coleta, Destino, Prova de entrega,
Falha/devolução, Histórico, Ganhos.

---

## 11. Localização e mapas

- Provider externo encapsulado atrás de interface própria.
- Solicitar permissões explicitamente; lidar com negado/restrito.
- Distinguir GPS indisponível de internet indisponível.
- Coordenadas com timestamp; validar precisão antes de uso operacional.
- Rastrear somente quando permitido/necessário (bateria/dados).
- Manter destino offline quando provider suportar.
- Proximidade pode ser calculada localmente, mas elegibilidade oficial é do backend.
- Eventos de localização associados à entrega/contexto correto.

---

## 12. Notificações

- Push é efeito secundário; estado autoritativo vem de dados sincronizados.
- Tratar foreground, background e app terminado.
- Recebimento de notificação não é prova de evento de negócio.
- Abrir notificação navega ao estado sincronizado atual (não confiar em status do payload).
- Deduplicar notificações (backend pode repetir).
- Não expor dados sensíveis/financeiros no payload.
- Permissões conforme plataforma e UX.

---

## 13. Segurança

- Nunca hardcodar segredos/chaves/credenciais no app.
- Tokens em secure storage; nunca logs de tokens/senhas/dados sensíveis.
- HTTPS/TLS fora de dev.
- Não armazenar senha localmente.
- Validar deep links/conteúdo remoto.
- Fotos/evidências = dados operacionais sensíveis; respeitar retenção e limpar
  temporários após sync bem-sucedido.
- Autorização é sempre do servidor; checks no cliente são só UX.

## 14. Tratamento de erros

- Erros explícitos; nunca engolir exceções silenciosamente.
- Distinguir: validação (422), autorização (401/403), conflito (409),
  rate limit (429), conectividade, sync conflict, servidor (5xx), inesperado.
- Falha de conectividade NÃO vira erro permanente quando a ação é enfileirável.
- Nunca mostrar sucesso quando só houve persistência local (a menos que marcado pendente).
- Logs diagnósticos sem dados sensíveis.
- Retry onde apropriado/seguro.

---

## 15. Testes

- Cobertura automatizada para todo workflow crítico.
- Unit: formatação de preço, mapeamento de estados, validações, sync queue,
  retry, idempotência local, regras de formulário.
- Widget: estados críticos (loading, vazio, erro, offline, sincronizando, sucesso).
- Integration/E2E: login, criação de entrega, oferta/aceite, contraproposta,
  coleta, prova de entrega, falha, devolução, sync offline/online.
- Testar duplicidade de eventos de sync e restart durante sync pendente.
- Fakes/mocks para providers remotos e serviços de mapa/pagamento/notificação.
- Regressão para bugs de produção em caminhos críticos.

---

## 16. Performance e acessibilidade

- Sem rebuilds desnecessários; sem trabalho pesado em `build()`.
- Paginar listas grandes de histórico.
- Evitar carregar mídia grande em memória; comprimir/redimensionar evidências antes do upload.
- Sync em background com cuidado com bateria/dados.
- Evitar amostragem GPS frequente sem necessidade operacional.
- Labels acessíveis, alvos de toque, contraste, semântica, texto escalável.

---

## 17. Build, ambientes e flavors

- Ambientes: local/dev, staging, produção.
- URLs/flags de ambiente via configuração controlada; sem segredos commitados.
- Flavors/configuração de build quando útil.
- Builds de produção reprodutíveis; registrar versão do app e versão do schema de sync.
- Definir versões mínimas Android/iOS em ADR antes do primeiro release.

---

## 18. Ordem de implementação (baseline)

1. Ambiente e flavor/configuração
2. API client
3. Auth/session
4. DTOs e mappers
5. Local database
6. Repository
7. Sync engine
8. Delivery feature
9. Location/tracking
10. Notifications
11. UI
12. Testes

Regra: o app deve renderizar o estado local sem depender da internet e
sincronizar alterações conforme `POST /sync/batch`.

---

## 19. Notas práticas e estado atual (2026-08-16)

- Diretório de regras real: `docs/flutter/.cursor/rules/` (19 arquivos `.mdc`).
  O prompt original citava `docs/delivery-platform-docs/flutter/...` — caminho não existe.
- Especificações técnicas: `docs/flutter/docs/` (14 documentos + contracts).
- `./flutter/` estava vazio — projeto ainda não criado; este arquivo é o primeiro.
- **SDK Flutter não instalado** no ambiente (`which flutter` vazio).
- Backend Laravel já implementado (Stage 4): máquina de estados de delivery,
  `CreateDeliveryAction`, `DispatchService` — testes 12/12 passando.
- Contrato HTTP em `docs/docs/openapi/openapi.yaml` (672 linhas, base `/api/v1`).
- Sync em `docs/docs/api/38-sync-api.md`; erros/idempotência em
  `docs/docs/api/42-api-errors-idempotency-concurrency.md`.



