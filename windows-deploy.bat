@echo off
REM ============================================
REM Windows Deployment Script for forms-interface (Improved Version)
REM This script handles version bumping and git push with error handling
REM ============================================

setlocal enabledelayedexpansion

REM Configuration
set MAX_RETRIES=3
set RETRY_DELAY=5

echo ====================================
echo Forms Interface Deployment (Windows)
echo ====================================
echo.

REM ============================================
REM Pre-flight Checks
REM ============================================
echo Step 0: Pre-flight checks...
echo.

REM Check if git repository exists
if not exist ".git" (
    echo [ERROR] Not a git repository!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

REM Check network connectivity
echo [INFO] Checking network connectivity...
ping -n 1 github.com >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Cannot reach GitHub. Please check your internet connection.
    pause
    exit /b 1
)
echo [OK] Network connectivity OK
echo.

REM ============================================
REM Step 1: Check if git repository is clean
REM ============================================
echo Step 1: Checking git status...

for /f "delims=" %%i in ('git status --porcelain') do (
    set "CHANGES=1"
)

if defined CHANGES (
    echo [WARNING] You have uncommitted changes!
    echo Please commit or stash them first.
    echo.
    git status --short
    echo.
    choice /C YN /M "Do you want to stash changes and continue"
    if errorlevel 2 (
        echo [INFO] Deployment cancelled by user.
        pause
        exit /b 1
    )

    echo [INFO] Stashing changes...
    git stash push -m "auto-stash-before-deploy-%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
    if errorlevel 1 (
        echo [ERROR] Git stash failed!
        pause
        exit /b 1
    )
    echo [OK] Changes stashed
)

echo [OK] Working directory is clean
echo.

REM ============================================
REM Step 2: Extract current version
REM ============================================
echo Step 2: Reading current cache version...

for /f "delims=" %%i in ('powershell -Command "if ((Get-Content forms-interface\index.html -Raw -ErrorAction Stop) -match 'script\.js\?v=([0-9.]+)') { Write-Output $matches[1] }"') do set CURRENT_VERSION=%%i

if not defined CURRENT_VERSION (
    echo [ERROR] Failed to read current version from index.html
    pause
    exit /b 1
)

echo Current version: %CURRENT_VERSION%
echo.

REM ============================================
REM Step 3: Increment version
REM ============================================
echo Step 3: Incrementing cache version...

for /f "tokens=1,2,3 delims=." %%a in ("%CURRENT_VERSION%") do (
    set "MAJOR=%%a"
    set "MINOR=%%b"
    set /a "PATCH=%%c + 1"
)

set "NEW_VERSION=%MAJOR%.%MINOR%.%PATCH%"
echo New version: %NEW_VERSION%
echo.

REM ============================================
REM Step 4: Update index.html
REM ============================================
echo Step 4: Updating forms-interface\index.html...

REM Backup original file
copy /Y "forms-interface\index.html" "forms-interface\index.html.bak" >nul

REM Create temporary file with updated version
powershell -Command "$version = '%NEW_VERSION%'; (Get-Content forms-interface\index.html) -replace 'script\.js\?v=[0-9.]*', \"script.js?v=$version\" | Set-Content forms-interface\index.html"

if errorlevel 1 (
    echo [ERROR] Failed to update index.html!
    echo Restoring backup...
    copy /Y "forms-interface\index.html.bak" "forms-interface\index.html" >nul
    del "forms-interface\index.html.bak"
    pause
    exit /b 1
)

REM Verify update
findstr /C:"script.js?v=%NEW_VERSION%" "forms-interface\index.html" >nul
if errorlevel 1 (
    echo [ERROR] Version update verification failed!
    echo Restoring backup...
    copy /Y "forms-interface\index.html.bak" "forms-interface\index.html" >nul
    del "forms-interface\index.html.bak"
    pause
    exit /b 1
)

REM Delete backup on success
del "forms-interface\index.html.bak"

echo [OK] Cache version updated to %NEW_VERSION%
echo.

REM ============================================
REM Step 5: Git commit and push with retry
REM ============================================
echo Step 5: Committing and pushing changes...
echo.

REM Commit changes
echo [INFO] Committing changes...
git add forms-interface/index.html
git commit -m "Bump cache version to %NEW_VERSION%

- Auto-incremented cache version for deployment
- Force browser cache refresh"

if errorlevel 1 (
    echo [ERROR] Git commit failed!
    echo Please check the error message above.
    pause
    exit /b 1
)

echo [OK] Changes committed
echo.

REM Push to remote with retry logic
set RETRY_COUNT=0

:push_retry
echo [INFO] Pushing to GitHub (Attempt !RETRY_COUNT!/%MAX_RETRIES%)...

git push origin main

if errorlevel 1 (
    set /a RETRY_COUNT+=1

    if !RETRY_COUNT! geq %MAX_RETRIES% (
        echo [ERROR] Git push failed after %MAX_RETRIES% attempts!
        echo.
        echo Troubleshooting:
        echo 1. Check your internet connection
        echo 2. Verify GitHub credentials: git remote -v
        echo 3. Check GitHub status: https://www.githubstatus.com
        echo 4. Try manual push: git push origin main
        echo.
        echo Note: Your changes have been committed locally.
        echo You can push manually when the issue is resolved.
        pause
        exit /b 1
    )

    echo [WARN] Push failed, retrying in %RETRY_DELAY% seconds...
    timeout /t %RETRY_DELAY% /nobreak >nul
    goto push_retry
)

echo [OK] Changes pushed to GitHub
echo.

REM ============================================
REM Step 6: Display deployment instructions
REM ============================================
echo ====================================
echo Deployment completed successfully!
echo ====================================
echo.
echo Deployment Summary:
echo   Previous Version: %CURRENT_VERSION%
echo   New Version: %NEW_VERSION%
echo   Push Attempts: !RETRY_COUNT!
echo.
echo Next Steps (Raspberry Pi):
echo   The deploy-and-restart.sh script will now:
echo   - Automatically pull latest changes (no conflicts!)
echo   - Deploy to web server
echo   - Restart nginx/apache
echo   - Set files to read-only
echo   - Verify deployment success
echo   - Auto-rollback on failure
echo.
echo   Just run this on your Pi:
echo   1. SSH: ssh raspi@your-pi-ip
echo   2. cd ~/workspace/mcp-agent-server
echo   3. sudo ./deploy-and-restart.sh
echo.
echo Access URLs:
echo   - http://localhost/forms
echo   - https://forms.abyz-lab.work
echo.
echo IMPORTANT: Clear browser cache after deployment!
echo   Windows/Linux: Ctrl + Shift + R
echo   Mac: Cmd + Shift + R
echo.
echo Monitoring:
echo   Check deployment logs on Pi: tail -f /var/log/mcp-agent-deploy.log
echo   Check web server status: sudo systemctl status nginx
echo.

REM ============================================
REM Completion
REM ============================================
echo [SUCCESS] Deployment pipeline initiated successfully!
echo.
pause
