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

# Lean CLI does not ship modules-*.json in the wheel; on import it downloads
# that file into its own package directory and refreshes it daily. Fetch it
# now as root so the file exists. Always chown the package to `coder` so the
# runtime user can write the refresh (and __pycache__) even if the CDN fetch
# fails during the image build.
RUN pip install lean --break-system-packages && \
    (python3 -c "from lean.models import json_modules" || true) && \
    chown -R coder:coder "$(python3 -c 'import lean, pathlib; print(pathlib.Path(lean.__file__).parent)')"
RUN curl https://cursor.com/install -fsS | HOME=/data bash
RUN curl -fsSL https://opencode.ai/install | HOME=/data bash
RUN npm install -g --ignore-scripts --min-release-age=0 @earendil-works/pi-coding-agent
RUN HOME=/data pi install npm:@akepka/pi-cursor-cli-provider

# Once-off runtime dirs and default Pi settings (do not regenerate at start).
RUN mkdir -p /data/.local/share/opencode /data/.npm /data/.lean && \
    cat > /data/.pi/agent/settings.json <<'EOF'
{
  "packages": [
    "npm:@akepka/pi-cursor-cli-provider"
  ],
  "lastChangelogVersion": "0.84.1",
  "theme": "dark",
  "skills": ["/data/.pi/skills"],
  "enabledModels": [
    "opencode-go/mimo-v2.5",
    "opencode-go/deepseek-v4-flash",
    "opencode-go/muse-spark-1.2-contributor",
    "cursor/cursor-grok-4.5-high-fast",
    "cursor/cursor-grok-4.6-high-fast",
    "cursor/composer-2.5-fast",
    "opencode/hy3-free",
    "opencode/nemotron-3-ultra-free",
    "opencode/nemotron-3.5-lightning-free",
    "cursor/claude-opus-5-thinking-max",
    "mistral/codestral-latest",
    "nvidia/z-ai/glm-5.2",
    "nvidia/moonshotai/kimi-k2.6",
    "nvidia/minimaxai/minimax-m3",
    "nvidia/nvidia/nemotron-3-ultra-550b-a55b",
    "nvidia/nvidia/nemotron-3.5-lightning-30b-a3b",
    "nvidia/nvidia/nemotron-3-super-120b-a12b"
  ],
  "defaultProvider": "opencode",
  "defaultModel": "nemotron-3.5-lightning-free"
}
EOF

RUN mkdir -p ~/.pi/agent/extensions
RUN cp -r /usr/local/lib/node_modules/@earendil-works/pi-coding-agent/examples/extensions/plan-mode ~/.pi/agent/extensions/

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

RUN chown -R coder:coder /data/.opencode /data/.cursor /data/.local /data/.pi /data/.npm /data/.lean 2>/dev/null; true

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

RUN echo "https://$GITHUB_TOKEN:@github.com" > ~/.git-credentials
RUN git config --global credential.helper store

COPY .pi /data/.pi/
RUN chown -R coder:coder /data/.pi

COPY .cursor /data/.cursor/
RUN chown -R coder:coder /data/.cursor

#COPY .opencode /data/.opencode/
#RUN chown -R coder:coder /data/.opencode

#COPY .agents /data/.agents/
#RUN chown -R coder:coder /data/.agents

RUN export LANG=C.UTF-8
RUN export LC_ALL=C.UTF-8
RUN export LC_CTYPE=C.UTF-8

ENTRYPOINT ["/opt/entrypoint.sh"]
