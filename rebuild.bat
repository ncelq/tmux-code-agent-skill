docker compose down && docker compose build --no-cache code-agent && docker compose up -d --build && docker exec -u coder -it code_agent-code-agent-1 /bin/bash



#docker compose build --no-cache code-agent
#docker compose up -d