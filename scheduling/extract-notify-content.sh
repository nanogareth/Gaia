#!/bin/bash
# Extract task-specific notification content from Gaia state files.
# Usage: extract-notify-content.sh <task-name> [output-file]
# Outputs NOTIFY_TITLE and NOTIFY_BODY as shell variable assignments.

TASK_NAME="${1:?}"
OUTPUT_FILE="${2:-}"
GAIA_DIR="C:/GitHub/Gaia"
GAM_FILE="$GAIA_DIR/temporal/gamification.json"
TODAY_FILE="$GAIA_DIR/temporal/today.md"

# JSON field reader — uses jq if available, falls back to py
json_field() {
    local file="$1" field="$2"
    if command -v jq > /dev/null 2>&1; then
        jq -r ".$field // empty" "$file" 2>/dev/null
    else
        py -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get(sys.argv[2],''))" "$file" "$field" 2>/dev/null
    fi
}

# Extract #1 priority text from today.md
get_priority() {
    if [ -f "$TODAY_FILE" ]; then
        grep -m1 '^1\.' "$TODAY_FILE" 2>/dev/null | sed 's/^1\.\s*//' | sed 's/\*\*\[[^]]*\]\*\*\s*//' | cut -c1-80
    fi
}

# Read gamification stats
STREAK=$(json_field "$GAM_FILE" "current_streak" 2>/dev/null || echo "0")
XP=$(json_field "$GAM_FILE" "xp" 2>/dev/null || echo "0")
LEVEL_NAME=$(json_field "$GAM_FILE" "level_name" 2>/dev/null || echo "")
PRIORITY=$(get_priority)

# Strip single quotes, backticks, newlines for shell safety
sanitize() { echo "$1" | tr "'\`\n\r" '    '; }

case "$TASK_NAME" in
    morning-plan)
        NOTIFY_TITLE="Gaia: Morning Plan"
        NOTIFY_BODY="#1: $(sanitize "${PRIORITY:-Check today.md}"). Streak: ${STREAK}d. XP: ${XP}."
        ;;
    micro-commit)
        MICRO=""
        if [ -f "$TODAY_FILE" ]; then
            MICRO=$(grep -A1 '\*\*Start here:\*\*' "$TODAY_FILE" 2>/dev/null | head -1 | sed 's/.*\*\*Start here:\*\*\s*//' | cut -c1-80)
        fi
        NOTIFY_TITLE="Gaia: 5-min Start"
        NOTIFY_BODY="$(sanitize "${MICRO:-Check today.md for your micro-commitment}")"
        ;;
    noon-check)
        if [ -n "$OUTPUT_FILE" ] && [ -f "$OUTPUT_FILE" ]; then
            FIRST_LINE=$(head -1 "$OUTPUT_FILE" 2>/dev/null)
            case "$FIRST_LINE" in
                ON\ TRACK*)
                    NOTIFY_TITLE="Gaia: On Track"
                    NOTIFY_BODY="$(sanitize "$(head -c 120 "$OUTPUT_FILE")")"
                    ;;
                *)
                    NOTIFY_TITLE="Gaia: Noon — Act Now"
                    NOTIFY_BODY="#1: $(sanitize "${PRIORITY:-Check today.md}"). Streak at risk (${STREAK}d)."
                    ;;
            esac
        else
            NOTIFY_TITLE="Gaia: Noon Check"
            NOTIFY_BODY="Streak: ${STREAK}d. ${LEVEL_NAME}."
        fi
        ;;
    evening-reflect)
        NOTIFY_TITLE="Gaia: Evening Done"
        NOTIFY_BODY="Streak: ${STREAK}d. XP: ${XP} (${LEVEL_NAME})."
        ;;
    *)
        NOTIFY_TITLE="Gaia: ${TASK_NAME}"
        NOTIFY_BODY="Report generated."
        ;;
esac

echo "NOTIFY_TITLE='${NOTIFY_TITLE}'"
echo "NOTIFY_BODY='${NOTIFY_BODY}'"
