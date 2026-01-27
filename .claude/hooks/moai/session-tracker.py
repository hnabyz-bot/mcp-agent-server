#!/usr/bin/env python3
"""
Session Tracker Hook - Saves work context to Memory MCP
This hook runs after each tool use to maintain work continuity
"""

import json
import os
from datetime import datetime

def main():
    # Current session context
    context = {
        "last_updated": datetime.now().isoformat(),
        "current_task": "forms_email_field_fix",
        "task_status": "deployed_testing",
        "problem": "Email field missing from webhook payload",
        "solution": "Added email field to script.js, deployed to /var/www/html/forms/",
        "next_steps": [
            "Verify script.js has email field on Raspberry Pi",
            "Clear browser cache (Ctrl+Shift+R)",
            "Test form submission",
            "Check n8n SMTP credentials"
        ],
        "deployment": {
            "server": "nginx",
            "path": "/var/www/html/forms",
            "url": "https://forms.abyz-lab.work"
        },
        "files_modified": [
            "forms-interface/script.js"
        ],
        "commit": "8c536d8"
    }
    
    # Save to file for reference
    context_file = "/tmp/claude_session_context.json"
    with open(context_file, 'w') as f:
        json.dump(context, f, indent=2)
    
    print(f"Session context saved to {context_file}")
    print(json.dumps(context, indent=2))

if __name__ == "__main__":
    main()
