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
OUTPUT_FILE="$LOG_DIR/$TASK_NAME-$TIMESTAMP.output"

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

# Capture claude output separately for notification content extraction
"$CLAUDE_BIN" -p "$PROMPT" \
    --model "$MODEL" \
    --max-budget-usd "$BUDGET" \
    --dangerously-skip-permissions \
    > "$OUTPUT_FILE" 2>&1

EXIT_CODE=$?

# Append claude output to main log
cat "$OUTPUT_FILE" >> "$LOG_FILE" 2>/dev/null
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

# Extract task-specific notification content
NOTIFY_TITLE="Gaia: $TASK_NAME"
NOTIFY_BODY="Completed."
EXTRACT_SCRIPT="$GAIA_DIR/scheduling/extract-notify-content.sh"
if [ -f "$EXTRACT_SCRIPT" ]; then
    NOTIFY_CONTENT=$("$EXTRACT_SCRIPT" "$TASK_NAME" "$OUTPUT_FILE" 2>/dev/null) || true
    if [ -n "$NOTIFY_CONTENT" ]; then
        eval "$NOTIFY_CONTENT"
    fi
fi

if [ "$EXIT_CODE" -ne 0 ]; then
    NOTIFY_TITLE="Gaia: $TASK_NAME FAILED"
    NOTIFY_BODY="Exit code $EXIT_CODE. Check scheduling/logs/."
fi

# Send Windows toast notification
powershell.exe -NoProfile -NonInteractive -File \
    "$GAIA_DIR/scheduling/notify-toast.ps1" \
    -Title "$NOTIFY_TITLE" \
    -Body "$NOTIFY_BODY" \
    >> "$LOG_FILE" 2>&1 || true

log "=== Task complete ==="

# Prune logs and output files older than 30 days
find "$LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
find "$LOG_DIR" -name "*.output" -mtime +30 -delete 2>/dev/null || true
