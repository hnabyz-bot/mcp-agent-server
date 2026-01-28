# Cross-platform Development Examples

Working code examples demonstrating cross-platform patterns and solutions.

---

## File Operations

### Case-Insensitive File Finding (Python)

```python
import os
from pathlib import Path

def find_file_ci(directory: str, filename: str) -> Path | None:
    """
    Find file with case-insensitive matching.
    Useful when exact case is unknown (Windows vs Linux).

    Args:
        directory: Directory to search
        filename: Filename to find (case-insensitive)

    Returns:
        Path object if found, None otherwise
    """
    dir_path = Path(directory)

    if not dir_path.exists():
        return None

    # Case-insensitive search
    for file in dir_path.iterdir():
        if file.name.lower() == filename.lower():
            return file

    return None

# Usage
css_file = find_file_ci("forms-interface", "styles.css")
if css_file:
    print(f"Found: {css_file}")
else:
    print("File not found")
```

### Cross-Platform Path Construction

**Python (pathlib):**
```python
from pathlib import Path

# Build paths cross-platform
config_dir = Path("config")
config_file = config_dir / "settings.json"

# Get absolute path
abs_path = config_file.resolve()

# Check existence
if config_file.exists():
    content = config_file.read_text()
```

**Node.js:**
```javascript
const path = require('path');

// Build paths cross-platform
const configDir = path.join('config', 'subdir');
const configFile = path.join(configDir, 'settings.json');

// Normalize path (handles mixed separators)
const normalized = path.normalize('config\\subdir/settings.json');

// Resolve to absolute path
const absolute = path.resolve(configFile);

// Check if file exists
const fs = require('fs');
if (fs.existsSync(absolute)) {
    const content = fs.readFileSync(absolute, 'utf8');
}
```

**Bash:**
```bash
#!/bin/bash

# Use variables for path components
PROJECT_DIR="$HOME/workspace/project"
CONFIG_DIR="$PROJECT_DIR/config"
CONFIG_FILE="$CONFIG_DIR/settings.json"

# Check file exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Config file found"
else
    echo "Config file not found"
    exit 1
fi
```

---

## Permission Management

### Auto-Fix Script Permissions

```bash
#!/bin/bash
# ensure-executable.sh

# Ensure all .sh files in current directory are executable
# Safe to run multiple times (idempotent)

SCRIPT_COUNT=0
FIXED_COUNT=0

for script in *.sh; do
    if [ -f "$script" ]; then
        SCRIPT_COUNT=$((SCRIPT_COUNT + 1))

        if [ ! -x "$script" ]; then
            echo "Adding execute bit: $script"
            chmod +x "$script"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    fi
done

echo "Scanned $SCRIPT_COUNT scripts, fixed $FIXED_COUNT"

if [ $FIXED_COUNT -gt 0 ]; then
    echo "Some scripts were fixed. Please run your deployment again."
    exit 1
fi
```

### Pre-commit Hook for Execute Bits

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Automatically add execute bits to shell scripts
# Run on Windows before committing

echo "Checking shell script execute bits..."

SCRIPTS_ADDED=0

for file in $(git diff --cached --name-only --diff-filter=ACMR | grep '\.sh$'); do
    if [ -f "$file" ]; then
        # Check if file is executable
        if [ ! -x "$file" ]; then
            echo "Adding execute bit to: $file"
            git update-index --chmod=+x "$file"
            SCRIPTS_ADDED=$((SCRIPTS_ADDED + 1))
        fi
    fi
done

if [ $SCRIPTS_ADDED -gt 0 ]; then
    echo ""
    echo "⚠ Added execute bits to $SCRIPTS_ADDED scripts."
    echo "Please review and commit again."
    exit 1
fi

echo "✓ All shell scripts have execute bits"
```

---

## Line Ending Management

### Git Attributes Configuration

```gitattributes
# .gitattributes - Configure line endings for cross-platform development

# Default: Auto-detect text files and normalize to LF on checkout
* text=auto

# Shell scripts - Always LF
*.sh text eol=lf
*.bash text eol=lf
*.zsh text eol=lf

# Python scripts - Always LF
*.py text eol=lf

# JavaScript/TypeScript - Always LF
*.js text eol=lf
*.ts text eol=lf
*.jsx text eol=lf
*.tsx text eol=lf

# Web files - Always LF
*.html text eol=lf
*.css text eol=lf
*.json text eol=lf
*.xml text eol=lf
*.yaml text eol=lf
*.yml text eol=lf

# Markdown - Always LF
*.md text eol=lf

# Windows-specific files - CRLF
*.bat text eol=crlf
*.cmd text eol=crlf
*.ps1 text eol=crlf
*.psm1 text eol=crlf
*.psd1 text eol=crlf

