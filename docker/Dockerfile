# docker-agent-cache-optimized-workflow — ready-to-use agent container.
# hermes-agent + the cache-optimized-workflow skill pre-installed on first boot.
# The user only configures their provider (API key) on first launch.
#
# Build:  docker build -t docker-agent-cache -f docker/Dockerfile .
# Run:    docker run -it --name agent docker-agent-cache
#         (first boot: hermes wizard asks for the provider key, then the skill
#          is available as docker-agent-cache-optimized-workflow)
#
# No author configuration or credentials are baked in.

FROM nousresearch/hermes-agent:latest

# tmux (agent sessions inside the container)
RUN apt-get update && apt-get install -y --no-install-recommends tmux \
    && rm -rf /var/lib/apt/lists/*

# the skill (SKILL.md + templates + scripts)
COPY docker/skill/ /opt/setup/skill/

# first-boot installer (s6-overlay cont-init.d runs before the service)
COPY docker/03-skill-install /etc/cont-init.d/03-skill-install
RUN chmod +x /etc/cont-init.d/03-skill-install
