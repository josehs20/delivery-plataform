# Laravel — 13. Storage e Mídia

## Uso

Fotos de prova de entrega, documentos e evidências devem ser armazenadas em storage adequado.

## Regras

- Nunca colocar arquivos binários grandes no MySQL.
- Metadados ficam no banco.
- URLs públicas permanentes devem ser evitadas para conteúdo sensível.
- Usar URLs temporárias quando aplicável.
- Validar MIME, extensão, tamanho e conteúdo quando necessário.
- Gerar nomes internos não previsíveis.

## Imagens

Preservar evidência original quando houver requisito de auditoria; derivar versões comprimidas para visualização se necessário.

## Documentos

Documentos de motoboy devem possuir acesso restrito ao próprio usuário e administradores autorizados.
