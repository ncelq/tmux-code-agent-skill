@echo off
setlocal
set CONTAINER=code_agent-code-agent-1

docker compose down
if errorlevel 1 exit /b 1
docker compose build --no-cache code-agent
if errorlevel 1 exit /b 1
docker compose up -d --build
if errorlevel 1 exit /b 1

echo Waiting for %CONTAINER% to stay running...
set /a i=0
:wait
set /a i+=1
if %i% gtr 60 (
  echo Container did not become ready.
  docker inspect -f "Status={{.State.Status}} Exit={{.State.ExitCode}} Restarts={{.RestartCount}}" %CONTAINER%
  exit /b 1
)
for /f "usebackq delims=" %%s in (`docker inspect -f "{{.State.Status}}" %CONTAINER% 2^>nul`) do set STATUS=%%s
if /i not "%STATUS%"=="running" (
  timeout /t 1 /nobreak >nul
  goto wait
)

docker exec -u coder -it %CONTAINER% /bin/bash
