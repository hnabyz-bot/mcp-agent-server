# Cross-platform Best Practices

Comprehensive best practices for developing cross-platform applications that work seamlessly across Windows and Linux.

## Development Workflow

### 1. Development Environment

**Use WSL (Windows Subsystem for Linux) on Windows:**
- Provides Linux-like testing environment on Windows
- Allows testing shell scripts with LF line endings
- Catches case sensitivity issues early

**Use Docker Containers:**
- Provides consistent Linux environment across all platforms
- Eliminates "works on my machine" issues
- Enables testing actual deployment environment locally

**Test on Actual Target Platform:**
- Always test on the target platform before deployment
- Use staging environments that mirror production
- Validate in same OS version as production

### 2. Pre-commit Checks

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "=== Cross-platform Pre-commit Checks ==="

# Check for case-sensitive file mismatches
echo "Checking filename consistency..."
find . -type f -name "*.css" -o -name "*.js" -o -name "*.html" | while read file; do
    basename=$(basename "$file")
    if grep -r "$(basename "$file" | sed 's/s\.css/css/')" --include="*.html" --include="*.js" .; then
        echo "⚠ Potential case mismatch: $basename"
    fi
done

# Check for CRLF in shell scripts
echo "Checking line endings in shell scripts..."
file *.sh 2>/dev/null | grep CRLF && {
    echo "✗ CRLF detected in shell scripts"
    echo "Run: dos2unix *.sh"
    exit 1
}

# Verify execute bits on .sh files
echo "Checking execute permissions..."
for file in $(git diff --cached --name-only | grep '\.sh$'); do
    if [ -f "$file" ]; then
        git update-index --chmod=+x "$file"
        echo "✓ Added execute bit to $file"
    fi
done

# Validate path construction
echo "Checking for hardcoded path separators..."
if grep -r '\\\\' --include="*.py" --include="*.js" .; then
    echo "⚠ Hardcoded backslashes found"
    echo "Use pathlib (Python) or path.join (Node.js)"
fi

echo "✓ All pre-commit checks passed"
```

### 3. Pre-deployment Verification

Create `pre-deploy-check.sh`:
```bash
#!/bin/bash
# pre-deploy-check.sh

echo "=== Cross-platform Pre-deployment Validation ==="

# 1. File existence check
echo "Checking core files..."
for file in forms-interface/index.html forms-interface/script.js forms-interface/styles.css; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file NOT FOUND"
        exit 1
    fi
done

# 2. Script permissions check
echo ""
echo "Checking script permissions..."
NON_EXEC=$(ls -la *.sh 2>/dev/null | grep -v "^-rwxr-xr-x" | grep -v "^total")
if [ -n "$NON_EXEC" ]; then
    echo "⚠ Non-executable scripts found:"
    echo "$NON_EXEC"
    echo "Fixing..."
    chmod +x *.sh
    echo "✓ Permissions fixed"
else
    echo "✓ All scripts are executable"
fi

# 3. Line ending check
echo ""
echo "Checking line endings..."
CRLF_FILES=$(file *.sh 2>/dev/null | grep CRLF | cut -d: -f1)
if [ -n "$CRLF_FILES" ]; then
    echo "⚠ CRLF detected in shell scripts:"
    echo "$CRLF_FILES"
    echo "Fixing..."
    echo "$CRLF_FILES" | xargs dos2unix
    echo "✓ Line endings fixed"
else
    echo "✓ All shell scripts use LF"
fi

# 4. Path reference check
echo ""
echo "Checking for hardcoded backslashes..."
if grep -r '\\\\' --include="*.py" --include="*.js" . 2>/dev/null; then
    echo "⚠ Hardcoded backslashes found"
    echo "Use pathlib (Python) or path.join (Node.js)"
    exit 1
else
    echo "✓ No hardcoded path separators"
fi

