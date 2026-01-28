# Cross-platform Development Reference

Comprehensive platform documentation and reference materials.

---

## Platform Comparison Matrix

### File System Characteristics

| Feature | Windows | Linux | macOS |
|---------|---------|-------|-------|
| **Case Sensitivity** | Case-insensitive (NTFS, FAT32) | Case-sensitive (ext4, xfs) | Case-insensitive (APFS), Case-preserving |
| **Path Separator** | Backslash `\` | Forward slash `/` | Forward slash `/` |
| **Path Max Length** | 260 chars (MAX_PATH) | 4096 chars | 1024 chars |
| **Forbidden Characters** | `< > : " / \ | ? *` | `/` and NULL | `:` and NULL |
| **Reserved Names** | CON, PRN, AUX, NUL, COM*, LPT* | None (except `/` and NULL) | None |

### Line Endings

| Platform | Line Ending | Hex | Description |
|----------|-------------|-----|-------------|
| Windows | CRLF | `0D 0A` | Carriage Return + Line Feed |
| Linux | LF | `0A` | Line Feed only |
| Classic Mac OS | CR | `0D` | Carriage Return only (obsolete) |
| macOS (Unix) | LF | `0A` | Line Feed only (since OS X) |

### Permission Models

| Feature | Windows | Linux | macOS |
|---------|---------|-------|-------|
| **Executable Detection** | File extension-based | Execute bit (`chmod +x`) | Execute bit (`chmod +x`) |
| **Permission Bits** | ACLs (Access Control Lists) | Unix mode bits (rwxrwxrwx) | Unix mode bits + ACLs |
| **Read-only** | File attribute | Mode 444 (r--r--r--) | Mode 444 (r--r--r--) |
| **Executable Scripts** | `.bat`, `.cmd`, `.ps1` | Any file with execute bit | Any file with execute bit |
| **Script Shebang** | Not supported (use extensions) | `#!/bin/bash` etc. | `#!/bin/bash` etc. |

### Symbolic Links

| Feature | Windows | Linux | macOS |
|---------|---------|-------|-------|
| **Creation Command** | `mklink` (Admin/Dev Mode) | `ln -s` | `ln -s` |
| **Privileges Required** | Administrator or Developer Mode | None (for user dirs) | None (for user dirs) |
| **Junctions** | Supported (directory junctions) | Not applicable | Not applicable |
| **Hard Links** | Supported (NTFS) | Supported | Supported |
| **Max Link Depth** | Limited | Unlimited | Unlimited |

---

## File System Reference

### Windows-Specific Path Formats

**UNC Paths (Universal Naming Convention):**
```
\\Server\Share\file.txt
\\?\C:\Very\Long\Path\file.txt  # Extended-length path
```

**Drive Letters:**
```
C:\Users\username\Documents
D:\data\project
```

**Environment Variables:**
```
%USERPROFILE%\Documents
%APPDATA%\Application
%TEMP%
```

**PowerShell Paths:**
```powershell
# PSDrives (virtual drives)
C:\Windows\
HKLM:\Software\  # Registry
Env:\Path        # Environment variables
```

### Linux-Specific Path Formats

**Standard Paths:**
```
/home/username/documents
/var/www/html
/usr/local/bin
```

**Home Directory:**
```
~  # Expands to /home/username
$HOME  # Environment variable
```

**Special Paths:**
```
.   # Current directory
..  # Parent directory
-   # Previous directory
```

**Symlink Examples:**
```
/etc/alternatives/python3 -> /usr/bin/python3.10
/var/www/html/forms -> /home/user/project/forms-interface
```

### macOS-Specific Path Formats

**Standard Paths:**
```
/Users/username/Documents
/Applications/MyApp.app
/Library/Preferences
```

**Special Directories:**
```
~/Desktop
~/Downloads
~/Library/Application Support
```

**Bundle Structure (.app):**
```
MyApp.app/Contents/
  ├── MacOS/MyApp        # Executable
  ├── Resources/         # Assets
  └── Info.plist         # Metadata
```

---

## Permission Reference

### Linux Permission Bits

