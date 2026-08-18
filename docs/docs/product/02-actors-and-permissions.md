# 02 — Atores e Permissões

## 1. Atores

### 1.1 Comércio

Representa o estabelecimento que solicita serviços.

### 1.2 Motoboy

Representa o profissional que executa o transporte.

### 1.3 Administrador

Representa a operação da plataforma.

## 2. Matriz de permissões

| Ação | Comércio | Motoboy | Admin |
|---|---:|---:|---:|
| Criar entrega | Sim | Não | Sim |
| Editar entrega aberta | Sim* | Não | Sim |
| Publicar entrega | Sim | Não | Sim |
| Ver ofertas | Sim | Próprias/elegíveis | Sim |
| Aceitar oferta como motoboy | Não | Sim | Sim |
| Fazer contraproposta | Não | Sim | Não* |
| Aceitar contraproposta | Sim | Não | Sim* |
| Aceitar múltiplas entregas | Não | Sim | Sim* |
| Confirmar coleta | Não | Sim | Sim* |
| Atualizar localização | Não | Sim | Não |
| Registrar prova de entrega | Não | Sim | Sim* |
| Registrar falha | Não | Sim | Sim |
| Solicitar cancelamento | Sim | Sim | Sim |
| Aprovar cancelamento excepcional | Não | Não | Sim |
| Confirmar devolução | Sim | Não | Sim* |
| Executar devolução | Não | Sim | Sim* |
| Ver pagamentos próprios | Sim | Sim | Sim |
| Ver pagamentos de terceiros | Não | Não | Sim |
| Bloquear usuário | Não | Não | Sim |
| Aprovar motoboy | Não | Não | Sim |
| Configurar regras | Não | Não | Sim |
| Ver auditoria | Não | Não | Sim |

`*` significa intervenção operacional/admin ou ação limitada a cenários definidos por regra.

## 3. Princípio de autorização

Toda operação deve ser autorizada no backend. O estado exibido no aplicativo não concede permissão por si só.

## 4. Comércio e estabelecimento

A arquitetura deve permitir futuramente que um usuário comercial administre mais de um estabelecimento e que um estabelecimento possua mais de um usuário, mesmo que o MVP comece com um modelo simplificado.

## 5. Motoboy

O motoboy precisa estar aprovado e em situação operacional válida para receber novas ofertas. Documentos vencidos ou status bloqueado podem impedir novas atribuições conforme regras administrativas.

## 6. Administrador

Os perfis administrativos devem permanecer preparados para subdivisão futura em funções como suporte, operação e financeiro. A existência desses perfis adicionais não é requisito obrigatório do MVP.
