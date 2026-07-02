FROM debian:13-slim

ENV PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates curl git python3 python-is-python3 python3-pip python3-requests \
    ripgrep ffmpeg gcc g++ make cmake python3-dev python3-venv \
    libffi-dev procps openssh-client xz-utils tmux vim && \
    rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.11.6-python3.13-trixie /usr/local/bin/uv /usr/local/bin/uvx /usr/local/bin/

COPY --from=node:22-bookworm-slim /usr/local/bin/node /usr/local/bin/
COPY --from=node:22-bookworm-slim /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
COPY --from=node:22-bookworm-slim /usr/local/lib/node_modules/corepack /usr/local/lib/node_modules/corepack
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx && \
    ln -sf /usr/local/lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack

RUN useradd -m -u 1000 -d /data coder

RUN printf 'set -g default-terminal "tmux-256color"\nset -as terminal-overrides ",*:RGB"\n' > /data/.tmux.conf && \
    chown coder:coder /data/.tmux.conf && \
    cp /data/.tmux.conf /root/.tmux.conf

RUN curl -fsSL https://github.com/cli/cli/releases/download/v2.67.0/gh_2.67.0_linux_amd64.tar.gz | \
    tar xz -C /tmp && \
    cp /tmp/gh_*/bin/gh /usr/local/bin/ && \
    rm -rf /tmp/gh_*

RUN curl https://cursor.com/install -fsS | HOME=/data bash
RUN curl -fsSL https://opencode.ai/install | HOME=/data bash

RUN echo '#!/bin/bash' > /usr/local/bin/init-project.sh && \
    echo 'MODEL="${1:-opencode/mimo-v2.5-free}"' >> /usr/local/bin/init-project.sh && \
    echo 'opencode run --model "$MODEL" "/multi-agents-dev init"' >> /usr/local/bin/init-project.sh && \
    chmod +x /usr/local/bin/init-project.sh

RUN chown -R coder:coder /data/.opencode /data/.cursor /data/.local 2>/dev/null; true

ENV CODE_HOME=/data \
    PATH="/data/.opencode/bin:/data/.cursor/bin:/data/.local/bin:${PATH}" \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

EXPOSE 7860


COPY --chmod=0755 entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh && ls -la /opt/entrypoint.sh

COPY .opencode /data/.opencode/
RUN chown -R coder:coder /data/.opencode

RUN export LANG=C.UTF-8
RUN export LC_ALL=C.UTF-8
RUN export LC_CTYPE=C.UTF-8

ENTRYPOINT ["/opt/entrypoint.sh"]
