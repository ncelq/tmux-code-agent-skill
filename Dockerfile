FROM debian:13-slim

ENV PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates curl git python3 python-is-python3 python3-pip python3-requests \
    ripgrep ffmpeg gcc g++ make cmake python3-dev python3-venv \
    libffi-dev procps openssh-client xz-utils tmux vim && \
    rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.11.6-python3.13-trixie /usr/local/bin/uv /usr/local/bin/uvx /usr/local/bin/

COPY --from=node:latest /usr/local/bin/node /usr/local/bin/
COPY --from=node:latest /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

RUN useradd -m -u 1000 -d /data coder

RUN printf 'set -g default-terminal "tmux-256color"\nset -as terminal-overrides ",*:RGB"\n' > /data/.tmux.conf && \
    chown coder:coder /data/.tmux.conf && \
    cp /data/.tmux.conf /root/.tmux.conf

COPY --from=maniator/gh:v2.67.0 /usr/bin/gh /usr/local/bin/gh

RUN curl https://cursor.com/install -fsS | HOME=/data bash
RUN curl -fsSL https://opencode.ai/install | HOME=/data bash
RUN npm install -g --ignore-scripts --min-release-age=0 @earendil-works/pi-coding-agent
RUN HOME=/data pi install npm:@akepka/pi-cursor-cli-provider

RUN git clone --depth 1 https://github.com/obra/superpowers.git /tmp/superpowers && \
    mkdir -p /data/.pi/agent/skills && \
    for skill in brainstorming writing-plans "test-driven-development" \
        "using-git-worktrees" "requesting-code-review" \
        "finishing-a-development-branch"; do \
        mv "/tmp/superpowers/skills/$skill" /data/.pi/agent/skills/; \
    done && \
    rm -rf /tmp/superpowers

# pi-cursor-cli-provider discovers Cursor models via the Cursor CLI (`agent`).
# Install puts a symlink at ~/.local/bin/agent (not a regular file).
RUN test -x /data/.local/bin/agent && \
    ln -sf /data/.local/bin/agent /usr/local/bin/agent && \
    /usr/local/bin/agent --version

RUN echo '#!/bin/bash' > /usr/local/bin/init-project.sh && \
    echo 'PROJECT_DIR="${1:-.}"' >> /usr/local/bin/init-project.sh && \
    echo 'mkdir -p "$PROJECT_DIR/.opencode"' >> /usr/local/bin/init-project.sh && \
    echo 'cp -r /data/.opencode/skills/multi-agents-dev/agents "$PROJECT_DIR/.opencode/"' >> /usr/local/bin/init-project.sh && \
    echo 'cp /data/.opencode/skills/multi-agents-dev/*.sh "$PROJECT_DIR/"' >> /usr/local/bin/init-project.sh && \
    chmod +x /usr/local/bin/init-project.sh

RUN chown -R coder:coder /data/.opencode /data/.cursor /data/.local /data/.pi /data/.npm 2>/dev/null; true

# Allow the runtime (non-root `coder`) user to run `pi update` itself.
# `pi update` calls `npm install -g`, which must be able to rename the
# package dir inside the global lib and recreate the `pi` symlink in bin,
# and to write to its npm cache (~/.npm == /data/.npm under HOME=/data).
RUN chown -R coder:coder /usr/local/lib/node_modules /usr/local/bin 2>/dev/null; true

ENV CODE_HOME=/data \
    HOME=/data \
    NPM_CONFIG_CACHE=/data/.npm \
    PATH="/data/.opencode/bin:/data/.cursor/bin:/data/.local/bin:/usr/local/bin:${PATH}" \
    CURSOR_AGENT_PATH=/usr/local/bin/agent \
    AGENT_PATH=/usr/local/bin/agent \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

EXPOSE 7860


COPY --chmod=0755 entrypoint.sh /opt/entrypoint.sh
RUN sed -i 's/\r$//' /opt/entrypoint.sh && chmod +x /opt/entrypoint.sh

#COPY .opencode /data/.opencode/
#RUN chown -R coder:coder /data/.opencode

#COPY .agents /data/.agents/
#RUN chown -R coder:coder /data/.agents

RUN export LANG=C.UTF-8
RUN export LC_ALL=C.UTF-8
RUN export LC_CTYPE=C.UTF-8

ENTRYPOINT ["/opt/entrypoint.sh"]