**Symbolic Notation:**
```
-rwxrwxrwx
││││││└── Other users (read, write, execute)
││││└──── Group (read, write, execute)
│││└───── Owner (read, write, execute)
││└────── File type (- = file, d = directory, l = symlink)
```

**Octal Notation:**
```
755 = rwxr-xr-x  (Owner: rwx, Group: rx, Other: rx)
644 = rw-r--r--  (Owner: rw, Group: r, Other: r)
777 = rwxrwxrwx  (All permissions)
444 = r--r--r--  (Read-only for all)
```

**Common Permissions:**
```bash
644  # Regular file (rw-r--r--)
755  # Executable file/Directory (rwxr-xr-x)
600  # Private file (rw-------)
700  # Private directory (rwx------)

# Deployment-specific
444  # Read-only file (r--r--r--)
555  # Read-only executable (r-xr-xr-x)
```

### Windows File Attributes

**Attribute Bits:**
```powershell
ReadOnly    # FILE_ATTRIBUTE_READONLY (0x1)
Hidden      # FILE_ATTRIBUTE_HIDDEN (0x2)
System      # FILE_ATTRIBUTE_SYSTEM (0x4)
Archive     # FILE_ATTRIBUTE_ARCHIVE (0x20)
Temporary   # FILE_ATTRIBUTE_TEMPORARY (0x100)
```

**PowerShell Commands:**
```powershell
# Set read-only
Set-ItemProperty -Path "file.txt" -Name IsReadOnly -Value $true

# Check attributes
Get-ItemProperty -Path "file.txt" | Select-Object Attributes
```

---

## Line Ending Reference

### Detection Commands

**Linux/macOS:**
```bash
# Show line ending type
file script.sh
# Output: script.sh: ASCII text, with CRLF line terminators

# Show raw characters (CRLF appears as ^M$)
cat -A script.sh

# Check only for CRLF
file script.sh | grep -q "CRLF" && echo "Has CRLF"

# Count files with CRLF
find . -name "*.sh" -type f -exec file {} \; | grep -c "CRLF"
```

**Windows PowerShell:**
```powershell
# Check file encoding
Get-Content script.sh | Format-Hex

# Detect CRLF
Select-String -Path script.sh -Pattern "`r`n"
```

**Python:**
```python
# Detect line endings
with open('script.sh', 'rb') as f:
    content = f.read()
    if b'\r\n' in content:
        print("Has CRLF")
    if b'\n' in content and b'\r\n' not in content:
        print("Has LF only")
```

### Conversion Tools

**dos2unix/unix2dos:**
```bash
# Convert CRLF to LF
dos2unix script.sh

# Convert LF to CRLF
unix2dos script.sh

# Batch convert
find . -name "*.sh" -exec dos2unix {} \;
```

**sed:**
```bash
# CRLF to LF
sed -i 's/\r$//' script.sh

# LF to CRLF
sed -i 's/$/\r/' script.sh
```

**Python:**
```python
# Convert CRLF to LF
with open('script.sh', 'rb') as f:
    content = f.read().decode('utf-8')

content = content.replace('\r\n', '\n')

with open('script.sh', 'wb') as f:
    f.write(content.encode('utf-8'))
```

---

## Git Configuration Reference

### .gitattributes Patterns

**Text File Detection:**
```
# Auto-detect text files
* text=auto

# Explicit text files
*.txt text
*.md text
*.json text

# Explicit binary files
*.png binary
*.jpg binary
*.pdf binary
```

**Line Ending Control:**
```
# Always LF (Unix)
*.sh text eol=lf
*.py text eol=lf
*.js text eol=lf

# Always CRLF (Windows)
*.bat text eol=crlf
*.ps1 text eol=crlf

# As-is (don't convert)
*.png binary
*.jpg binary
```

**Working Directory EOL:**
```
# Checkout with CRLF on Windows, LF on Unix
* text=auto eol=lf

# Always use LF in working directory
* text eol=lf
```

### Git Settings

