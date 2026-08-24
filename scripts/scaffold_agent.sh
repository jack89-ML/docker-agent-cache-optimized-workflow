#!/usr/bin/env bash
# ============================================================================
# scaffold_agent.sh — Genera i 4 file di contesto e lancia l'agente autonomo.
# Uso: ./scaffold_agent.sh <project_name> <image> <volume> <env_file> [extra_docker_args...]
#   <project_name>  nome progetto (es. myapp)
#   <image>         immagine docker (es. nousresearch/hermes-agent)
#   <volume>        volume persistente (es. /opt/myapp-data)
#   <env_file>      file env con le chiavi API (es. /opt/myapp.env)
#   [args]          argomenti extra docker run (es. --network host)
# ============================================================================
set -euo pipefail

if [ $# -lt 4 ]; then
  echo "Uso: $0 <project_name> <image> <volume> <env_file> [docker_args...]"
  exit 1
fi

PROJ="$1"; IMAGE="$2"; VOL="$3"; ENVF="$4"; shift 4
DOCKER_ARGS=("$@")
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="$VOL/workspace"
CONTAINER="agent-${PROJ}"

echo "=== Scaffold agente: $PROJ ==="

# 0. Precondizioni
[ -f "$ENVF" ] || { echo "ERRORE: env file $ENVF non trovato"; exit 1; }
sudo mkdir -p "$WS"
sudo chown 10000:10000 "$VOL" "$WS" 2>/dev/null || true

# 1. Genera i 4 file di contesto dai template
echo "— Generazione file di contesto in $WS"
for t in CONTEXT MASTER_PLAN TASK_LIST AGENT_PROMPT; do
  SRC="$SKILL_DIR/templates/${t}_TEMPLATE.md"
  DST="$WS/${t}.md"
  if [ -f "$SRC" ]; then
    sudo cp "$SRC" "$DST"
    sudo chown 10000:10000 "$DST"
    echo "  ✓ ${t}.md (template — COMPILA i placeholder <...>)"
  fi
done

# 2. Sostituzioni placeholder base (se fornite via variabili d'ambiente)
sudo sed -i "s/<PROJECT_NAME>/${PROJ}/g" "$WS"/*.md 2>/dev/null || true
echo "  ✓ placeholder PROJECT_NAME sostituiti"

# 3. Crea/ricrea il container
echo "— Container $CONTAINER (immagine $IMAGE)"
sudo docker rm -f "$CONTAINER" 2>/dev/null || true
sudo docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  "${DOCKER_ARGS[@]}" \
  -v "$VOL:/opt/data" \
  --env-file "$ENVF" \
  "$IMAGE" sleep infinity
echo "  ✓ container avviato"

# 4. Installa tmux nel container (se manca)
sudo docker exec "$CONTAINER" bash -c 'which tmux >/dev/null 2>&1 || apt-get install -y tmux >/dev/null 2>&1' || true

# 5. Lancia la sessione persistente
sudo docker exec -d "$CONTAINER" bash -c "tmux new-session -d -s agent -x 200 -y 50 hermes"
sleep 10

# 6. Inietta il prompt via buffer (robusto contro i problemi di quoting)
sudo docker cp "$WS/AGENT_PROMPT.md" "$CONTAINER:/tmp/agent_prompt.md"
sudo docker exec "$CONTAINER" bash -c \
  'tmux load-buffer -b agent_prompt /tmp/agent_prompt.md \
   && tmux paste-buffer -b agent_prompt -t agent \
   && tmux send-keys -t agent Enter'

echo ""
echo "=== FATTO ==="
echo "Container : $CONTAINER (tmux session: agent)"
echo "Workspace : $WS"
echo ""
echo "Prossimi passi:"
echo "  1. Compila i placeholder <...> nei 4 file (soprattutto MASTER_PLAN e CONTEXT)"
echo "  2. Verifica: sudo docker exec $CONTAINER bash -c 'tmux capture-pane -t agent -p | tail -20'"
echo "  3. Controlla costi: watch -n 60 'sqlite3 $VOL/state.db ...' (colonna cache_read_tokens)"
