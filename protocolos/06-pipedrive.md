# 06 — Pipedrive

## O papel dele

Espelho completo do Supabase, e a interface de trabalho do time. Regra prática:
**ninguém deveria precisar abrir o banco para saber algo sobre um cliente.** Se um
dado é útil para uma pessoa, ele está aqui também.

Ele não é consultado no caminho quente (conversa de WhatsApp) — latência e limite de
taxa não permitem. É consultado como **fonte secundária** de identificação, quando o
Supabase não sabe responder (ex.: descobrir de qual empresa é um e-mail).

## Campos customizados são chaves hasheadas

Um campo customizado não é `cnpj`, é `e39a55b0567dc44f48c2d5c6d087c433ad9f9d64`.
Isso significa:

- Nunca escreva a chave direto no workflow. Vai para a `pipedrive_config`, com nome
  legível (`ORG_FIELD_CNPJ`), e o workflow lê de lá.
- Webhook v2 aninha customizado sob `data.custom_fields['<chave>'].id` — não no
  primeiro nível como os campos nativos.

## `stage_id` é global, não por pipeline

As etapas são numeradas de forma única em toda a conta. A etapa 8 é
"Diagnóstico Agendado" e ponto — não existe "etapa 8 do pipeline de vendas" e
"etapa 8 do pipeline de ex-clientes". Isso simplifica: para saber onde um negócio
está, o `stage_id` basta.

Temos dois pipelines: **Vendas** (2) e **Ex-clientes** (3). Ao cruzar dados, olhe
**os dois** — um cliente que cancelou saiu do pipeline de vendas e continua sendo
alguém de quem temos histórico.

## Etiquetas

`label` é campo nativo do tipo `set` — aceita múltiplos valores. Usamos três eixos:
fit (qualificado / incerto / sem fit), rota (start / modular) e origem (WhatsApp /
Typeform / Calendly). Os IDs estão na `pipedrive_config` como `LABEL_*`.

Etiqueta serve para o time filtrar de olho. Não use etiqueta como estado de máquina
— para isso existe etapa e campo.

## Organização, não só Pessoa

Todo lead com empresa conhecida precisa de **Organização**, não apenas de Pessoa.
A Organização é o que amarra várias pessoas ao mesmo cliente — quando aparece um
segundo contato numa reunião (o caso Wellington/Manekin), ele entra como Pessoa
**dentro da Organização existente**, e continua sendo o mesmo cliente.

Sem Organização, cada contato novo vira um cliente novo e o histórico se estilhaça.
A auditoria diária reclama de empresa conhecida sem Organização por causa disso.

## Atividades e notas

**Atividade** é compromisso com data: reunião de kickoff, diagnóstico agendado.
Serve para aparecer na agenda de alguém.

**Nota** é contexto que a pessoa lê antes de falar com o cliente: resumo do que ele
respondeu no kickoff, o que foi tratado numa reunião. É onde a informação que a
automação capturou vira algo útil para um humano.

A regra que separa: se tem hora marcada, é atividade. Se é para ler antes, é nota.

## Erros que já cometemos

**Deixar a integração nativa do Pipedrive com o Drive ligada.** Ela cria pasta
própria, com estrutura dela, paralela à nossa. Fica desligada.

**Escrever chave de campo direto no node.** Espalha o mesmo hash por vários
workflows e, quando muda, você não acha todos. Tudo na Data Table.

**Criar registro na mão antes de marcar o negócio como ganho.** A automação cria de
novo e você fica com duplicado. Deixe o `won` ser o gatilho.