**core.autocrlf:**
```bash
# Windows: Convert CRLF to LF on commit, LF to CRLF on checkout
git config --global core.autocrlf true

# Linux/macOS: Don't convert
git config --global core.autocrlf input

# Disable: Don't touch line endings
git config --global core.autocrlf false
```

**core.eol:**
```bash
# Force LF
git config --global core.eol lf

# Force CRLF
git config --global core.eol crlf
```

**core.safecrlf:**
```bash
# Warn if converting CRLF to LF
git config --global core.safecrlf true

# Fail if converting mixed line endings
git config --global core.safecrlf warn
```

---

## Shell Reference

### Bash Shebang Variants

```bash
#!/bin/bash        # GNU Bash (most portable)
#!/usr/bin/env bash  # Use PATH to find bash (more portable)
#!/bin/sh          # POSIX shell (minimal features)
#!/usr/bin/env sh  # Use PATH to find sh
```

**Choosing Shebang:**
- Use `#!/bin/bash` for scripts requiring Bash features
- Use `#!/usr/bin/env bash` for maximum portability
- Use `#!/bin/sh` for POSIX-compliant scripts
- Use `#!/usr/bin/env python3` for Python scripts

### Cross-Platform Shell Commands

**Path Operations:**
```bash
# Get script directory (works on Linux/macOS/Git Bash)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Get script directory (Python alternative)
SCRIPT_DIR=$(python3 -c "import os; print(os.path.dirname(os.path.abspath('$0')))")
```

**File Existence:**
```bash
# Test if file exists
[ -f "$FILE" ]    # Regular file
[ -d "$DIR" ]     # Directory
[ -e "$PATH" ]    # Exists (file or directory)
[ -L "$LINK" ]    # Symlink

# Test if file is readable/writable/executable
[ -r "$FILE" ]    # Readable
[ -w "$FILE" ]    # Writable
[ -x "$FILE" ]    # Executable
```

**String Operations:**
```bash
# Get directory name
DIR=$(dirname "$PATH")

# Get file name
FILE=$(basename "$PATH")

# Get file extension
EXT="${FILE##*.}"

# Get file name without extension
BASE="${FILE%.*}"

# Remove trailing slash
PATH="${PATH%/}"
```

---

## Programming Language APIs

### Python (pathlib)

```python
from pathlib import Path

# Path construction
path = Path("dir") / "subdir" / "file.txt"
path = Path("dir") / "subdir" / "file.txt"

# Path operations
path.exists()
path.is_file()
path.is_dir()
path.is_absolute()

# Path components
path.name         # file.txt
path.stem         # file
path.suffix       # .txt
path.parent       # .. (parent Path object)

# Path resolution
path.resolve()    # Absolute path
path.absolute()   # Absolute path (no symlink resolution)
path.as_posix()   # Always use forward slashes

# File operations
path.read_text()
path.write_text(content)
path.stat()
```

### Node.js (path module)

```javascript
const path = require('path');

// Path construction
path.join('dir', 'subdir', 'file.txt')
path.resolve('dir', 'subdir', 'file.txt')

// Path normalization
path.normalize('dir/subdir/../file.txt')
path.posix.join('dir', 'subdir')  # Force POSIX (forward slash)
path.win32.join('dir', 'subdir')  # Force Windows (backslash)

# Path components
path.basename('/path/file.txt')    // file.txt
path.dirname('/path/file.txt')     // /path
path.extname('/path/file.txt')     // .txt
path.parse('/path/file.txt')       // { root, dir, base, name, ext }

// Path detection
path.isAbsolute('/path/file.txt')
path.relative('/from', '/to')
```

### Rust (std::path)

```rust
use std::path::Path;

// Path construction
let path = Path::new("dir").join("subdir").join("file.txt");

// Path operations
path.exists();
path.is_file();
path.is_dir();
path.is_absolute();

// Path components
path.file_name();    // Some("file.txt")
path.file_stem();    // Some("file")
path.extension();    // Some("txt")
path.parent();       // Some(Path("dir/subdir"))

// Path conversion
path.to_path_buf();  // PathBuf
path.to_str();       // Option<&str>
path.display();      // Display
```

---

## Deployment Reference

### Linux Service Management

