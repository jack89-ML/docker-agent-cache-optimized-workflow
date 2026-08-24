#!/usr/bin/env bash
# ============================================================================
# scaffold_agent.sh — Generate the 4 context files and launch an autonomous agent.
# Usage: ./scaffold_agent.sh <project_name> <image> <volume> <env_file> [extra_docker_args...]
#   <project_name>  project name (e.g. myapp)
#   <image>         docker image (e.g. nousresearch/hermes-agent)
#   <volume>        persistent volume (e.g. /opt/myapp-data)
#   <env_file>      env file with API keys (e.g. /opt/myapp.env)
#   [args]          extra docker run args (e.g. --network host — use ONLY if needed)
#
# Security notes:
#   - The container runs as UID 10000 (non-root) when SCAFFOLD_USER is unset and
#     the image supports it; override with SCAFFOLD_USER=<uid> or SCAFFOLD_USER=0 for root.
#   - --network host exposes the host network namespace: pass it ONLY when the
#     agent must reach LAN hosts; prefer a dedicated bridge otherwise.
#   - The env file must be chmod 0600 and contain ONE key per line (duplicate
#     lines break naive parsing).
# ============================================================================
set -euo pipefail

if [ $# -lt 4 ]; then
  echo "Usage: $0 <project_name> <image> <volume> <env_file> [docker_args...]"
  exit 1
fi

PROJ="$1"; IMAGE="$2"; VOL="$3"; ENVF="$4"; shift 4
DOCKER_ARGS=("$@")
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="$VOL/workspace"
CONTAINER="agent-${PROJ}"
RUN_USER="${SCAFFOLD_USER:-10000:10000}"

echo "=== Scaffolding agent: $PROJ ==="

# 0. Preconditions
[ -f "$ENVF" ] || { echo "ERROR: env file $ENVF not found"; exit 1; }
[ "$(stat -c %a "$ENVF" 2>/dev/null)" = "600" ] || \
  echo "WARNING: env file $ENVF is not 0600 — chmod it to protect your keys"
case " ${DOCKER_ARGS[*]} " in
  *" --network host "*|*"--network=host"*)
    echo "WARNING: --network host exposes the host network namespace. Prefer a dedicated bridge when possible."
    ;;
esac

sudo mkdir -p "$WS"
sudo chown 10000:10000 "$VOL" "$WS" 2>/dev/null || true

# 1. Generate the 4 context files from the templates
echo "— Generating context files in $WS"
for t in CONTEXT MASTER_PLAN TASK_LIST AGENT_PROMPT; do
  SRC="$SKILL_DIR/templates/${t}_TEMPLATE.md"
  DST="$WS/${t}.md"
  if [ -f "$SRC" ]; then
    sudo cp "$SRC" "$DST"
    sudo chown 10000:10000 "$DST"
    echo "  ✓ ${t}.md (template — fill in the <...> placeholders)"
  fi
done

# 2. Base placeholder substitution (if provided via env vars)
sudo sed -i "s/<PROJECT_NAME>/${PROJ}/g" "$WS"/*.md 2>/dev/null || true
echo "  ✓ PROJECT_NAME placeholders substituted"

# 3. Create/recreate the container (non-root user, restart policy)
echo "— Container $CONTAINER (image $IMAGE)"
sudo docker rm -f "$CONTAINER" 2>/dev/null || true
sudo docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  --user "$RUN_USER" \
  "${DOCKER_ARGS[@]}" \
  -v "$VOL:/opt/data" \
  --env-file "$ENVF" \
  "$IMAGE" sleep infinity
echo "  ✓ container started (user: $RUN_USER)"

# 4. Install tmux in the container (as root, if missing)
sudo docker exec -u 0 "$CONTAINER" bash -c 'which tmux >/dev/null 2>&1 || apt-get install -y tmux >/dev/null 2>&1' || true

# 5. Launch the persistent session (as the non-root agent user)
sudo docker exec "$CONTAINER" bash -c "tmux new-session -d -s agent -x 200 -y 50 hermes" 2>/dev/null \
  || sudo docker exec -u 0 "$CONTAINER" bash -c "tmux new-session -d -s agent -x 200 -y 50 hermes"
sleep 10

# 6. Inject the prompt via buffer (robust against quoting pitfalls)
sudo docker cp "$WS/AGENT_PROMPT.md" "$CONTAINER:/tmp/agent_prompt.md"
sudo docker exec "$CONTAINER" bash -c \
  'tmux load-buffer -b agent_prompt /tmp/agent_prompt.md \
   && tmux paste-buffer -b agent_prompt -t agent \
   && tmux send-keys -t agent Enter' 2>/dev/null \
  || sudo docker exec -u 0 "$CONTAINER" bash -c \
  'tmux load-buffer -b agent_prompt /tmp/agent_prompt.md \
   && tmux paste-buffer -b agent_prompt -t agent \
   && tmux send-keys -t agent Enter'

echo ""
echo "=== DONE ==="
echo "Container : $CONTAINER (tmux session: agent)"
echo "Workspace : $WS"
echo ""
echo "Next steps:"
echo "  1. Fill in the <...> placeholders in the 4 files (MASTER_PLAN and CONTEXT first)"
echo "  2. Verify: sudo docker exec $CONTAINER bash -c 'tmux capture-pane -t agent -p | tail -20'"
echo "  3. Monitor costs: bash scripts/usage_report.sh $VOL/state.db"
