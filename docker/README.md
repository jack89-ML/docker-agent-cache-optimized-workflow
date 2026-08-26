# Local-model agent container

A ready-to-use Docker image for running this workflow against a LOCAL model
backend (any OpenAI-compatible server, e.g. FreeToken). The image is
parameterized: **no configuration of the image author is baked in** — every
user supplies their own backend URL and model name via environment variables
at first boot.

## Build

```bash
docker build -t agent-local-bench:full -f docker/Dockerfile .
```

## Run (first boot, empty volume)

```bash
docker run -d --name bench --network host \
  -e FREETOKEN_BASE_URL=http://192.168.x.x:1919/v1 \
  -e MODEL_NAME=qwen36-35b \
  -v /path/to/data:/opt/data \
  agent-local-bench:full sleep infinity
```

On first boot the container generates `config.yaml` from the template using
the environment variables (marker file `.topic-pool-seeded` prevents
overwrites on restarts). No author data is shipped in the image.

## What is inside

- `Dockerfile` — base `nousresearch/hermes-agent`, adds `tmux`, copies
  templates and the first-boot bootstrap script
- `03-topic-pool-setup` — s6-overlay `cont-init.d` script: renders
  `config.yaml` from the template on first boot (note: the active
  `cont-init.d` directory is `/etc/cont-init.d/`, not
  `/opt/hermes/docker/cont-init.d/`)
- `config.template.yaml` — parameterized config (model, base URL, thinking
  disabled via `chat_template_kwargs`)

## Local-model notes (measured on RTX A2000 12GB, Qwen3.6-35B-A3B)

- MoE models with expert offload run fine; dense models must fit in VRAM
- KV cache budget must be re-applied after every model restart (the default
  sequence limit collapses to ~8K → "prompt too long" errors)
- Pareto point for agent tasks (~43K token context max): KV 64-80K +
  remaining VRAM to experts (radix prefix cache hits ~96%)
- Thinking can be disabled via `chat_template_kwargs: enable_thinking: false`
  (Qwen3.x templates) — removes reasoning loops in agent sessions