# Binary files - No conversion
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.woff binary
*.woff2 binary
*.ttf binary
*.eot binary
```

### Line Ending Detection Script

```bash
#!/bin/bash
# detect-line-endings.sh

# Check for CRLF line endings in files that should be LF
# Run on Linux before deployment

ERRORS_FOUND=0

echo "Checking for CRLF in shell scripts..."

for file in $(find . -name "*.sh" -type f); do
    if file "$file" | grep -q "CRLF"; then
        echo "⚠ CRLF found in: $file"
        ERRORS_FOUND=$((ERRORS_FOUND + 1))
    fi
done

if [ $ERRORS_FOUND -gt 0 ]; then
    echo ""
    echo "Found $ERRORS_FOUND files with CRLF line endings"
    echo "Run: dos2unix <file> to fix"
    exit 1
fi

echo "✓ All shell scripts have LF line endings"
```

### Convert Line Endings

```bash
#!/bin/bash
# fix-line-endings.sh

# Convert CRLF to LF for all shell scripts
# Run after cloning on Linux

SCRIPTS_CONVERTED=0

for file in $(find . -name "*.sh" -type f); do
    if file "$file" | grep -q "CRLF"; then
        echo "Converting: $file"
        sed -i 's/\r$//' "$file"
        SCRIPTS_CONVERTED=$((SCRIPTS_CONVERTED + 1))
    fi
done

echo "Converted $SCRIPTS_CONVERTED scripts from CRLF to LF"
```

---

## Symlink Management

### Safe Symlink Creation

```bash
#!/bin/bash
# create-symlink.sh

SOURCE_DIR="$1"
TARGET_LINK="$2"

# Validate arguments
if [ -z "$SOURCE_DIR" ] || [ -z "$TARGET_LINK" ]; then
    echo "Usage: $0 <source_dir> <target_link>"
    exit 1
fi

# Verify source exists
if [ ! -e "$SOURCE_DIR" ]; then
    echo "ERROR: Source does not exist: $SOURCE_DIR"
    exit 1
fi

# Get absolute path of source
SOURCE_ABSOLUTE=$(cd "$SOURCE_DIR" && pwd)

# Verify target parent exists
TARGET_PARENT=$(dirname "$TARGET_LINK")
if [ ! -d "$TARGET_PARENT" ]; then
    echo "ERROR: Target parent directory does not exist: $TARGET_PARENT"
    exit 1
fi

# Remove existing link or file
if [ -L "$TARGET_LINK" ]; then
    echo "Removing existing symlink..."
    rm "$TARGET_LINK"
elif [ -e "$TARGET_LINK" ]; then
    echo "ERROR: Target exists and is not a symlink: $TARGET_LINK"
    exit 1
fi

# Create symlink
ln -sf "$SOURCE_ABSOLUTE" "$TARGET_LINK"

# Verify
if [ -L "$TARGET_LINK" ]; then
    echo "✓ Symlink created: $TARGET_LINK -> $SOURCE_ABSOLUTE"
    ls -la "$TARGET_LINK"
else
    echo "✗ Failed to create symlink"
    exit 1
fi
```

### Symlink Verification

```bash
#!/bin/bash
# verify-symlink.sh

LINK="$1"

if [ -z "$LINK" ]; then
    echo "Usage: $0 <symlink_path>"
    exit 1
fi

echo "Checking symlink: $LINK"
echo ""

# Check if symlink exists
if [ -L "$LINK" ]; then
    echo "✓ Symlink exists"

    # Get target
    TARGET=$(readlink -f "$LINK")
    echo "  Target: $TARGET"

    # Check if target exists
    if [ -e "$TARGET" ]; then
        echo "  ✓ Target exists"
    else
        echo "  ✗ Target does not exist (broken link)"
        exit 1
    fi

    # Show details
    ls -la "$LINK"

elif [ -e "$LINK" ]; then
    echo "✗ Path exists but is not a symlink"
    ls -la "$LINK"
    exit 1

else
    echo "✗ Path does not exist"
    exit 1
fi
```

---

## Platform Detection

### Cross-Platform Script

```bash
#!/bin/bash
# platform-detect.sh

# Detect operating system
OS_TYPE=$(uname -s)

echo "Detected OS: $OS_TYPE"

