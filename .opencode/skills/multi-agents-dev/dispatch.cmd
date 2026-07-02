@echo off
setlocal
set "PS1=%TEMP%\dispatch-%RANDOM%.ps1"
powershell -NoProfile -Command "((Get-Content -LiteralPath '%~f0') | Select-Object -Skip 9) | Set-Content -LiteralPath '%PS1%' -Encoding UTF8"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
set "EXITCODE=%ERRORLEVEL%"
del "%PS1%" 2>nul
exit /b %EXITCODE%

# --- PowerShell follows ---
# dispatch.cmd — send message to agent pane + C-m
# Usage: dispatch.cmd <agent> <message>
#
# Agents: orchestrator, Cursor, implementer, ops
# Env: TMUX_SESSION (default: main), DISPATCH_DEBUG (set to 1 for verbose)
#      DISPATCH_FORCE (set to 1 to bypass duplicate guard), DISPATCH_DEDUP_MS (default: 5000)

$ErrorActionPreference = 'Stop'

function Get-AgentPane {
    param([string]$Agent)
    $session = if ($env:TMUX_SESSION) { $env:TMUX_SESSION } else { 'main' }
    switch ($Agent.ToLower()) {
        'orchestrator' { return "${session}:0.0" }
        'cursor'       { return "${session}:0.1" }
        'implementer'  { return "${session}:0.2" }
        'ops'          { return "${session}:0.3" }
        default {
            Write-Error "Unknown agent '$Agent'. Use: orchestrator, Cursor, implementer, ops"
            exit 1
        }
    }
}

function Test-RecentDuplicate {
    param([string]$Pane, [string]$Message)
    if ($env:DISPATCH_FORCE -eq '1') { return $false }
    $windowMs = if ($env:DISPATCH_DEDUP_MS) { [int]$env:DISPATCH_DEDUP_MS } else { 5000 }
    $stateFile = Join-Path $env:TEMP 'dispatch-last.json'
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $key = "$Pane|$Message"
    if (Test-Path $stateFile) {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        if ($state.Key -eq $key -and ($now - $state.Ts) -lt $windowMs) {
            return $true
        }
    }
    @{ Key = $key; Ts = $now } | ConvertTo-Json | Set-Content $stateFile -Encoding UTF8
    return $false
}

function Send-Dispatch {
    param([string]$Pane, [string]$Message)
    if ($env:DISPATCH_DEBUG -eq '1') {
        Write-Host "dispatch: pane=$Pane message=$Message"
    }
    # -l = literal text (required for /commands and paths); do NOT use '--' (breaks on Windows tmux)
    & tmux send-keys -t $Pane -l $Message
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Start-Sleep -Seconds 1
    & tmux send-keys -t $Pane C-m
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if ($args.Count -lt 2) {
    Write-Host @"
Usage:
  dispatch.cmd <agent> <message>

  Sends message literally, waits 1s, then C-m (Enter) automatically.
  Skips duplicate pane+message within 5s (override: DISPATCH_FORCE=1).

Agents: orchestrator (0.0), Cursor (0.1), implementer (0.2), ops (0.3)

Examples:
  dispatch.cmd Cursor "/brainstorming build API. Save specs to ./docs/"
  dispatch.cmd ops "/skills using-git-worktrees create branch dev/my-feature"
  dispatch.cmd orchestrator "using-git-worktress step finished, you can proceed next step"
"@
    exit 1
}

$agent = $args[0]
$message = if ($args.Count -gt 2) { ($args[1..($args.Count - 1)] -join ' ') } else { $args[1] }
$pane = Get-AgentPane $agent

if (Test-RecentDuplicate -Pane $pane -Message $message) {
    if ($env:DISPATCH_DEBUG -eq '1') {
        Write-Host "dispatch: SKIPPED duplicate to $pane (within dedup window)"
    }
    exit 0
}

Send-Dispatch -Pane $pane -Message $message
