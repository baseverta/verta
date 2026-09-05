# 07 — Nomenclatura e organização

Nome não é estética. Em vários pontos do sistema o nome **é o contrato**: mudar
quebra coisa. Este protocolo diz onde isso acontece e como padronizar o resto.

## Onde o nome é contrato (mudar quebra)

**Nome de node no n8n.** Code nodes referenciam outros nodes por nome
(`$('Ler Config Pipedrive')`). Renomear um node quebra todo mundo que o referencia,
e o erro só aparece na execução seguinte.

Antes de renomear qualquer node, procure o nome antigo em **todos** os workflows —
referência cruzada entre workflows existe. Depois de renomear, releia e confirme que
nenhuma referência ao nome antigo sobrou.

**Chave da Data Table.** Trocar `ORG_FIELD_CNPJ` de nome quebra todo `cfg.ORG_FIELD_CNPJ`.

**Path de webhook.** É a URL registrada na ferramenta de origem. Mudar exige
atualizar o registro externo no mesmo movimento.

## Convenções

**Workflow:** `<O que faz> - <Origem ou periodicidade>`
`Conversa WhatsApp - Verta`, `Sincronizacao Deal - Pipedrive -> Supabase`,
`Auditoria de Integridade - Diaria`. Lendo o nome, você sabe o que dispara.

**Node:** verbo no infinitivo + objeto. `Buscar Lead p Onboarding`,
`Montar SQL Kickoff`, `Validar Assinatura Typeform`. Node de decisão termina com
`?`: `Lead Localizado?`, `Assinatura OK?`.

Quando o mesmo passo existe em dois ramos do mesmo workflow, sufixo entre parênteses
diz qual: `Criar Pasta Cliente Drive (Novo TF)` e `(Existente TF)`. Nome duplicado
não é permitido, e sufixo é melhor que numerar.

**Path de webhook:** `verta-<ferramenta>-<evento>`, minúsculo com hífen.
`verta-typeform-kickoff`, `verta-pipedrive-deal-updated`.

**Chave de config:** `MAIÚSCULA_COM_UNDERLINE`, prefixo por domínio —
`FIELD_*` (campo de Deal), `ORG_FIELD_*` (campo de Organização),
`PERSON_FIELD_*`, `STAGE_*`, `LABEL_*`, `PIPELINE_*`, `DRIVE_FOLDER_*`,
`TYPEFORM_URL_*`, `EMAIL_*`.

**Coluna no Supabase:** `snake_case`, português, sem abreviar. ID externo carrega a
origem no nome: `pipedrive_org_id`, `pipedrive_deal_id`.

**Pasta de cliente no Drive:** nome da Organização no Pipedrive, igual. Subpastas
com nome fixo: `Transcrições`, `Propostas`, `Contratos`, `Arquivos Recebidos`.

**Etapas do ciclo de vida no Drive** levam prefixo numérico (`01 - Lead`,
`02 - Cliente`, `03 - Ex-cliente`) só para ordenar na tela. Nenhum código depende
desses nomes — ver protocolo 05.

## Organização de workflows em pastas

Uma pasta por **ferramenta que dispara**: `Pipedrive`, `WhatsApp`, `Typeform`,
`Fathom`. Mais uma pasta `Rotinas` para tudo agendado.

O critério é o **gatilho**, não o assunto. `Sincronizacao Deal` mexe em Drive,
Supabase, e-mail e Typeform, mas mora em `Pipedrive` porque é o Pipedrive que a
dispara. Assim, quando algo não aconteceu, você sabe onde procurar antes de abrir:
se era reação a evento externo, está na pasta da ferramenta; se era para rodar no
horário, está em `Rotinas`.

Workflow novo nunca fica solto na raiz. A API pública do n8n não move workflow entre
pastas — é arrastar na interface.

## Onde cada tipo de conhecimento mora

| Tipo | Lugar | Por quê |
|---|---|---|
| Decisão de arquitetura | `ARQUITETURA-DADOS.md` | versionado, com o porquê |
| Como fazer / erro conhecido | `protocolos/` | este diretório |
| Credencial, ID, chave | `.env.n8n` | fora do Git, tem segredo |
| Config que o workflow lê | Data Table `pipedrive_config` | muda sem editar workflow |
| Estado de cliente | Supabase, espelhado no Pipedrive | ver protocolo 03 |

**Cuidado:** o `.env.n8n` é gitignorado. Conhecimento que só existe lá **morre com o
arquivo**. Ele guarda segredo e referência — raciocínio e decisão vão para o
`ARQUITETURA-DADOS.md` ou para cá.

## Escrita destes documentos

Ao registrar um erro, escreva três coisas:

1. **Sintoma** — o que apareceu na tela, com a mensagem literal quando houver.
   É por ela que alguém vai buscar daqui a seis meses.
2. **Causa real** — quase nunca é a primeira hipótese. Escreva a verdadeira.
3. **Regra prática** — o que fazer diferente. Sem isso o registro vira anedota.

Erro que não virou protocolo vai voltar.