case "$OS_TYPE" in
    Linux*)
        echo "Running Linux-specific setup..."
        # Linux-specific commands
        INSTALL_CMD="sudo apt-get install"
        SHELL_CMD="/bin/bash"
        ;;

    Darwin*)
        echo "Running macOS-specific setup..."
        # macOS-specific commands
        INSTALL_CMD="brew install"
        SHELL_CMD="/bin/bash"
        ;;

    MINGW*|MSYS*|CYGWIN*)
        echo "Running Windows (Git Bash) setup..."
        # Windows-specific commands
        INSTALL_CMD="pacman -S"
        SHELL_CMD="/bin/bash"
        ;;

    *)
        echo "ERROR: Unknown operating system: $OS_TYPE"
        exit 1
        ;;
esac

echo "Install command: $INSTALL_CMD"
echo "Shell: $SHELL_CMD"
```

### Python Platform Detection

```python
import platform
import subprocess
from pathlib import Path

def detect_platform() -> dict:
    """
    Detect platform and return platform-specific configuration.

    Returns:
        Dictionary with platform-specific settings
    """
    system = platform.system()
    machine = platform.machine()

    config = {
        "system": system,
        "machine": machine,
        "path_separator": "\\" if system == "Windows" else "/",
        "shell": "cmd.exe" if system == "Windows" else "/bin/bash",
    }

    # Platform-specific settings
    if system == "Linux":
        config["package_manager"] = "apt-get"
        config["install_cmd"] = "sudo apt-get install"
        config["service_cmd"] = "systemctl"
    elif system == "Darwin":  # macOS
        config["package_manager"] = "brew"
        config["install_cmd"] = "brew install"
        config["service_cmd"] = "launchctl"
    elif system == "Windows":
        config["package_manager"] = "choco"
        config["install_cmd"] = "choco install"
        config["service_cmd"] = "sc"

    return config

