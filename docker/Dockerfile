# agent-local-bench:full — Topic Pool / Benchmark container, user-ready.
# Dal primo avvio si auto-configura (volume vuoto) usando le ENV dell'utente.
#
# Build:  docker build -t agent-local-bench:full -f docker/Dockerfile .
# Run (con il TUO backend OpenAI-compatibile):
#   docker run -d --name bench --network host \
#     -e FREETOKEN_BASE_URL=http://192.168.x.x:1919/v1 \
#     -e MODEL_NAME=qwen36-35b \
#     -v /path/to/data:/opt/data \
#     agent-local-bench:full sleep infinity
#
# Nessun dato di chi ha costruito l'immagine: la config nasce dalle env.

FROM nousresearch/hermes-agent:latest

# tmux (sessioni agente nel container)
RUN apt-get update && apt-get install -y --no-install-recommends tmux \
    && rm -rf /var/lib/apt/lists/*

# template di config parametrizzata (segnaposto -> env al primo avvio)
COPY setup/config.template.yaml  /opt/setup/config.template.yaml
COPY skill-templates/            /opt/setup/skill-templates/
COPY pipeline/                   /opt/setup/pipeline/

# bootstrap al primo avvio (eseguito da s6-overlay PRIMA del servizio)
COPY docker/03-topic-pool-setup  /etc/cont-init.d/03-topic-pool-setup
RUN chmod +x /etc/cont-init.d/03-topic-pool-setup
