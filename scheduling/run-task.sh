#!/bin/bash
# Gaia Scheduling Layer v2 — Task Runner
# Invokes Claude Code CLI in non-interactive mode for automated tasks.
#
# Usage: run-task.sh <task-name> [model] [budget]
#   task-name: matches a file in scheduling/prompts/<task-name>.md
#   model:     claude model alias (default: sonnet)
#   budget:    max USD spend (default: 2.00)
#
# Called by Windows Task Scheduler. See setup-scheduler.ps1 to register tasks.

set -uo pipefail

TASK_NAME="${1:?Usage: run-task.sh <task-name> [model] [budget]}"
MODEL="${2:-sonnet}"
BUDGET="${3:-2.00}"

GAIA_DIR="C:/GitHub/Gaia"
CLAUDE_BIN="$HOME/.local/bin/claude"
PROMPT_FILE="$GAIA_DIR/scheduling/prompts/$TASK_NAME.md"
LOG_DIR="$GAIA_DIR/scheduling/logs"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
LOG_FILE="$LOG_DIR/$TASK_NAME-$TIMESTAMP.log"

# Simple logging — no process substitution (avoids hang on Windows)
log() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG_FILE"; }

mkdir -p "$LOG_DIR"

log "=== Gaia Task: $TASK_NAME ==="
log "Model: $MODEL | Budget: \$$BUDGET"

if [ ! -f "$PROMPT_FILE" ]; then
    log "ERROR: Prompt file not found: $PROMPT_FILE"
    exit 1
fi

if [ ! -f "$CLAUDE_BIN" ]; then
    # Fallback to PATH
    CLAUDE_BIN=$(which claude 2>/dev/null || true)
    if [ -z "$CLAUDE_BIN" ]; then
        log "ERROR: claude binary not found at ~/.local/bin/claude or in PATH"
        exit 1
    fi
fi

cd "$GAIA_DIR" || exit 1

# Wait for network (machine may have just woken from sleep)
for i in 1 2 3; do
    if ping -n 1 -w 2000 api.anthropic.com > /dev/null 2>&1; then
        break
    fi
    log "Waiting for network (attempt $i/3)..."
    sleep 5
done

# Pull latest state
log "Pulling latest..."
PULL_OUT=$(git pull --rebase 2>&1) || log "WARNING: git pull failed: $PULL_OUT"

PROMPT=$(cat "$PROMPT_FILE")

log "Invoking claude -p (${#PROMPT} chars)..."

# Run claude and capture output to log file directly
"$CLAUDE_BIN" -p "$PROMPT" \
    --model "$MODEL" \
    --max-budget-usd "$BUDGET" \
    --dangerously-skip-permissions \
    >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

log "claude exit code: $EXIT_CODE"

if [ "$EXIT_CODE" -ne 0 ]; then
    PENDING_DIR="$GAIA_DIR/.pending"
    mkdir -p "$PENDING_DIR"
    cat > "$PENDING_DIR/$TASK_NAME-$TIMESTAMP.md" <<EOF
---
task: $TASK_NAME
failed_at: $(date -Iseconds)
exit_code: $EXIT_CODE
log: scheduling/logs/$TASK_NAME-$TIMESTAMP.log
---

Task $TASK_NAME failed with exit code $EXIT_CODE.
Check the log file for details.
EOF
    log "Wrote failure record to .pending/"
fi

# Send Windows toast notification with result
notify() {
    local title="$1"
    local body="$2"
    powershell.exe -NoProfile -Command "
        Add-Type -AssemblyName System.Windows.Forms
        \$n = New-Object System.Windows.Forms.NotifyIcon
        \$n.Icon = [System.Drawing.SystemIcons]::Information
        \$n.BalloonTipTitle = '$title'
        \$n.BalloonTipText = '$body'
        \$n.Visible = \$true
        \$n.ShowBalloonTip(5000)
        Start-Sleep -Seconds 6
        \$n.Dispose()
    " 2>/dev/null &
}

if [ "$EXIT_CODE" -eq 0 ]; then
    notify "Gaia: $TASK_NAME" "Completed successfully"
else
    notify "Gaia: $TASK_NAME FAILED" "Check logs for details"
fi

log "=== Task complete ==="

# Prune logs older than 30 days
find "$LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
