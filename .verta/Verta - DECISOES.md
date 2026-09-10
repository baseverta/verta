# DECISOES.md

### Verta — Diário de Bordo Técnico e Estratégico

**Status:** Oficial e Ativo
**Versão:** 3.2
**Objetivo:** Registrar o histórico de escolhas arquiteturais e comerciais da Verta, para que ninguém repita erro do passado nem desfaça restrição sem entender o porquê.

**Como usar:** toda decisão registra o problema, a decisão e a data. Decisão revertida não é apagada — é marcada como superada, com a nova entrada abaixo. Histórico revogado ainda ensina.

---

## 1. Infraestrutura e DevOps

**Rejeição do Traefik v3.x e fixação no v2.11**
- *Problema:* nos testes do Cliente Zero, o Traefik 3.0 falhou ao negociar a API do Docker em instâncias de VPS específicas, gerando loop (`Loop client version 1.24 is too old`) e retornando `404 Not Found` ou `504 Gateway Timeout`.
- *Decisão:* imagem fixada em `traefik:v2.11`. Atualização major banida até compatibilidade garantida.

**Substituição de API externa por embeddings self-hosted**
- *Problema:* depender de API terceira (Voyage AI) para vetorização criava rate limit severo, travando o atendimento em pico.
- *Decisão:* modelo BGE-M3 em container local, conectado exclusivamente à rede cega `internal`. Zera custo por token de embedding e elimina limite de requisição.

**Modelo único de isolamento: multi-tenant lógico com critério de saída** *(nova)*
- *Problema:* a documentação anterior recomendava isolamento físico (uma VPS por cliente) em um arquivo e afirmava que uma VPS absorve 10 clientes em outro. Custo 10x diferente, decisão tomada caso a caso, sem critério.
- *Decisão:* padrão é multi-tenant lógico com container e volume prefixados por cliente. VPS dedicada passa a ser obrigatória por gatilho objetivo — mais de 10 clientes na máquina, cliente acima de 3.000 conversas/mês, exigência contratual, ou CPU acima de 70% por 7 dias. Supabase permanece isolado por *Project* nos dois modelos, sem exceção.

**Política de backup e custódia de chave** *(nova)*
- *Problema:* a documentação tratava volume persistente como se fosse backup. Volume protege contra restart de container, não contra VPS morta, corrupção de disco ou exclusão acidental. Pior: sem a `N8N_ENCRYPTION_KEY` guardada fora do servidor, um backup restaurado devolve todas as credenciais ilegíveis — e a promessa comercial de portabilidade anti-lock-in fica impossível de cumprir.
- *Decisão:* rotina obrigatória de dump diário do Postgres e do Supabase, export diário dos workflows para Git privado, destino externo em bucket (Cloudflare R2 ou Backblaze B2), retenção 7/4/3, e teste de restauração mensal em VPS descartável. A `N8N_ENCRYPTION_KEY` de cada cliente vive em cofre de senhas com cópia offline. **Go-live sem backup validado está proibido.**

**Proibição de segredo hardcoded em Code Node** *(nova)*
- *Problema:* o sandbox do Code Node não lê credenciais nativas do n8n, o que levava a fixar o segredo de validação de webhook direto no código. Esse arquivo vai para o repositório do cliente, e um push distraído expõe a credencial.
- *Decisão:* o segredo é injetado por variável de ambiente e lido via `$env`, com `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` no container. `.gitignore` obrigatório cobrindo `.env`, `*.key`, `*.pem` e `acme.json`. Hardcode só como exceção temporária, registrada aqui e com prazo de substituição.

**Imagem do n8n fixada em 2.37.7** *(09/09/2026)*
- *Problema:* o `docker-compose.yml` em produção usava `docker.n8n.io/n8nio/n8n:latest`, contrariando a regra de `ARQUITETURA.md` seção 3. A violação passou despercebida por rodar sem restart: qualquer `docker compose up -d` — inclusive um recreate de rotina para adicionar variável de ambiente — puxaria a versão mais recente e poderia derrubar a produção sem aviso.
- *Decisão:* imagem fixada em `2.37.7`, a versão que já estava rodando. Atualização passa a exigir janela agendada e troca explícita da tag. Backup do compose e do `.env` gravado antes da alteração (`docker-compose.yml.bak-20260909-231631`).

