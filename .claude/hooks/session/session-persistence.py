#!/usr/bin/env python3
"""
Session Persistence Hook for Claude Code
Automatically saves and restores session context to prevent work loss
"""

import os
import json
from datetime import datetime
from pathlib import Path

# Session state file
SESSION_STATE_FILE = Path(".claude/session_state.json")

def save_session_state(context):
    """
    Save current session state to file
    Called automatically after each major task completion

    Args:
        context: Dictionary containing session context
            - current_task: Task being worked on
            - todo_list: Current todo items
            - last_action: Last completed action
            - next_steps: Planned next steps
            - notes: Additional notes
    """
    try:
        # Add timestamp
        context['timestamp'] = datetime.now().isoformat()
        context['last_updated'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # Save to file
        SESSION_STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(SESSION_STATE_FILE, 'w', encoding='utf-8') as f:
            json.dump(context, f, indent=2, ensure_ascii=False)

        print(f"✓ Session state saved to {SESSION_STATE_FILE}")
        return True

    except Exception as e:
        print(f"✗ Failed to save session state: {e}")
        return False


def load_session_state():
    """
    Load saved session state from file
    Called automatically at session start

    Returns:
        Dictionary containing saved session state, or None if not found
    """
    try:
        if not SESSION_STATE_FILE.exists():
            print(f"ℹ No saved session state found at {SESSION_STATE_FILE}")
            return None

        with open(SESSION_STATE_FILE, 'r', encoding='utf-8') as f:
            state = json.load(f)

        print(f"✓ Session state loaded from {SESSION_STATE_FILE}")
        print(f"  Last updated: {state.get('last_updated', 'Unknown')}")
        print(f"  Current task: {state.get('current_task', 'Unknown')}")

        return state

    except Exception as e:
        print(f"✗ Failed to load session state: {e}")
        return None


def clear_session_state():
    """Clear saved session state"""
    try:
        if SESSION_STATE_FILE.exists():
            SESSION_STATE_FILE.unlink()
            print(f"✓ Session state cleared")
            return True
        else:
            print(f"ℹ No session state to clear")
            return True
    except Exception as e:
        print(f"✗ Failed to clear session state: {e}")
        return False


def format_session_summary(state):
    """
    Format session state as human-readable summary

    Args:
        state: Session state dictionary

    Returns:
        Formatted string summary
    """
    if not state:
        return "No session state available"

    summary = []
    summary.append("=" * 60)
    summary.append("Session State Summary")
    summary.append("=" * 60)
    summary.append("")

    # Last updated
    if 'last_updated' in state:
        summary.append(f"📅 Last Updated: {state['last_updated']}")
        summary.append("")

    # Current task
    if 'current_task' in state:
        summary.append(f"🎯 Current Task: {state['current_task']}")
        summary.append("")

    # Todo list
    if 'todo_list' in state and state['todo_list']:
        summary.append("📋 Todo List:")
        for i, item in enumerate(state['todo_list'], 1):
            status = item.get('status', 'pending')
            content = item.get('content', 'Unknown')
            status_symbol = {
                'pending': '⏳',
                'in_progress': '🔄',
                'completed': '✅'
            }.get(status, '❓')
            summary.append(f"  {i}. {status_symbol} {content}")
        summary.append("")

    # Last action
    if 'last_action' in state:
        summary.append(f"✓ Last Action: {state['last_action']}")
        summary.append("")

    # Next steps
    if 'next_steps' in state and state['next_steps']:
        summary.append("➡️  Next Steps:")
        for step in state['next_steps']:
            summary.append(f"  • {step}")
        summary.append("")

    # Notes
    if 'notes' in state and state['notes']:
        summary.append("📝 Notes:")
        for note in state['notes']:
            summary.append(f"  • {note}")
        summary.append("")

    summary.append("=" * 60)

    return "\n".join(summary)


if __name__ == "__main__":
    # CLI interface for manual operations
    import sys

    if len(sys.argv) < 2:
        print("Usage: python session-persistence.py {load|save|clear|summary}")
        sys.exit(1)

    command = sys.argv[1].lower()

    if command == "load":
        state = load_session_state()
        if state:
            print("\n" + format_session_summary(state))

    elif command == "save":
        # Example save
        context = {
            "current_task": "Example task",
            "todo_list": [
                {"content": "Task 1", "status": "completed"},
                {"content": "Task 2", "status": "in_progress"}
            ],
            "last_action": "Completed Task 1",
            "next_steps": ["Complete Task 2", "Start Task 3"],
            "notes": ["Example note"]
        }
        save_session_state(context)

    elif command == "clear":
        clear_session_state()

    elif command == "summary":
        state = load_session_state()
        if state:
            print("\n" + format_session_summary(state))

    else:
        print(f"Unknown command: {command}")
        print("Available commands: load, save, clear, summary")
        sys.exit(1)
