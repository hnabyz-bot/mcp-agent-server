# Cross-platform Failure Patterns

Detailed analysis of common cross-platform development failure patterns with systematic prevention strategies.

## Pattern 1: Case Sensitivity Mismatch

**Symptom:**
```
chmod: cannot access 'forms-interface/style.css': No such file or directory
```

**Root Cause:**
- Actual file: `styles.css` (with 's')
- Code references: `style.css` (without 's')
- Windows doesn't detect difference, Linux fails

**Detection:**
```bash
# On Linux: Find case mismatches
cd forms-interface
ls -la *.css  # Shows actual filename: styles.css

# Search code for wrong references
grep -r "style\.css" --include="*.{html,js,sh,py}"
# Output: Shows files referencing "style.css" (wrong)
```

**Prevention Workflow:**
```bash
#!/bin/bash
# pre-commit-check.sh

echo "Checking for case-sensitive file references..."

# Get list of actual files
find forms-interface -type f | sort > /tmp/actual_files.txt

# Get list of referenced files in code
grep -roh 'forms-interface/[^"'"'"']\+' --include="*.html" --include="*.js" --include="*.sh" | \
    sort -u > /tmp/referenced_files.txt

# Compare
while read -r ref; do
    if ! grep -qx "$ref" /tmp/actual_files.txt; then
        echo "⚠ Reference not found: $ref"
    fi
done < /tmp/referenced_files.txt
```

**Systematic Fix:**
```bash
# 1. Identify all incorrect references
grep -r "style\.css" --include="*.html" --include="*.js" --include="*.sh" -l

# 2. Replace with correct filename (case-sensitive)
find . -type f \( -name "*.html" -o -name "*.js" -o -name "*.sh" \) -exec sed -i 's/style\.css/styles.css/g' {} +

# 3. Verify fix
grep -r "styles\.css" --include="*.html" --include="*.js" --include="*.sh"
```

## Pattern 2: Lost Execute Permissions

**Symptom:**
```
sudo-rs: cannot execute '/home/user/deploy-and-restart.sh': Permission denied
```

**Root Cause:**
- Git commits on Windows lose execute bit
- `git pull` on Linux doesn't restore permissions
- Windows filesystem doesn't store Unix execute bits

**Prevention Method 1: Git Configuration**
```bash
# On Linux: After creating new script
chmod +x deploy-and-restart.sh
git add deploy-and-restart.sh
git update-index --chmod=+x deploy-and-restart.sh
git commit -m "Add deployment script with execute bit"

# Verify execute bit is tracked
git ls-files --stage deploy-and-restart.sh
# Output includes mode: 100755 (executable)
```

**Prevention Method 2: Deployment Script Self-Healing**
```bash
#!/bin/bash
# deploy-and-restart.sh

# Self-check: Ensure this script is executable
if [ ! -x "$0" ]; then
    echo "ERROR: This script is not executable!"
    echo "Run: chmod +x $0"
    exit 1
fi

# Or auto-fix (requires restart)
if [ ! -x "$0" ]; then
    echo "Script not executable. Adding execute bit..."
    chmod +x "$0"
    echo "Please run the script again."
    exit 1
fi
```

**Prevention Method 3: Pre-deploy Check Script**
```bash
#!/bin/bash
# pre-deploy-verify.sh

echo "Checking script permissions..."

FAILED=0
for script in *.sh; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        echo "⚠ $script is not executable"
        chmod +x "$script"
        echo "✓ Fixed: chmod +x $script"
        FAILED=1
    fi
done

if [ $FAILED -eq 1 ]; then
    echo ""
    echo "Permissions were fixed. Please run deployment again."
    exit 1
fi

echo "✓ All scripts are executable"
```

## Pattern 3: Line Ending Corruption

**Symptom:**
```
/bin/bash^M: bad interpreter: No such file or directory
```

**Root Cause:**
- Script created on Windows with CRLF line endings
- Linux shebang (`#!/bin/bash`) becomes `#!/bin/bash\r\n`
- Linux tries to execute `/bin/bash^M` (literal Ctrl-M)

