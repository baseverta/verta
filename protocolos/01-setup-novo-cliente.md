# 01 — Setup de cliente novo

O passo a passo de quando um negócio é ganho até o cliente estar operando. A maior
parte é automática; este documento existe para você saber **o que deve acontecer
sozinho**, **o que exige gente** e **como perceber que algo não aconteceu**.

> **Antes deste documento vêm outros dois.** O protocolo 08 define em qual modelo o
> cliente será implantado (VPS dedicada ou compartilhada) e provisiona a
> infraestrutura; o protocolo 09 fecha quais módulos ele tem. Os passos abaixo
> assumem CRM, arquivos e formulários ligados — se algum não estiver contratado,
> pule os itens correspondentes em vez de tratá-los como pendência.

## Princípio que governa tudo aqui

> Nada no processo pode depender de o cliente responder alguma coisa.

O cliente pode sumir por duas semanas depois de assinar. O setup precisa avançar
até o limite do que não depende dele, e o que depende vira cobrança automática +
handoff humano. Formulário é **coleta**, nunca **pré-requisito**.

## O gatilho: marcar o negócio como ganho no CRM

Todo o setup nasce de um evento só — o negócio virar `won`. Não crie nada na mão antes
disso, porque a automação vai criar de novo e você fica com registro duplicado.

Ao marcar como ganho, dispara em paralelo:

1. Pasta do cliente **move** de `01 - Lead` para `02 - Cliente` no Drive
2. Subpastas `Contratos` e `Arquivos Recebidos` são criadas
3. Formulário de **Onboarding** é enviado ao cliente por e-mail
4. Link do **Kickoff** vai para o time, para o card do cliente e vira uma atividade
5. `client_forms` registra o envio, para a cobrança saber o que cobrar

### O que fazer se o negócio foi ganho e nada aconteceu

Abra a execução do workflow `Sincronizacao Deal - Pipedrive -> Supabase` no n8n.
Erro mais provável: o lead não tinha pasta no Drive (cliente que entrou por um
caminho fora do padrão). Existe guarda para isso hoje (`Tem Pasta no Drive (Won)?`),
mas se o sintoma voltar, é ali que se olha.

## Os dois formulários, e por que são diferentes

| | Onboarding do Cliente | Kickoff Operacional |
|---|---|---|
| Quem preenche | o cliente, sozinho | **o nosso time**, com o cliente na reunião |
| Quando | logo após o ganho | na reunião de kickoff |
| Se não responder | cobrança automática ×2, depois e-mail para o time | não se aplica |

O Kickoff ser preenchido pelo time foi decisão deliberada: pedir dado técnico
(horário de funcionamento, ferramentas, quem é o responsável técnico) por formulário
para o cliente gera resposta vaga ou nenhuma. Na reunião, com a pessoa na linha,
sai em cinco minutos e sai certo.

### Como o time abre o formulário certo do cliente certo

O link do Kickoff carrega dois parâmetros: `public_token` (identifica o lead) e
`cliente` (nome da empresa, que o formulário exibe na primeira tela).

**Confira o nome na primeira tela antes de digitar qualquer coisa.** Se estiver
diferente do cliente da reunião, o link está errado — pare. É a única barreira
contra gravar o kickoff de um cliente no cadastro de outro.

O mesmo link está em três lugares para você nunca precisar caçar e-mail:
o e-mail que o time recebeu, o campo **Link do Kickoff** no card do CRM, e uma
atividade de reunião no próprio card.

### A cobrança de formulário

Roda diariamente às 09h. Cobra o cliente duas vezes com intervalo. Depois da segunda
tentativa sem resposta, **para de cobrar** e manda e-mail para o time fazer contato
pessoal. Isso é de propósito: um terceiro e-mail automático não convence ninguém e
queima a relação. A partir dali o problema é humano, não de automação.

## Erros que já cometemos

**Negócio ganho derrubou a execução inteira.**
Sintoma: o formulário de onboarding não foi enviado. Causa: o lead não tinha pasta
no Drive, o node de mover pasta recebeu `files/undefined` e a execução morreu —
levando junto o disparo do formulário, que estava depois na mesma execução.
Regra: **efeito colateral importante nunca fica atrás de um passo que pode falhar
por dado faltando.** Hoje os nodes de Drive têm guarda de existência e
`onError: continueRegularOutput`.

**Formulário como pré-requisito.**
Chegamos a condicionar passos à resposta do onboarding. Um cliente que demora
três semanas trava o setup inteiro. Regra: formulário alimenta, não bloqueia.

**Link de kickoff sem identificação visível.**
A primeira versão do link só tinha o token. Ninguém consegue conferir um UUID de
olho. Passamos a embutir o nome da empresa e exibi-lo na abertura do formulário,
para o erro ser óbvio antes de custar dado errado.

**Token editado na mão derrubava a execução.**
Se o `public_token` na URL viesse torto ou vazio, o Postgres estourava
`invalid input syntax for type uuid` e a execução morria. Hoje o formato é validado
antes de montar a query e, se não for UUID, cai no critério seguinte (CNPJ, e-mail,
telefone).

## Checklist de conferência (5 minutos, depois de fechar um cliente)

- [ ] Pasta do cliente está em `02 - Cliente`, com `Contratos` e `Arquivos Recebidos`
- [ ] Card do CRM tem Empresa (não só Pessoa) e o campo Pasta no Drive preenchido
- [ ] Campo **Link do Kickoff** preenchido no card
- [ ] Atividade de reunião de kickoff criada
- [ ] `RESUMO.md` na pasta do cliente reflete o que sabemos dele
- [ ] Cliente tem e-mail cadastrado — sem e-mail não casamos transcrição de reunião
      nem conseguimos enviar formulário (ver protocolo 03)

O último item é o que mais falha, porque lead que entrou por WhatsApp costuma não
ter e-mail. A auditoria diária das 08h30 reclama disso — e ela está certa.
