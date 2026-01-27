@echo off
REM ============================================
REM Windows Deployment Script for forms-interface
REM This script handles version bumping and git push
REM ============================================

setlocal enabledelayedexpansion

echo ====================================
echo Forms Interface Deployment (Windows)
echo ====================================
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
    pause
    exit /b 1
)
echo [OK] Working directory is clean
echo.

REM ============================================
REM Step 2: Extract current version
REM ============================================
echo Step 2: Reading current cache version...
for /f "delims=" %%i in ('powershell -Command "if ((Get-Content forms-interface\index.html -Raw) -match 'script\.js\?v=([0-9.]+)') { Write-Output $matches[1] }"') do set CURRENT_VERSION=%%i
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

REM Create temporary file with updated version
powershell -Command "$version = '%NEW_VERSION%'; (Get-Content forms-interface\index.html) -replace 'script\.js\?v=[0-9.]*', \"script.js?v=$version\" | Set-Content forms-interface\index.html"

echo [OK] Cache version updated to %NEW_VERSION%
echo.

REM ============================================
REM Step 5: Git commit and push
REM ============================================
echo Step 5: Committing and pushing changes...
echo.

REM Commit changes
git add forms-interface/index.html
git commit -m "Bump cache version to %NEW_VERSION%

- Auto-incremented cache version for deployment
- Force browser cache refresh"

if errorlevel 1 (
    echo [ERROR] Git commit failed!
    pause
    exit /b 1
)

echo [OK] Changes committed
echo.

REM Push to remote
echo Pushing to GitHub...
git push origin main

if errorlevel 1 (
    echo [ERROR] Git push failed!
    echo Please check your internet connection and credentials.
    pause
    exit /b 1
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
echo.
echo Next Steps:
echo   1. SSH into Raspberry Pi
echo   2. Run: cd ~/workspace/mcp-agent-server
echo   3. Run: git pull
echo   4. Run: sudo ./deploy-and-restart.sh
echo.
echo Access URLs:
echo   - http://localhost/forms
echo   - https://forms.abyz-lab.work
echo.
echo IMPORTANT: Clear browser cache after deployment!
echo   Windows/Linux: Ctrl + Shift + R
echo   Mac: Cmd + Shift + R
echo.
pause
