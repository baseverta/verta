# 06 — CRM

> **Camada**, não ferramenta. Hoje o CRM da Verta é o **Pipedrive**, e os exemplos
> concretos abaixo são dele. Cliente pode usar outro (RD Station, HubSpot, Ploomes)
> ou nenhum. O que não muda são as regras da camada — a seção final diz o que
> conferir ao trocar de ferramenta.

## O papel da camada

Espelho completo do banco, e a **interface de trabalho de gente**. Regra prática:
ninguém deveria precisar abrir o banco para saber algo sobre um cliente. Se um dado
é útil para uma pessoa, ele está no CRM também.

O CRM **não** é consultado no caminho quente (conversa de WhatsApp) — latência e
limite de taxa não permitem. É consultado como **fonte secundária** de
identificação, quando o banco não sabe responder (ex.: de qual empresa é este
e-mail).

Quem manda é o banco. Ver protocolo 03.

## As quatro entidades, e o erro de confundi-las

Todo CRM tem alguma versão disto. Os nomes mudam; os papéis, não.

| Papel | Pipedrive | Para que serve |
|---|---|---|
| Empresa | Organização | amarra várias pessoas ao mesmo cliente |
| Pessoa | Pessoa | um contato individual |
| Negócio | Deal | a oportunidade, com etapa e valor |
| Compromisso | Atividade | algo com data, que aparece na agenda |

**O erro que mais custa: criar Pessoa sem Empresa.** Sem a entidade Empresa, cada
contato novo vira um cliente novo e o histórico se estilhaça. Quando aparece um
segundo contato numa reunião, ele precisa entrar como Pessoa **dentro da Empresa
existente** — é o que mantém "a mesma empresa" sendo a mesma coisa.

A auditoria diária reclama de empresa conhecida sem Empresa no CRM por causa disso.

## Campo customizado costuma ter chave opaca

No Pipedrive um campo customizado não é `cnpj`, é
`e39a55b0567dc44f48c2d5c6d087c433ad9f9d64`. Outros CRMs usam ID numérico ou
`slug` — o problema é o mesmo: **o identificador não é legível**.

Duas regras que valem em qualquer um:

- **Nunca escreva a chave direto no workflow.** Vai para a config (Data Table
  `pipedrive_config`), com nome legível (`ORG_FIELD_CNPJ`), e o workflow lê de lá.
  Chave espalhada por vários workflows é chave que você não acha quando muda.
- **Confira como o webhook entrega o campo.** No Pipedrive v2, customizado vem
  aninhado sob `data.custom_fields['<chave>'].id`, não no primeiro nível como os
  nativos. Quase todo CRM tem uma diferença dessas entre a API e o webhook.

## Etapa e pipeline

No Pipedrive o `stage_id` é **global**, não por pipeline: a etapa 8 é
"Diagnóstico Agendado" e ponto. Isso simplifica — para saber onde um negócio está,
o `stage_id` basta.

**Não presuma isso em outro CRM.** Vários numeram etapa por funil, e aí
`stage_id = 3` é ambíguo sem saber o funil. Ao trocar de ferramenta, esta é a
primeira coisa a testar.

Temos dois pipelines: **Vendas** e **Ex-clientes**. Ao cruzar dados, olhe **os
dois** — quem cancelou saiu do funil de vendas e continua sendo alguém de quem
temos histórico.

## Etiquetas

Usamos três eixos: fit (qualificado / incerto / sem fit), rota (start / modular) e
origem (WhatsApp / formulário / agenda).

Etiqueta serve para uma pessoa filtrar de olho. **Não use etiqueta como estado de
máquina** — para isso existe etapa e campo. Etiqueta costuma ser multivalorada e
editável por qualquer um; é o pior lugar possível para guardar estado que a
automação lê.

## Compromisso e anotação

**Compromisso** tem data e precisa aparecer na agenda de alguém: reunião de kickoff,
diagnóstico agendado.

**Anotação** é contexto para ler antes de falar com o cliente: o que ele respondeu
no formulário, o que foi tratado na última reunião. É onde o que a automação
capturou vira algo útil para um humano.

A regra que separa: **se tem hora marcada, é compromisso; se é para ler antes, é
anotação.**

## Erros que já cometemos

**Deixar a integração nativa do CRM com o Drive ligada.** O Pipedrive cria uma pasta
própria, com estrutura dele, paralela à nossa. Fica desligada — quem manda na
estrutura de pastas somos nós (protocolo 05). Vale para qualquer CRM que ofereça
integração de arquivos.

**Escrever chave de campo direto no node.** Espalha o mesmo identificador opaco por
vários workflows e, quando muda, você não acha todos.

**Criar registro na mão antes de marcar o negócio como ganho.** A automação cria de
novo e você fica com duplicado. Deixe o evento de "ganho" ser o gatilho
(protocolo 01).

## Ao trocar de CRM (ou instalar num cliente que já tem o dele)

Checklist do que **precisa ser respondido antes** de escrever qualquer automação:

- [ ] Existe entidade de **Empresa** separada de Pessoa? Se não existir, como
      agrupamos vários contatos do mesmo cliente?
- [ ] Como o CRM identifica **campo customizado** — e a API e o webhook usam o
      mesmo formato?
- [ ] `stage_id` é global ou por funil?
- [ ] O CRM **emite webhook** de mudança de negócio? Se não, vira consulta agendada
      e o setup deixa de ser em tempo real — isso muda o desenho, não só a config.
- [ ] Qual o limite de taxa da API?
- [ ] Dá para gravar **anotação** e **compromisso** por API?

As respostas viram chaves novas na config, nunca código espalhado. Se o CRM do
cliente não emite webhook, isso é uma **decisão de escopo** e precisa ser dita na
proposta — não é detalhe de implementação.
