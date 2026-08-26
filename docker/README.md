# Ready-to-use agent container (Docker)

A pre-configured agent container for this workflow: `hermes-agent` with the
`docker-agent-cache-optimized-workflow` skill installed automatically on first
boot. The user only configures their provider (API key) on first launch —
nothing else.

## Pull (published image)

```bash
docker pull ghcr.io/jack89-ml/docker-agent-cache-optimized-workflow:latest
docker run -it --name agent ghcr.io/jack89-ml/docker-agent-cache-optimized-workflow:latest
```

First boot: the hermes wizard asks for your provider key. The skill is then
available as `docker-agent-cache-optimized-workflow` (category
`autonomous-ai-agents`) — start a session and the workflow is ready.

## Build from source

```bash
docker build -t docker-agent-cache -f docker/Dockerfile .
```

## What is inside

- `Dockerfile` — base `nousresearch/hermes-agent`, adds `tmux`, copies the
  skill bundle and the first-boot installer
- `03-skill-install` — s6-overlay `cont-init.d` script (note: the active
  directory is `/etc/cont-init.d/`, not `/opt/hermes/docker/cont-init.d/`):
  copies the skill into `$HERMES_HOME/skills/` on first boot; provider config
  is intentionally left to the user
- `skill/` — the skill bundle (SKILL.md, templates, scripts, examples)

No author configuration or credentials are baked into the image.