**Conector MCP do Supabase apontado para outro cliente** *(09/09/2026)*
- *Problema:* durante a construção da cadência, a auditoria de conexões revelou que o conector MCP do Supabase estava autenticado numa conta cuja única organização era `Manekin.ai` — outro projeto —, enquanto o `.mcp.json` apontava para o `project_ref` da Verta. O conector tinha permissão de escrita e DDL sobre o banco de outro cliente dentro da sessão de trabalho da Verta. Nenhum dado da Manekin foi lido ou escrito, mas a barreira não existia. A regra de ouro do isolamento por Project protege os dados; não protege a camada de ferramenta.
- *Decisão:* reafirmada a regra de `ARQUITETURA.md` seção 7.1 — acesso ao Supabase por credencial em `.env` do projeto, **nunca por conector MCP global**. O acesso passou a ser feito pelo `.env.supabase` e pela connection string via pooler. O conector global deve ser desconectado.

---

## 2. Lógica e Motor (n8n)

**Discord com Threads para handoff**
- *Problema:* a Cloud API da Meta desconecta o número do aplicativo físico do WhatsApp. Assinar inbox comercial (Chatwoot, Zendesk) só para intervenção esporádica corroeria a margem e aumentaria a complexidade.
- *Decisão:* alerta via webhook para o Discord, com Threads isolando o histórico por lead. Comandos `/r` e `/bot_on` transformam o Discord em inbox gratuita e funcional.

**Discord como canal único de alerta** *(nova)*
- *Problema:* Telegram aparecia como destino de alerta em materiais comerciais enquanto Discord era o canal documentado na operação. Dois canais significam alerta perdido.
- *Decisão:* Discord é o canal único de transbordo e de alerta interno. Telegram descontinuado nessa função em todos os documentos e fluxos.

**Proibição da variável implícita `$json`**
- *Problema:* workflows quebravam silenciosamente quando um engenheiro inseria um nó intermediário, porque `$json` passa a referenciar o nó recém-criado e retorna nulo adiante.
- *Decisão:* todo mapeamento referencia a raiz absoluta do nó: `$('GET Supabase - Buscar Sessao').item.json.nome`.

**Contorno do Calendly com a API do Google Calendar**
- *Problema:* o webhook do Calendly retorna o campo da sala do Meet com status `processing` no momento do agendamento, impedindo o n8n de salvar o ID da reunião para monitoramento.
- *Decisão:* nó de Wait de 15 segundos, seguido de consulta direta à API do Google Calendar para extrair o `conferenceId` real.

**Calendly como padrão de agendamento** *(nova)*
- *Problema:* Cal.com constava no wireframe e na estratégia comercial, Calendly na base de incidentes, e um workflow chamado `CRON - CalCom -` na operação. Três referências para a mesma função.
- *Decisão:* Calendly é o padrão, por já ter o contorno técnico testado e a conta configurada. Cal.com sai de todos os documentos; o workflow passa a se chamar `CRON - Calendly - LembreteDiagnostico`.

**Webhook do Pipedrive sem assinatura: Basic Auth como exceção** *(09/09/2026)*
- *Problema:* `ARQUITETURA.md` seção 7.8 manda ativar `rawBody: true` e validar a assinatura de todo webhook. O Pipedrive **não assina webhook** — não há HMAC nem header de assinatura em nenhuma versão da API. A documentação oferece exclusivamente HTTP Basic Auth, com usuário e senha definidos no momento em que a subscrição é criada. A regra da seção 7.8 nasceu dos webhooks de Typeform e Cal.com, que assinam de fato, e não tem como ser cumprida aqui.
- *Decisão:* para webhooks do Pipedrive, a autenticação é Basic Auth validado em Code Node contra `$env.PIPEDRIVE_WEBHOOK_USER` e `$env.PIPEDRIVE_WEBHOOK_PASS`, com comparação de tempo constante. `rawBody` fica **desativado** — sem assinatura para ler, ele só transformaria o corpo em binário e complicaria o parse sem ganho de segurança. A regra da seção 7.8 permanece válida para todo provedor que assine; este é o único desvio autorizado.