**Detection:**
```bash
# Check for CRLF
file script.sh
# Output: "ASCII text, with CRLF line terminators"

# Show non-printable characters
cat -A script.sh | head -1
# Output: #!/bin/bash^M$
```

**Prevention - Git Configuration (.gitattributes):**
```
# Auto-detect and convert line endings
* text=auto

# Shell scripts must use LF
*.sh text eol=lf

# Python scripts must use LF
*.py text eol=lf

# JavaScript/HTML/CSS use LF
*.js text eol=lf
*.html text eol=lf
*.css text eol=lf

# Windows batch files use CRLF
*.bat text eol=crlf
*.ps1 text eol=crlf
```

**Fix Existing Repository:**
```bash
# 1. Add .gitattributes
echo "*.sh text eol=lf" >> .gitattributes
echo "*.py text eol=lf" >> .gitattributes
echo "*.js text eol=lf" >> .gitattributes

# 2. Normalize all files
git add --renormalize .

# 3. Commit
git commit -m "Normalize line endings"
```

**Fix Individual Files:**
```bash
# Convert CRLF to LF
dos2unix script.sh

# Or using sed (no dos2unix required)
sed -i 's/\r$//' script.sh

# Verify fix
file script.sh
# Output: "ASCII text" (no CRLF)
```

## Pattern 4: Path Separator Incompatibility

**Symptom:**
- Scripts work on one platform, fail on another
- File not found errors when paths are hardcoded

**Root Cause:**
- Hardcoded `\` or `/` separators
- String concatenation instead of path joining

**Detection:**
```bash
# Search for hardcoded separators
grep -r '\\\\' --include="*.py" --include="*.js"
grep -r '\\"' --include="*.py" --include="*.js"
```

**Prevention Python:**
```python
# WRONG
path = "forms-interface\\styles.css"  # Windows-only
path = "forms-interface/styles.css"  # Linux-only

# CORRECT
from pathlib import Path
path = Path("forms-interface") / "styles.css"

# Or
import os
path = os.path.join("forms-interface", "styles.css")
```

**Prevention Node.js:**
```javascript
// WRONG
const path = 'forms-interface\\styles.css';  // Windows-only
const path = 'forms-interface/styles.css';   // Linux-only

// CORRECT
const path = require('path');
const filePath = path.join('forms-interface', 'styles.css');
```

**Prevention Bash:**
```bash
# WRONG (works on Linux only)
FILE="forms-interface/styles.css"

# CORRECT (works on both)
FILE="forms-interface/styles.css"  # Bash handles / on Windows too

# Use variables for directories
DIR="forms-interface"
FILE="styles.css"
FULL_PATH="$DIR/$FILE"
```

## Pattern 5: Symlink Creation Failures

**Symptom:**
```
ln: failed to create symbolic link '/var/www/html/forms': Permission denied
```

**Root Cause:**
- Creating symlinks in system directories requires privileges
- Windows symlinks require Developer Mode or Admin rights
- Target directory doesn't exist

**Prevention Script:**
```bash
#!/bin/bash
# deploy-and-restart.sh

SOURCE_DIR="/home/user/project/forms-interface"
TARGET_LINK="/var/www/html/forms"

# 1. Verify source exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# 2. Verify target parent exists
TARGET_PARENT=$(dirname "$TARGET_LINK")
if [ ! -d "$TARGET_PARENT" ]; then
    echo "ERROR: Target parent directory not found: $TARGET_PARENT"
    exit 1
fi

# 3. Remove existing link if present
if [ -L "$TARGET_LINK" ]; then
    echo "Removing existing symlink..."
    sudo rm "$TARGET_LINK"
fi

# 4. Create new symlink
sudo ln -sf "$SOURCE_DIR" "$TARGET_LINK"

# 5. Verify
if [ -L "$TARGET_LINK" ]; then
    echo "✓ Symlink created successfully"
    ls -la "$TARGET_LINK"
else
    echo "✗ Failed to create symlink"
    exit 1
fi
```
