#!/bin/bash
# Session State Save Script
# Saves current work state to JSON file for session recovery

SESSION_STATE_FILE=".claude/session_state.json"
PROJECT_DIR="$(pwd)"

# Get current timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ISO_TIMESTAMP=$(date -Iseconds)

# Check if state file exists, load it
if [ -f "$SESSION_STATE_FILE" ]; then
    EXISTING_STATE=$(cat "$SESSION_STATE_FILE")
else
    EXISTING_STATE="{}"
fi

# Parse command line arguments
COMMAND=${1:-"help"}

case "$COMMAND" in
    save)
        # Save session state
        # Usage: ./session-save.sh save "current task description"
        CURRENT_TASK="$2"
        shift 2

        # Build JSON
        cat > "$SESSION_STATE_FILE" <<EOF
{
  "timestamp": "$ISO_TIMESTAMP",
  "last_updated": "$TIMESTAMP",
  "project_dir": "$PROJECT_DIR",
  "current_task": "$CURRENT_TASK",
  "last_action": "${@}",
  "session_type": "development"
}
EOF

        echo "✓ Session state saved"
        echo "  Task: $CURRENT_TASK"
        echo "  Time: $TIMESTAMP"
        ;;

    update-todo)
        # Update todo list
        # Usage: ./session-save.sh update-todo "completed|pending|in_progress" "task description"
        STATUS="$2"
        CONTENT="$3"

        # Read existing state
        if [ -f "$SESSION_STATE_FILE" ]; then
            # Add todo item (simplified - in production use jq)
            echo "⚠ Todo update: [$STATUS] $CONTENT"
            echo "  (Consider manually editing $SESSION_STATE_FILE)"
        fi
        ;;

    complete)
        # Mark task as completed
        TASK="$2"

        if [ -f "$SESSION_STATE_FILE" ]; then
            # Update last_action
            TEMP_FILE=$(mktemp)
            jq --arg task "$TASK" '.last_action = "Completed: \($task)"' "$SESSION_STATE_FILE" > "$TEMP_FILE"
            mv "$TEMP_FILE" "$SESSION_STATE_FILE"

            # Update timestamp
            TEMP_FILE=$(mktemp)
            jq --arg time "$TIMESTAMP" --arg iso "$ISO_TIMESTAMP" \
                '.last_updated = $time | .timestamp = $iso' \
                "$SESSION_STATE_FILE" > "$TEMP_FILE"
            mv "$TEMP_FILE" "$SESSION_STATE_FILE"

            echo "✓ Task completed: $TASK"
        fi
        ;;

    load|show)
        # Load and display session state
        if [ ! -f "$SESSION_STATE_FILE" ]; then
            echo "ℹ No saved session state found"
            exit 0
        fi

        echo ""
        echo "==================================="
        echo "📋 Saved Session State"
        echo "==================================="
        echo ""

        # Display using jq if available
        if command -v jq &> /dev/null; then
            jq -r '[
                "📅 Last Updated: \(.last_updated)",
                "🎯 Current Task: \(.current_task)",
                "",
                "✓ Last Action: \(.last_action)",
                "",
                "📁 Project: \(.project_dir)"
            ] | join("\n")' "$SESSION_STATE_FILE"

            # Display todos if exist
            if jq -e '.todo_list' "$SESSION_STATE_FILE" > /dev/null 2>&1; then
                echo ""
                echo "Todo List:"
                jq -r '.todo_list[]? | "  \(.status // "pending") | \(.content)"' "$SESSION_STATE_FILE"
            fi
        else
            # Fallback to cat
            cat "$SESSION_STATE_FILE"
        fi

        echo ""
        echo "==================================="
        ;;

    clear)
        # Clear session state
        rm -f "$SESSION_STATE_FILE"
        echo "✓ Session state cleared"
        ;;

    summary)
        # Show brief summary
        if [ ! -f "$SESSION_STATE_FILE" ]; then
            echo "ℹ No active session"
            exit 0
        fi

        if command -v jq &> /dev/null; then
            TASK=$(jq -r '.current_task // "Unknown"' "$SESSION_STATE_FILE")
            UPDATED=$(jq -r '.last_updated // "Unknown"' "$SESSION_STATE_FILE")
            echo "🎯 $TASK (updated: $UPDATED)"
        else
            echo "ℹ Session state exists at $SESSION_STATE_FILE"
        fi
        ;;

    help|*)
        echo "Session State Management Script"
        echo ""
        echo "Usage: ./session-save.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  save <task> [action]    Save session state with current task"
        echo "  complete <task>         Mark task as completed"
        echo "  load|show               Display saved session state"
        echo "  summary                 Show brief summary"
        echo "  clear                   Clear session state"
        echo ""
        echo "Examples:"
        echo "  ./session-save.sh save '배포 자동화 구현' 'deploy-and-restart.sh 작성 완료'"
        echo "  ./session-save.sh complete '파일명 불일치 수정'"
        echo "  ./session-save.sh show"
        echo ""
        ;;
esac
