# 05 — Google Drive

## A regra que protege de reorganização de pastas

> Referencie pasta **sempre por ID**, nunca por nome ou caminho.

No Google Drive o ID de uma pasta é imutável: sobrevive a **mover** e a **renomear**.
O caminho não sobrevive a nada — basta alguém arrastar uma pasta e todo código que
depende de "está dentro de Operacional" quebra.

Isso já foi validado na prática. As pastas do ciclo de vida foram movidas para
dentro de uma pasta `Operacional` criada depois, e **nenhum workflow precisou de
ajuste** — porque nenhum deles sabe onde as pastas estão, só quem elas são.

### Como fica na prática

Os IDs vivem na Data Table `pipedrive_config`:

| Chave | Aponta para |
|---|---|
| `DRIVE_FOLDER_LEAD` | `01 - Lead` |
| `DRIVE_FOLDER_CLIENTE` | `02 - Cliente` |
| `DRIVE_FOLDER_EXCLIENTE` | `03 - Ex-cliente` |
| `DRIVE_FOLDER_NAO_IDENTIFICADAS` | `Transcrições não identificadas` |

E o ID da pasta de cada cliente fica em `leads.drive_folders` (jsonb), com `root` e
as subpastas.

**Você pode reorganizar o Drive à vontade.** Mover, renomear, aninhar em pastas
novas — nada quebra. As duas únicas coisas que quebram:

1. **Apagar** uma dessas pastas (o ID morre junto)
2. **Criar uma pasta nova no lugar** de uma existente — mesmo nome, ID diferente.
   Se precisar substituir uma pasta, atualize a chave na `pipedrive_config`.

Se algum dia mudar um desses quatro IDs, é uma linha na Data Table — nenhum código.

### O que nunca fazer

Nunca resolva pasta por busca de nome (`name = 'Clientes'`). Duas pastas com o mesmo
nome, ou um renomear inocente, e o arquivo do cliente vai para o lugar errado — o
tipo de erro que ninguém percebe por semanas. Hoje **zero** workflows fazem isso, e
é para continuar assim.

## Estrutura

```
Operacional/
├── Lead/Cliente/Ex-cliente/
│   ├── 01 - Lead/          ← pasta nasce aqui
│   ├── 02 - Cliente/       ← move ao ganhar o negócio
│   └── 03 - Ex-cliente/    ← move ao entrar no pipeline de churn
├── Transcrições não identificadas/
└── Protocolos/
```

A pasta do cliente **move** entre as três etapas, não é copiada. Assim o histórico
(contratos, transcrições, arquivos recebidos) anda junto e existe **uma** pasta por
cliente na vida inteira dele.

Dentro da pasta do cliente: `Transcrições`, `Propostas`, `Contratos`,
`Arquivos Recebidos` e o `RESUMO.md`.

A pasta é nomeada com o nome da **Organização** no Pipedrive, para os dois sistemas
serem legíveis lado a lado.

## Mover pasta: o node não funciona

A operação `move` do node Google Drive do n8n **retorna sucesso e não move nada**.
Descobrimos com pasta que "mudou de etapa" e continuou no lugar.

Use HTTP Request cru:

```
PATCH https://www.googleapis.com/drive/v3/files/{id}
      ?addParents={destino}&removeParents={origem}&supportsAllDrives=true
```

com `predefinedCredentialType: googleDriveOAuth2Api`.

`removeParents` exige saber o pai **atual** — por isso existe um node de busca do pai
antes de cada movimentação. Sem isso a pasta fica com dois pais e aparece nos dois
lugares.

`supportsAllDrives=true` é obrigatório em Drive compartilhado. Sem ele, erro obscuro
de permissão.

## Subir arquivo

O node de upload exige **binário**. Texto vindo do `$json` não serve. Antes dele:
`n8n-nodes-base.convertToFile` com `operation: toText`, `sourceProperty` apontando
para o campo, e `options.fileName` / `mimeType`. No upload, `inputDataFieldName: 'data'`.

Sintoma de esquecer: *"Make sure that the previous node outputs a binary file"*.

## Credencial

A credencial precisa ser da conta **da Verta**, não de uma conta pessoal. Já
conectamos na conta errada uma vez e os arquivos foram para um Drive que o time não
enxergava. Ao configurar, confira em qual conta o consentimento foi dado.

O app OAuth deve ser **interno** no Google Cloud — externo exige processo de
verificação que não faz sentido para uso próprio.

## Erros que já cometemos

**Pipedrive criando a própria pasta.** A integração nativa do Pipedrive com Drive
cria uma pasta paralela, com estrutura dele, fora da nossa. Fica desligada: quem
manda na estrutura de pastas somos nós.

**Node de Drive derrubando execução inteira.** Cliente sem pasta fez o node de mover
receber `undefined` e matou a execução — junto com o disparo de formulário que vinha
depois. Hoje todo node de Drive tem guarda de existência antes e
`onError: continueRegularOutput`.

**Confiar no retorno de sucesso do `move`.** Ver acima. Regra maior: quando uma
operação diz que funcionou, **confira o efeito**, não a resposta.
