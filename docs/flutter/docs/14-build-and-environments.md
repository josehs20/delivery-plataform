# Flutter — 14. Build, Ambientes e Configuração

## Ambientes

Separar pelo menos:

- local/dev;
- homologação/staging;
- produção.

URLs, chaves públicas e flags de ambiente devem vir de configuração controlada; segredos não devem ser commitados.

## Flavors

Usar flavors/configuração de build quando útil para manter ambientes separados.

## Release

Builds de produção devem ser reprodutíveis. Registrar versão do app e schema da sincronização.

## Compatibilidade

Definir versões mínimas de Android/iOS em ADR antes do primeiro release, considerando APIs de localização, notificações e mapas.