**Filtro de transição de etapa exige checar o campo alterado** *(09/09/2026)*
- *Problema:* o webhook v2 do Pipedrive entrega `meta`, `data` e `previous`, e `previous` traz **somente os campos que mudaram**. A condição intuitiva — `data.stage_id == 16 && previous.stage_id != 16` — dispara indevidamente quando o negócio já estava na etapa 16 e alguém editou outro campo qualquer: `previous.stage_id` vem ausente, e `undefined != 16` avalia como verdadeiro. O resultado seria recriar a cadência inteira a cada edição.
- *Decisão:* todo filtro de transição de estado verifica antes se o campo consta na lista de alterados (`Object.keys(previous).includes('stage_id')`) e só então compara os valores. A guarda de idempotência continua obrigatória e independente — ela cobre a entrega duplicada do webhook, que é um problema distinto.

---

## 3. Comercial e Qualificação

**Substituição da regra de 3% pelo Índice de Recuperação (IR)**
- *Problema:* a regra de que a mensalidade não deveria passar de 3% do faturamento reprovava PME injustamente. Empresa faturando R$ 10.000 comprometeria 6,9% da receita com os R$ 690 e seria descartada, mesmo sangrando dinheiro por latência.
- *Decisão:* IR como critério, medindo receita vazando (leads perdidos × ticket médio × 20%) contra o custo mensal da Verta. Aprova com IR ≥ 2. O foco muda de tamanho da empresa para tamanho do gargalo.

**Remoção do piso de faturamento na Rota 1** *(nova)*
- *Problema:* a Rota 1 seguia declarando faixa de R$ 3.500 a R$ 15.000/mês, contradizendo o próprio IR que existia para eliminar régua de faturamento. Pior: para quem fatura R$ 3.500, o setup de R$ 2.800 é 80% de um mês de receita e a mensalidade come 20% do recorrente — negócio que não se sustenta e vira inadimplência em três meses.
- *Decisão:* piso de faturamento eliminado. Entrada definida por ticket médio ≥ R$ 200, volume ≥ 40 conversas/mês, autoridade confirmada e IR ≥ 2. A rota é escolhida pela complexidade do escopo, não pelo tamanho do cliente.

**Piso de volume passa de semanal para mensal** *(nova)*
- *Problema:* o piso de 30 conversas/semana (130/mês) reprovaria justamente o ICP escolhido. Clínica premium de alto ticket opera bem com 50 leads/mês e ainda assim perde muito dinheiro por latência.
- *Decisão:* piso de 40 conversas/mês. Volume alto importa quando o ticket é baixo; em ticket alto, quem decide é o IR.

**Método de derivação dos leads perdidos** *(nova)*
- *Problema:* o IR depende de "leads perdidos por mês", que é exatamente o número que o cliente não mede. Sem método, o vendedor pergunta, o cliente chuta, e o numerador infla até aprovar o negócio.
- *Decisão:* proibido perguntar quantos leads o cliente perde. O número é derivado ao vivo, com o prospect abrindo o WhatsApp na call e contando mensagens recebidas fora do horário e não respondidas em dois dias, projetadas para 22 dias úteis. Amostra registrada no Pipedrive.

**Abolição do diagnóstico no 1º toque**
- *Problema:* pedir 30 minutos de agenda no primeiro e-mail ou DM gerava rejeição em massa.
- *Decisão:* cadência de outbound alongada para 6 toques em 3 semanas. O primeiro toque é pergunta sobre a dor ("quem responde às 21h?"). O convite para a agenda só no T5, e apenas para quem engajou antes.

**ICP definido: decisão ágil e ticket alto** *(nova)*
- *Problema:* prospecção sem nicho definido produz mensagem genérica, ciclo longo e IR imprevisível.
- *Decisão:* dois ICPs — clínicas de estética avançada e odontologia premium (ticket R$ 2.000–15.000, decisor é o próprio doutor), e advocacia boutique com captação digital (1–3 sócios, Google Ads, urgência do lead). Ambos combinam decisor único, ticket alto e WhatsApp como gargalo. Rodar um por vez no primeiro ciclo, começando pelo A — dois nichos simultâneos com volume baixo impedem qualquer leitura do que funcionou.

**ICP dividido em três faixas: A1, A2 e B** *(nova)*
- *Problema:* estética e odontologia foram agrupadas como um único ICP por terem ticket parecido. Mas vendem de formas opostas — estética vende por desejo, alimentada por Instagram e tráfego pago, com volume alto e decisão rápida; odontologia premium vende por confiança clínica, alimentada por indicação, com volume menor e ciclo mais longo. Mensagem única para os dois sai morna e não converte em nenhum.
- *Decisão:* três faixas — A1 Estética, A2 Odontologia, B Advocacia. Ordem de ativação A1 → A2 → B, uma por vez. A1 primeiro por ter maior volume e ciclo mais curto, gerando dados de resposta mais rápido. Rodar faixas em paralelo é permitido, mas exige registro aqui e renúncia explícita ao teste comparativo de mensagem.

