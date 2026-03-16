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

set -euo pipefail

TASK_NAME="${1:?Usage: run-task.sh <task-name> [model] [budget]}"
MODEL="${2:-sonnet}"
BUDGET="${3:-2.00}"

GAIA_DIR="C:/GitHub/Gaia"
PROMPT_FILE="$GAIA_DIR/scheduling/prompts/$TASK_NAME.md"
LOG_DIR="$GAIA_DIR/scheduling/logs"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
LOG_FILE="$LOG_DIR/$TASK_NAME-$TIMESTAMP.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Gaia Task: $TASK_NAME ==="
echo "Started: $(date -Iseconds)"
echo "Model: $MODEL | Budget: \$$BUDGET"
echo "---"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "ERROR: Prompt file not found: $PROMPT_FILE"
    exit 1
fi

cd "$GAIA_DIR" || exit 1

# Pull latest state before running
echo "Pulling latest..."
git pull --rebase 2>&1 || echo "WARNING: git pull failed, continuing with local state"

PROMPT=$(cat "$PROMPT_FILE")

echo "Invoking Claude Code CLI..."
claude -p "$PROMPT" \
    --model "$MODEL" \
    --max-budget-usd "$BUDGET" \
    --dangerously-skip-permissions \
    2>&1

EXIT_CODE=${PIPESTATUS[0]:-$?}

echo "---"
echo "Finished: $(date -Iseconds)"
echo "Exit code: $EXIT_CODE"

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

Task $TASK_NAME failed. Check the log file for details.
EOF
    echo "Wrote failure record to .pending/$TASK_NAME-$TIMESTAMP.md"
fi

# Prune logs older than 30 days
find "$LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