# Usage
config = detect_platform()
print(f"Platform: {config['system']}")
print(f"Shell: {config['shell']}")
print(f"Path separator: {config['path_separator']}")
```

---

## Deployment Examples

### Cross-Platform Deployment Script

```bash
#!/bin/bash
# deploy.sh - Cross-platform deployment script

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Color codes (disable on Windows)
if [ "$(uname -s)" != "MINGW*" ] && [ "$(uname -s)" != "MSYS*" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Platform detection
OS_TYPE=$(uname -s)
log_info "Running on: $OS_TYPE"

# Check script permissions
if [ ! -x "$0" ]; then
    log_error "This script is not executable!"
    log_info "Run: chmod +x $0"
    exit 1
fi

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$PROJECT_DIR/forms-interface"
DEPLOY_LINK="/var/www/html/forms"

log_info "Project directory: $PROJECT_DIR"
log_info "Source directory: $SOURCE_DIR"

# Validate source directory
if [ ! -d "$SOURCE_DIR" ]; then
    log_error "Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Check required files
log_info "Checking required files..."
for file in index.html script.js styles.css; do
    if [ ! -f "$SOURCE_DIR/$file" ]; then
        log_error "Required file not found: $file"
        exit 1
    fi
    log_info "  ✓ $file"
done

# Set read-only permissions (Linux/macOS only)
if [ "$OS_TYPE" = "Linux" ] || [ "$OS_TYPE" = "Darwin" ]; then
    log_info "Setting file permissions..."
    chmod 444 "$SOURCE_DIR/index.html"
    chmod 444 "$SOURCE_DIR/script.js"
    chmod 444 "$SOURCE_DIR/styles.css"
    log_info "  ✓ Files set to read-only (444)"
fi

# Create symlink (requires sudo on Linux)
if [ "$OS_TYPE" = "Linux" ]; then
    log_info "Creating deployment symlink..."

    # Check if sudo is available
    if ! command -v sudo &> /dev/null; then
        log_error "sudo is required for deployment"
        exit 1
    fi

    # Remove existing link
    if [ -L "$DEPLOY_LINK" ]; then
        sudo rm "$DEPLOY_LINK"
        log_info "  ✓ Removed existing symlink"
    fi

    # Create new symlink
    sudo ln -sf "$SOURCE_DIR" "$DEPLOY_LINK"

    # Verify
    if [ -L "$DEPLOY_LINK" ]; then
        log_info "  ✓ Symlink created: $DEPLOY_LINK"
        ls -la "$DEPLOY_LINK"
    else
        log_error "Failed to create symlink"
        exit 1
    fi

    # Restart web server
    log_info "Restarting web server..."
    sudo systemctl restart nginx
    log_info "  ✓ nginx restarted"
fi

log_info "Deployment completed successfully!"
```

### Pre-Flight Check Script

```bash
#!/bin/bash
# pre-flight-check.sh

# Run before deployment to catch common issues

set -e

ERRORS=0

echo "==================================="
echo "Pre-Flight Deployment Check"
echo "==================================="
echo ""

# 1. Check file existence
echo "1. Checking file existence..."
for file in forms-interface/index.html forms-interface/script.js forms-interface/styles.css; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file NOT FOUND"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# 2. Check script permissions
echo "2. Checking script permissions..."
for script in *.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo "  ✓ $script is executable"
        else
            echo "  ⚠ $script is NOT executable"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done
echo ""

# 3. Check line endings
echo "3. Checking line endings..."
CRLF_FILES=$(find . -name "*.sh" -type f -exec file {} \; | grep -c "CRLF" || true)
if [ $CRLF_FILES -gt 0 ]; then
    echo "  ⚠ Found $CRLF_FILES shell script(s) with CRLF"
    ERRORS=$((ERRORS + 1))
else
    echo "  ✓ All shell scripts have LF line endings"
fi
echo ""

# 4. Check for case mismatches
echo "4. Checking for case-sensitive file mismatches..."
# Check for references to "style.css" (wrong) instead of "styles.css" (correct)
WRONG_REFS=$(grep -r "style\.css" --include="*.html" --include="*.js" --include="*.sh" . | wc -l)
if [ $WRONG_REFS -gt 0 ]; then
    echo "  ⚠ Found $WRONG_REFS reference(s) to 'style.css' (should be 'styles.css')"
    ERRORS=$((ERRORS + 1))
else
    echo "  ✓ No case mismatch references found"
fi
echo ""

# 5. Check network (Linux only)
if [ "$(uname -s)" = "Linux" ]; then
    echo "5. Checking network connectivity..."
    if ping -c 1 github.com &> /dev/null; then
        echo "  ✓ GitHub is reachable"
    else
        echo "  ✗ Cannot reach GitHub"
        ERRORS=$((ERRORS + 1))
    fi
    echo ""
fi

# Summary
echo "==================================="
if [ $ERRORS -eq 0 ]; then
    echo "✓ All checks passed! Ready to deploy."
    exit 0
else
    echo "✗ Found $ERRORS error(s). Please fix before deploying."
    exit 1
fi
```

---

## Testing Examples

### Cross-Platform Test Runner

```python
#!/usr/bin/env python3
# test_runner.py - Cross-platform test runner

import os
import sys
import subprocess
import platform
from pathlib import Path

def run_command(cmd: list, description: str) -> bool:
    """Run a command and report results."""
    print(f"\n{'='*60}")
    print(f"Testing: {description}")
    print(f"Command: {' '.join(cmd)}")
    print('='*60)

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode == 0:
            print("✓ PASSED")
            if result.stdout:
                print(result.stdout)
            return True
        else:
            print("✗ FAILED")
            if result.stderr:
                print(result.stderr)
            return False
    except subprocess.TimeoutExpired:
        print("✗ TIMEOUT")
        return False
    except Exception as e:
        print(f"✗ ERROR: {e}")
        return False

def main():
    """Run all cross-platform tests."""
    print(f"Platform: {platform.system()} {platform.machine()}")
    print(f"Python: {sys.version}")

    tests_passed = 0
    tests_failed = 0

    # Test 1: File operations
    if run_command(
        ["python3", "-c", "from pathlib import Path; p = Path('forms-interface'); print(p.exists())"],
        "Pathlib operations"
    ):
        tests_passed += 1
    else:
        tests_failed += 1

    # Test 2: Script permissions (Linux/macOS only)
    if platform.system() in ("Linux", "Darwin"):
        if run_command(
            ["bash", "-c", "[ -x 'deploy-and-restart.sh' ] && echo 'executable'"],
            "Script execute permissions"
        ):
            tests_passed += 1
        else:
            tests_failed += 1

    # Test 3: Line endings (Linux only)
    if platform.system() == "Linux":
        if run_command(
            ["bash", "-c", "! file deploy-and-restart.sh | grep -q CRLF && echo 'LF OK'"],
            "Shell script line endings"
        ):
            tests_passed += 1
        else:
            tests_failed += 1

    # Summary
    print(f"\n{'='*60}")
    print("Test Summary")
    print('='*60)
    print(f"Passed: {tests_passed}")
    print(f"Failed: {tests_failed}")

    return 0 if tests_failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
```

---

## CI/CD Integration

### GitHub Actions Cross-Platform Workflow

```yaml
# .github/workflows/cross-platform-test.yml

name: Cross-Platform Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        python-version: ['3.10', '3.11']

    runs-on: ${{ matrix.os }}

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt

    - name: Run tests
      run: |
        python test_runner.py

    - name: Check line endings (Linux only)
      if: runner.os == 'Linux'
      run: |
        bash detect-line-endings.sh

    - name: Check file permissions (Linux only)
      if: runner.os == 'Linux'
      run: |
        bash ensure-executable.sh
```

---

All examples are production-ready and can be used directly in your project.