**"WhatsApp direto" como origem de lead, com regra de preenchimento** *(nova)*
- *Problema:* WhatsApp entrou como opção de Origem do Lead durante a configuração do Pipedrive. Mas o WhatsApp é onde a conversa acontece, não de onde o lead veio — quem clicou no anúncio e mandou mensagem veio do Instagram. Sem regra, o campo registra 100% WhatsApp, não mede canal algum, e a decisão de onde investir esforço perde a base.
- *Decisão:* a opção fica, renomeada para "WhatsApp direto", e vale apenas para quem já tinha o número e escreveu sem passar por canal de aquisição — indicação informal, cliente antigo, contato de evento. A regra completa está em `COMERCIAL.md`, seção 7.2.

**Call única de 45 minutos, com oferta na mesa** *(nova)*
- *Problema:* dividir diagnóstico e proposta em dois encontros alonga o ciclo, esfria o lead e dobra a carga de agenda de quem acumula dono e closer. Mas o roteiro de 30 minutos não comporta descoberta, quantificação ao vivo, contraste e pitch.
- *Decisão:* diagnóstico e oferta na mesma reunião, com duração ampliada para 45 minutos. Preço dito em voz alta na call; o PDF apenas formaliza o que já foi acordado, nunca substitui a negociação.

**Formulário como porta da agenda** *(nova)*
- *Problema:* liberar o Calendly direto enche a agenda de lead sem fit e queima o tempo mais escasso da operação.
- *Decisão:* o link enviado na prospecção é o formulário de qualificação em dois passos. O Calendly só é revelado na tela de sucesso se o IR ≥ 2. Como a qualificação já ocorreu, o Calendly passa a pedir apenas nome, e-mail e WhatsApp — repetir as perguntas derruba a taxa de conclusão.

**Lista de prospecção: automação sim, scraping de LinkedIn não** *(nova)*
- *Problema:* montar lista automaticamente é necessário para volume, mas scraping do LinkedIn viola os termos de uso e leva a bloqueio permanente do perfil — que é justamente o canal de abordagem dos toques T1, T2 e T4.
- *Decisão:* Google Places API como fonte primária de lista, enriquecimento via n8n, e coleta no LinkedIn feita manualmente. Perder a conta encerra o canal.

**Documento de Tese gerado por template** *(nova)*
- *Problema:* enviar leitura preliminar da operação antes da call sustenta a promessa de "análise técnica prévia" feita no site. Mas redigir à mão para cada agendamento não sobrevive a 10 reuniões por semana, e boa parte vai dar no-show.
- *Decisão:* documento de uma página gerado por template preenchido automaticamente com os dados do formulário, via n8n, com revisão humana de 2 minutos antes do envio. Sem preço e sem escopo fechado. Se a geração não estiver funcionando, a promessa sai dos materiais — prometer análise prévia e chegar na call perguntando o que a empresa faz é pior que não prometer.

---

## 4. Documentos Revogados

Consolidação de setembro de 2026. Os arquivos abaixo estão arquivados e não devem ser consultados para decisão. Onde houver divergência, valem os cinco documentos oficiais.

- Implantação de Infraestrutura Baseverta → absorvido por `ARQUITETURA.md`
- Módulos Adicionais de Expansão → parte técnica em `ARQUITETURA.md`, parte comercial em `COMERCIAL.md`
- Estrutura Básica - Teste (Cliente Zero) → absorvido por `OPERACAO.md`
- Estratégia Comercial de Conversão, Framework de Aquisição e Funil, Preparação Comercial Mínima → `COMERCIAL.md`
- Qualificação BANT Adaptado, MEDDIC Adaptado, Técnica de Qualificação Avançada → substituídos pelo IR em `COMERCIAL.md`
- estrategia-precificacao v2 e v3 → `COMERCIAL.md`, seção 4
- Posicionamento, Infraestrutura e Portabilidade → `POSICIONAMENTO.md` e `ARQUITETURA.md`
