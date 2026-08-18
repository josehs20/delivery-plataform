# Flutter — 04. Estado e Reatividade

## Princípios

Escolher uma única estratégia de gerenciamento de estado para o projeto e documentá-la antes da implementação massiva. Riverpod/BLoC podem ser opções; não misturar padrões arbitrariamente.

## Estado remoto

Estados vindos do backend devem ser tratados como dados de domínio, não como simples booleanos de tela.

## Estado offline

Representar explicitamente:

- local;
- sincronizando;
- sincronizado;
- falha de sincronização;
- conflito.

## Formulários

Validação de UX no Flutter é complementar. A API continua sendo autoridade final.