# 5. Filename consistency check
echo ""
echo "Checking filename consistency..."
ACTUAL_CSS=$(ls forms-interface/*.css 2>/dev/null | xargs -n1 basename)
REFERENCED_CSS=$(grep -o '[a-zA-Z_-]*\.css' forms-interface/index.html 2>/dev/null | sort -u)
if [ "$ACTUAL_CSS" != "$REFERENCED_CSS" ]; then
    echo "⚠ Filename mismatch detected"
    echo "Actual: $ACTUAL_CSS"
    echo "Referenced: $REFERENCED_CSS"
    exit 1
else
    echo "✓ Filenames are consistent"
fi

echo ""
echo "=== All validations passed! Ready to deploy. ==="
```

## Defensive Programming

### 1. File Existence Checks

**Always check before file operations:**
```bash
# Good: Defensive check
if [ -f "$FILE" ]; then
    chmod 444 "$FILE"
else
    log_error "File not found: $FILE"
    exit 1
fi

# Bad: Assume file exists
chmod 444 forms-interface/styles.css
```

**Python version:**
```python
from pathlib import Path

file_path = Path("forms-interface/styles.css")
if file_path.exists():
    file_path.chmod(0o444)
else:
    log_error(f"File not found: {file_path}")
    sys.exit(1)
```

**Node.js version:**
```javascript
const fs = require('fs');
const path = require('path');

const filePath = path.join('forms-interface', 'styles.css');
if (fs.existsSync(filePath)) {
    fs.chmodSync(filePath, 0o444);
} else {
    log_error(`File not found: ${filePath}`);
    process.exit(1);
}
```

### 2. Permission Verification

**Check execute permissions before running:**
```bash
# Good: Verify before execute
if [ -x "$SCRIPT" ]; then
    ./"$SCRIPT"
else
    log_error "Script not executable: $SCRIPT"
    chmod +x "$SCRIPT"
    echo "Please run the script again."
    exit 1
fi

# Bad: Assume executable
./deploy-and-restart.sh
```

### 3. Error Handling

**Fail fast on errors:**
```bash
# Enable strict error handling
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Trap errors for cleanup
trap 'rollback_on_error' ERR

rollback_on_error() {
    echo "Deployment failed. Rolling back..."
    # Rollback logic here
    exit 1
}
```

**Python version:**
```python
import sys

try:
    # Deployment logic
    deploy()
except FileNotFoundError as e:
    log_error(f"File not found: {e}")
    sys.exit(1)
except PermissionError as e:
    log_error(f"Permission denied: {e}")
    sys.exit(1)
except Exception as e:
    log_error(f"Unexpected error: {e}")
    rollback()
    sys.exit(1)
```

## Platform Detection

### Bash Platform Detection

```bash
#!/bin/bash

# Detect platform
OS_TYPE=$(uname -s)

case "$OS_TYPE" in
    Linux*)
        echo "Running on Linux"
        # Linux-specific commands
        PKG_MANAGER="apt"
        ;;
    Darwin*)
        echo "Running on macOS"
        # macOS-specific commands
        PKG_MANAGER="brew"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "Running on Windows (Git Bash)"
        # Windows-specific adjustments
        PKG_MANAGER="choco"
        # Use forward slashes even on Windows
        ;;
    *)
        echo "Unknown OS: $OS_TYPE"
        exit 1
        ;;
esac
```

### Python Platform Detection

```python
import platform
import sys

def get_platform_info():
    """Get platform-specific information"""
    system = platform.system()
    machine = platform.machine()
    python_version = sys.version_info

    return {
        'os': system,
        'arch': machine,
        'python': f"{python_version.major}.{python_version.minor}",
        'path_separator': '\\' if system == 'Windows' else '/'
    }

info = get_platform_info()

if info['os'] == "Linux":
    # Linux-specific code
    print("Running on Linux")
elif info['os'] == "Windows":
    # Windows-specific code
    print("Running on Windows")
    # Use pathlib for cross-platform paths
    from pathlib import Path
    config_path = Path("config") / "settings.json"
elif info['os'] == "Darwin":
    # macOS-specific code
    print("Running on macOS")
```

### Node.js Platform Detection

```javascript
const os = require('os');
const path = require('path');

const platform = os.platform();
const arch = os.arch();
const isWindows = platform === 'win32';
const isLinux = platform === 'linux';
const isMac = platform === 'darwin';

// Platform-specific configurations
const config = {
    // Cross-platform path construction
    dataDir: path.join(
        isWindows ? process.env.LOCALAPPDATA : os.homedir(),
        'myapp',
        'data'
    ),

    // Platform-specific commands
    restartCommand: isWindows ? 'net restart' : 'systemctl restart',

    // Line endings
    lineEnding: isWindows ? '\r\n' : '\n'
};

if (isLinux) {
    console.log('Linux-specific code');
} else if (isWindows) {
    console.log('Windows-specific code');
} else if (isMac) {
    console.log('macOS-specific code');
}
```

## Continuous Integration

### GitHub Actions Cross-platform Testing

```yaml
name: Cross-platform Tests

on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        python-version: ['3.9', '3.10', '3.11']

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v3

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
          pytest tests/

      - name: Cross-platform validation
        run: |
          # Verify line endings
          if [ "$RUNNER_OS" != "Windows" ]; then
            file scripts/*.sh | grep -q CRLF && exit 1 || true
          fi

          # Verify execute permissions
          if [ "$RUNNER_OS" = "Linux" ]; then
            ls -l scripts/*.sh | grep -q "^-rwxr-xr-x" || exit 1
          fi
```
