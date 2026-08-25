# INSTALL — Docker Agent Workflow with Cache-Hit Strategy

Skill per agenti (Hermes e altri) che deployano agenti Docker autonomi con
strategia di ottimizzazione del prompt-cache. Questa repo È una skill:
`SKILL.md` è il playbook che l'agente carica e segue; `scripts/` e
`templates/` sono gli strumenti che il playbook usa.

## Prerequisiti

- Linux x86_64 con Docker installato
- Un agente basato su skills (Hermes, Claude Code, Codex, OpenClaw...)
- (Consigliato) `uv` per gli script Python

## Opzione A — Installazione nativa come skill Hermes

```bash
hermes skills install jack89-ML/docker-agent-cache-optimized-workflow
```

Oppure dal package manager dell'ecosistema (funziona con qualsiasi agente
basato su skills):

```bash
npx skills add jack89-ML/docker-agent-cache-optimized-workflow -g -y
```

Verifica:

```bash
hermes skills list | grep docker-agent-cache
# oppure
npx skills list
```

## Opzione B — Clone manuale nella cartella skills

```bash
git clone https://github.com/jack89-ML/docker-agent-cache-optimized-workflow.git
# Hermes:
mkdir -p ~/.hermes/skills/autonomous-ai-agents
cp -r docker-agent-cache-optimized-workflow ~/.hermes/skills/autonomous-ai-agents/
# Claude Code:
# cp -r docker-agent-cache-optimized-workflow ~/.claude/skills/
```

L'agente caricherà la skill automaticamente quando il task combacia con la
descrizione ("Use when deploying a Docker agent with cache-hit strategy"),
oppure su richiesta esplicita.

## Opzione C — Uso diretto senza installazione

```bash
git clone https://github.com/jack89-ML/docker-agent-cache-optimized-workflow.git
cd docker-agent-cache-optimized-workflow
```

Poi chiedi al tuo agente: "usa la skill in <percorso>/SKILL.md e applica il
workflow al progetto X". L'agente leggerà il playbook dal percorso.

## Flusso operativo (cosa succede dopo l'installazione)

1. L'agente carica `SKILL.md` (playbook)
2. Genera i 4 file di contesto per il progetto da `templates/`:
   `AGENT_PROMPT.md`, `CONTEXT.md`, `MASTER_PLAN.md`, `TASK_LIST.md`
   (via `scripts/scaffold_agent.sh <project> <image> <volume> <env_file>`)
3. Compila i placeholder `<...>` (nome progetto, modelli, endpoint)
4. Crea il container Docker e avvia la sessione persistente (tmux)
5. Inietta il prompt dell'agente e il lavoro parte
6. Monitora costi e cache-hit con `scripts/usage_report.sh <state.db>`

## Verifica rapida post-installazione

```bash
bash -n scripts/*.sh                  # sintassi OK
bash tests/test_scaffold.sh           # smoke test dello scaffold
./scripts/scaffold_agent.sh --help    # argomenti corretti
```

## Aggiornamenti

La skill si aggiorna con `git pull` (se clonata) oppure:

```bash
hermes skills update docker-agent-cache-optimized-workflow
# oppure
npx skills update
```

## Nota filosofica

Questa repo è volutamente sia codice sia conoscenza: clonarla è il modo
naturale di usarla (la skill si aggiorna con git). L'installazione via
package manager crea una copia statica: va reinstallata per gli
aggiornamenti.