**systemd (Ubuntu, Debian, CentOS, RHEL):**
```bash
# Start/stop/restart service
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# Enable/disable at boot
sudo systemctl enable nginx
sudo systemctl disable nginx

# Check status
sudo systemctl status nginx

# View logs
sudo journalctl -u nginx -f
```

**init.d (older systems):**
```bash
sudo service nginx start
sudo service nginx stop
sudo service nginx restart
sudo service nginx status
```

### macOS Service Management

**launchctl:**
```bash
# Start/stop service
sudo launchctl start com.example.service
sudo launchctl stop com.example.service

# Load/unload service
sudo launchctl load /Library/LaunchDaemons/com.example.service.plist
sudo launchctl unload /Library/LaunchDaemons/com.example.service.plist

# List services
sudo launchctl list
```

**brew services (Homebrew):**
```bash
brew services start nginx
brew services stop nginx
brew services restart nginx
brew services list
```

### Windows Service Management

**PowerShell:**
```powershell
# Start/Stop service
Start-Service -Name "nginx"
Stop-Service -Name "nginx"
Restart-Service -Name "nginx"

# Check status
Get-Service -Name "nginx"

# View service details
Get-Service -Name "nginx" | Select-Object *
```

**sc (Service Control):**
```cmd
sc start nginx
sc stop nginx
sc query nginx
```

---

## Testing Reference

### Cross-Platform Test Frameworks

**Python: pytest**
```python
# pytest.ini
[pytest]
testpaths = tests
python_files = test_*.py
python_functions = test_*
python_classes = Test*

# Run tests
pytest tests/                # Run all tests
pytest tests/test_file.py   # Run specific file
pytest -k "test_name"       # Run matching tests
pytest -v                   # Verbose output
pytest -s                   # Show print output
```

**Node.js: Jest**
```javascript
// package.json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  },
  "jest": {
    "testEnvironment": "node",
    "testMatch": ["**/tests/**/*.test.js"]
  }
}
```

**Bash: Bats**
```bash
#!/usr/bin/env bats
# test/file_operations.bats

@test "check if file exists" {
  [ -f "forms-interface/index.html" ]
}

@test "check if script is executable" {
  [ -x "deploy-and-restart.sh" ]
}

@test "check line endings are LF" {
  run file deploy-and-restart.sh
  [[ ! "$output" =~ CRLF ]]
}
```

---

## Debugging Reference

### Common Error Messages

**Case Sensitivity:**
```
Error: No such file or directory
Cause: Filenames don't match exactly (case-sensitive)
Fix: Use `ls -la` to verify exact filename case
```

**Missing Execute Permissions:**
```
Error: Permission denied
bash: ./script.sh: Permission denied
Cause: Script doesn't have execute bit set
Fix: Run `chmod +x script.sh`
```

**Line Ending Issues:**
```
Error: bad interpreter: No such file or directory
/bin/bash^M: bad interpreter
Cause: Script has CRLF line endings
Fix: Run `dos2unix script.sh` or `sed -i 's/\r$//' script.sh`
```

**Symlink Failures:**
```
Error: Permission denied
ln: failed to create symbolic link '/path/to/link': Permission denied
Cause: Creating symlinks in system directories requires privileges
Fix: Use `sudo` or create link in user directory
```

**Path Issues:**
```
Error: ENOENT: no such file or directory
Cause: Path uses wrong separators or doesn't exist
Fix: Use `path.join` (Node.js) or `pathlib` (Python)
```

### Debugging Tools

**strace (Linux):**
```bash
# Trace system calls
strace ./script.sh

# Trace file operations only
strace -e trace=file ./script.sh

# Save to file
strace -o trace.log ./script.sh
```

**Process Monitor (Windows):**
```powershell
# Monitor file system activity
procmon.exe

# Filter by process name and operation
# Save to log file for analysis
```

**dtruss (macOS):**
```bash
# Trace system calls
sudo dtruss -f ./script.sh

# Trace specific syscalls
sudo dtruss -f -t open,read,write ./script.sh
```

---

This reference provides comprehensive platform-specific information for cross-platform development.
