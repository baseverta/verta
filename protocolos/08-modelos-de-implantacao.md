# 08 — Modelos de implantação e infraestrutura

Existem **dois modelos**, e a escolha muda o que precisa ser provisionado. O que não
muda é a stack de software: os dois rodam exatamente os mesmos containers.

| | **VPS dedicada** (isolamento físico) | **VPS compartilhada da Verta** (isolamento lógico) |
|---|---|---|
| Servidor | um por cliente | vários clientes na mesma máquina |
| Domínio | do cliente (`n8n.cliente.com.br`) | subdomínio nosso por cliente |
| Traefik | um por VPS, dono das portas 80/443 | **um só**, global, roteando por `Host` |
| Custo de VPS | do cliente | rateado |
| Portabilidade | entrega a VPS inteira | export de fluxos e dados |
| Indicado para | Rota 2 / cliente maior, exigência de isolamento | Rota 1 / Verta Start |

**Regra de ouro, vale nos dois:** o banco de negócio (Supabase) é **sempre** isolado
por *Project*, um por cliente. Nunca por schema dentro do mesmo projeto. Isolamento
de dados de cliente não se negocia por conveniência de infra.

O documento de origem com o passo a passo narrativo é
`.verta/Verta - Implantação de Infraestrutura Baseverta.md`. Este protocolo é a
versão operacional: o que de fato roda hoje, mais o que já deu errado.

## A stack base — todo cliente tem isto

Espelho do `docker-compose.yml` na raiz do repositório, que por sua vez espelha o
que roda em produção (`/root/verta/docker-compose.yml`).

| Container | Papel | Rede |
|---|---|---|
| `traefik` | proxy reverso, TLS automático (Let's Encrypt), redirect 80→443 | `proxy` |
| `postgres` | banco **do n8n** (execuções, credenciais) — não é o banco de negócio | `internal` |
| `n8n` | motor de automação | `proxy` + `internal` |
| `embeddings` | servidor de embeddings self-hosted | `internal` |
| `redis` | cache | `internal` |
| `evolution` | ponte com o WhatsApp | `proxy` + `internal` |

Duas redes, de propósito: `internal` é `internal: true`, ou seja, **sem saída para a
internet**. Só quem precisa ser alcançado de fora entra na rede `proxy`. Banco e
embeddings não têm por que ser alcançáveis.

Não confunda os dois bancos: o `postgres` do compose é do n8n. O banco de negócio é
o Supabase, externo, um Project por cliente.

## Sequência de provisionamento (VPS dedicada)

1. **VPS** — plano KVM, Ubuntu 22.04 ou 24.04 LTS, sem interface gráfica.
2. **DNS** — registro `A` do subdomínio apontando para o IP da VPS.
   **Desligue o proxy do Cloudflare (nuvem cinza) durante a emissão do SSL.** Com o
   proxy ligado, o desafio HTTP do Let's Encrypt não chega no Traefik e o
   certificado não sai — sintoma: o site responde, mas com certificado inválido.
3. **Acesso** — SSH como root, `apt update && apt upgrade -y`, instalar Docker.
4. **Repositório** — clonar em `/root/verta`, copiar `.env.example` para `.env`.
5. **Preencher o `.env`** — domínio, e-mail do SSL, credenciais do Postgres,
   `N8N_ENCRYPTION_KEY` (gere com `openssl rand -hex 32`), chave da Evolution.
6. **Subir** — `docker compose up -d`, conferir `docker compose ps` e os logs do
   Traefik até o certificado sair.
7. **n8n** — criar o usuário owner, gerar a API key, conectar as credenciais.
8. **Supabase** — criar o Project **do cliente**, aplicar o schema.
9. **Conferir a base** — protocolo 09, seção do módulo base.

### Variáveis que não são óbvias

`NODE_FUNCTION_ALLOW_BUILTIN=crypto` — sem isso, todo Code node que valida
assinatura de webhook quebra com `crypto is not defined` (protocolo 04). Já
esquecemos e só descobrimos quando a validação foi ligada.

`WEBHOOK_URL` e `N8N_EDITOR_BASE_URL` precisam bater com o domínio real. Se
estiverem errados, o n8n gera URLs de webhook que você registra nas ferramentas e
que nunca vão receber nada.

## O que muda na VPS compartilhada

O `docker-compose.yml` deste repositório é escrito para o modelo **dedicado**: o
Traefik dele toma as portas 80 e 443. Dois desses na mesma máquina não sobem —
o segundo falha com conflito de porta.

No modelo compartilhado:

- **Um único Traefik global**, fora dos composes de cliente, numa rede externa
  compartilhada. Cada cliente entra nela.
- **Remova o serviço `traefik` do compose do cliente.** Mantenha as `labels` — é
  por elas que o Traefik global descobre e roteia por `Host`.
- **Nomes de container e volume precisam ser únicos por cliente.** Os nomes fixos
  atuais (`container_name: n8n`, `name: baseverta_postgres_data`) colidem. Prefixe
  com o cliente.
- **Porta publicada colide.** A Evolution publica `127.0.0.1:8082`. Segundo cliente
  na mesma máquina precisa de outra porta — ou de nenhuma, falando só pela rede
  interna.

Nada disso é difícil, mas **é a fonte previsível de erro** ao instalar o segundo
cliente numa máquina que já tem um. Trate como checklist, não como memória.

## Segurança

**Evolution só escuta em `127.0.0.1`.** A porta 8082 está publicada como
`127.0.0.1:8082:8080`, ou seja, não é alcançável de fora da máquina. Se algum dia
alguém trocar por `8082:8080`, a API do WhatsApp fica exposta na internet com uma
chave só. Não faça.

**Acesso SSH por chave, e a chave privada precisa existir.** Já ficamos sem acesso
a uma VPS porque a chave autorizada era de uma sessão antiga cuja metade privada não
existia mais — e a única saída foi o console web do provedor. Ao autorizar uma
chave, **teste o login numa segunda sessão antes de fechar a que funciona**.

**Segredo nunca entra no Git.** O `.env` é gitignorado, o `.env.example` é o que
fica versionado. Ver protocolo 07 sobre onde cada coisa mora.

## Erros que já cometemos

**Traefik v3.1 não sobe nesta VPS.** Ficamos presos até fixar a **v2.11** e definir
`DOCKER_API_VERSION: "1.41"`. É por isso que a imagem está pinada. Não atualize
Traefik sem testar em ambiente separado — e, se atualizar, atualize o comentário no
compose junto.

**Imagem sem versão fixa.** O n8n está em `:latest`. É conveniente e é risco: um
`docker compose pull` pode trazer versão que quebra. Ao mexer numa VPS de cliente,
**não rode `pull` sem intenção** — subir um container não deveria ser o momento de
descobrir uma atualização de major.

**Editar direto no servidor e esquecer de trazer para o repositório.** O compose
daqui declara que espelha produção — se alguém editar só lá, essa frase vira mentira
e a próxima instalação sai errada. Mudou no servidor, commite aqui.

## Portabilidade

Está no contrato e é diretriz obrigatória: ao fim do contrato a Verta transfere a
conta e os acessos, ou entrega export completo de fluxos, prompts, configurações e
credenciais.

Isso tem consequência prática de engenharia: **nada pode ser mágica não
documentada.** Se um fluxo só funciona por causa de um ajuste manual feito no
servidor e não registrado, a portabilidade prometida não existe de verdade.
