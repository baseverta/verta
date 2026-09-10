# Verta — Posicionamento de Infraestrutura e Portabilidade

**Versão:** 1.0  
**Data:** agosto de 2026  
**Status:** Diretriz obrigatória  
**Relacionada à:** R3 — Retenção por SLA, Não por Atrito

---

## 1. Princípio Central (Inegociável)

A Verta retém clientes pela qualidade da operação, pelo SLA cumprido e pelo resultado mensurável.

**Nunca** pela impossibilidade de o cliente sair ou pela ameaça de desligar a infraestrutura.

Qualquer forma de retenção por atrito (lock-in artificial) é proibida, mesmo que sutil.

---

## 2. O que é permitido (e recomendado)

- Gerenciar a infraestrutura (VPS, Hostinger, n8n, etc.) enquanto o contrato estiver ativo.
- Manter controle operacional para garantir estabilidade, segurança, backups, atualizações e cumprimento de SLA.
- Usar instância sob nossa gestão no início (especialmente Rota 1) por questões de velocidade e controle.
- Em clientes maiores (Rota 2), preferir criar a infraestrutura já no nome do cliente com acesso administrativo nosso.

Isso é boa engenharia. Não é lock-in.

---

## 3. O que é proibido

- Usar o desligamento do servidor como mecanismo de retenção ou ameaça.
- Dizer ou sugerir que “sem a gente a operação para” de forma a criar medo.
- Criar obstáculos artificiais à migração ou transferência.
- Usar linguagem que faça o cliente se sentir refém da infraestrutura.

---

## 4. Linguagem oficial recomendada

Quando o cliente perguntar sobre o servidor, conta ou infraestrutura, usar esta formulação (ou equivalente limpa):

> “A infraestrutura fica sob nossa gestão enquanto o contrato estiver ativo. Isso garante estabilidade, atualizações de segurança, backups e o cumprimento do SLA.  
> Toda a configuração (fluxos, prompts, integrações) é documentada.  
> Ao final do contrato, fazemos a transferência completa da conta e dos acessos para você, ou entregamos o export completo para migração, conforme preferir.”

### O que evitar dizer

- “Para manter ativo precisa de manutenção conosco”
- “A conta é sua, mas...” (se tecnicamente ainda não for)
- Qualquer frase que implique dependência forçada

---

## 5. Portabilidade (obrigatória no contrato)

Todo contrato deve prever, de forma clara:

- Ao término do contrato (ou mediante solicitação formal), a Verta realizará a transferência da conta/infraestrutura ou entregará export completo dos fluxos, prompts, configurações e credenciais relevantes.
- Prazo máximo de transferência/export: a ser definido no contrato (recomendado: até 10 dias úteis após o encerramento).
- A Verta não criará obstáculos técnicos ou burocráticos à saída do cliente.

O custo de troca legítimo (reconfigurar, reotimizar, perder histórico de ajustes) já existe naturalmente. Não precisamos inventar barreiras artificiais.

---

## 6. Instrução permanente para o Chat (IA Sócia)

**Sempre que o fundador solicitar:**

- Geração de proposta comercial
- Roteiro de comunicação com cliente
- Resposta a objeções
- Cláusulas de contrato
- Qualquer material client-facing relacionado a infraestrutura, servidor, hospedagem ou continuidade

**O chat deverá:**

1. Lembrar explicitamente desta diretriz.
2. Verificar se a linguagem proposta está alinhada com o posicionamento de portabilidade e anti-lock-in.
3. Alertar caso alguma formulação esteja se aproximando de retenção por atrito.

Esta notificação é obrigatória e deve aparecer de forma clara no início ou durante a resposta, para que o posicionamento nunca seja esquecido na correria do dia a dia.

---

## 7. Resumo Executivo

| Aspecto | Diretriz |
|---------|----------|
| Controle operacional da infra | Sim, enquanto o contrato estiver ativo |
| Retenção por medo de desligamento | Proibido |
| Portabilidade ao final do contrato | Obrigatória e documentada |
| Linguagem com o cliente | Transparente, profissional e sem ameaça velada |
| Lembrete automático do chat | Sempre que houver proposta ou comunicação client-facing |

---

**Este documento é parte da governança da Verta.**  
Qualquer desvio deve ser justificado explicitamente. Em caso de dúvida, prevalece a R3: retenção por SLA e resultado, nunca por atrito.
