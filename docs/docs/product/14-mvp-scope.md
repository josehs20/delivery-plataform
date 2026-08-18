# 14 — Escopo do MVP

## 1. Objetivo do MVP

Validar o fluxo central de contratação e execução de entregas entre comércio e motoboy.

## 2. Incluído

### Comércio

- cadastro/login;
- estabelecimento;
- origem;
- criação de entrega;
- múltiplos itens;
- destino com coordenadas;
- destinatário;
- preço calculado ou manual;
- publicação;
- recebimento de ofertas;
- contrapropostas;
- aceite;
- acompanhamento;
- cancelamento;
- histórico;
- confirmação de devolução.

### Motoboy

- cadastro;
- documentos;
- veículo;
- capacidade/restrições;
- disponibilidade;
- descoberta por proximidade;
- aceite;
- recusa;
- contraproposta;
- múltiplas entregas;
- navegação/rota por provedor externo;
- GPS;
- coleta;
- transporte;
- prova de entrega;
- falha;
- devolução;
- histórico;
- ganhos/valores.

### Backend

- autenticação;
- autorização;
- domínio de entrega;
- negociação;
- pagamentos;
- comissão;
- estorno;
- eventos;
- filas;
- notificações;
- tracking;
- auditoria;
- sincronização.

### Admin

- usuários;
- motoboys;
- documentos;
- entregas;
- pagamentos;
- cancelamentos;
- falhas;
- devoluções;
- configurações;
- auditoria.

## 3. Fora do MVP

- consumidor final;
- catálogo/marketplace de produtos;
- chat completo;
- avaliações;
- cupons;
- fidelidade;
- agendamento tradicional de uma janela fixa, salvo o `pickup_deadline` já previsto;
- múltiplos destinos;
- otimização avançada de frota;
- IA;
- API pública;
- ERP;
- publicidade;
- franquias;
- assinatura avançada.

## 4. Critério de sucesso

O MVP precisa provar que um comércio consegue contratar uma corrida, que um motoboy próximo consegue assumir/negociar, executar a coleta e entrega, e que a plataforma consegue registrar evidências e finalizar o ciclo financeiro.

## 5. Estratégia de evolução

Depois da validação do fluxo principal, priorizar funcionalidades com impacto em:

1. eficiência de despacho;
2. redução de cancelamentos;
3. confiabilidade do offline;
4. monetização;
5. retenção de comércio e motoboy;
6. escalabilidade regional.
