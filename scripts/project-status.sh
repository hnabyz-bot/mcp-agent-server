#!/bin/bash
#
# project-status.sh
#
# Display status of all projects being developed
# Shows deployment status, version, last action, and health check
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SESSION_STATE="$PROJECT_ROOT/.claude/session_state.json"
STATUS_CACHE="$HOME/.project_status_cache"
LOG_FILE="$HOME/project_status.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Project configuration
# Add your projects here
declare -A PROJECTS
PROJECTS["mcp-agent-server"]="$PROJECT_ROOT|https://forms.abyz-lab.work|/var/www/html/forms|forms-interface"
#PROJECTS["another-project"]="/path/to/another|https://another-project.com|/var/www/another|public"
#PROJECTS["project-three"]="/path/to/three|https://three.example.com|/var/www/three|build"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Get project status from session state
get_session_status() {
    local project_dir="$1"
    local session_file="$project_dir/.claude/session_state.json"

    if [ ! -f "$session_file" ]; then
        echo "unknown"
        return
    fi

    if command -v jq &> /dev/null; then
        local status=$(jq -r '.current_task // "unknown"' "$session_file" 2>/dev/null || echo "unknown")
        echo "$status"
    else
        echo "unknown"
    fi
}

# Get last commit info
get_git_info() {
    local project_dir="$1"

    if [ ! -d "$project_dir/.git" ]; then
        echo ""
        return
    fi

    cd "$project_dir" || return

    local last_commit=$(git log -1 --format="%h %s" 2>/dev/null || echo "unknown")
    local last_date=$(git log -1 --format="%ci" 2>/dev/null || echo "unknown")

    echo "$last_date | $last_commit"
}

# Check deployment health
check_deployment_health() {
    local project_dir="$1"
    local deploy_url="$2"
    local deploy_path="$3"

    local status="✅"
    local issues=()

    # Check if deployed path exists
    if [ -n "$deploy_path" ] && [ -e "$deploy_path" ]; then
        # File exists, check if it's a symlink
        if [ -L "$deploy_path" ]; then
            local target=$(readlink -f "$deploy_path")
            if [ ! -d "$target" ]; then
                status="❌"
                issues+=("Broken symlink: $deploy_path -> $target")
            fi
        fi
    elif [ -n "$deploy_path" ]; then
        status="⚠️ "
        issues+=("Deploy path not found: $deploy_path")
    fi

    # Check HTTP status if URL provided
    if [ -n "$deploy_url" ]; then
        if command -v curl &> /dev/null; then
            local http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$deploy_url" 2>/dev/null || echo "000")

            if [ "$http_code" = "200" ]; then
                : # Healthy
            elif [ "$http_code" = "000" ]; then
                status="⚠️ "
                issues+=("Cannot connect to: $deploy_url")
            else
                status="❌"
                issues+=("HTTP $http_code: $deploy_url")
            fi
        fi
    fi

    echo "$status|${issues[*]}"
}

# Get current version
get_version() {
    local project_dir="$1"
    local index_file="$project_dir/forms-interface/index.html"

    if [ -f "$index_file" ]; then
        if command -v grep &> /dev/null && command -v sed &> /dev/null; then
            local version=$(grep -oP 'script\.js\?v=\K[0-9.]+' "$index_file" 2>/dev/null || echo "unknown")
            echo "$version"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Display project status
display_project_status() {
    local project_name="$1"
    local project_config="$2"

    IFS='|' read -r project_dir deploy_url deploy_path build_dir <<< "$project_config"

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Project: ${NC}$project_name"
    echo -e "${BLUE}Path: ${NC}$project_dir"

    # Get session status
    local session_status=$(get_session_status "$project_dir")
    echo -e "${BLUE}Last Action: ${NC}$session_status"

    # Get git info
    local git_info=$(get_git_info "$project_dir")
    if [ -n "$git_info" ]; then
        echo -e "${BLUE}Last Commit: ${NC}$git_info"
    fi

    # Get version
    local version=$(get_version "$project_dir")
    echo -e "${BLUE}Version: ${NC}$version"

    # Check deployment
    if [ -n "$deploy_url" ] || [ -n "$deploy_path" ]; then
        local health_result=$(check_deployment_health "$project_dir" "$deploy_url" "$deploy_path")
        IFS='|' read -r health_status health_issues <<< "$health_result"

        echo -e "${BLUE}Deployment: ${NC}$health_status $health_issues"
        echo -e "${BLUE}URL: ${NC}${deploy_url:-"N/A"}"
    fi

    echo ""
}

# Display summary
display_summary() {
    local total=${#PROJECTS[@]}
    local healthy=0
    local warning=0
    local critical=0

    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Project Status Dashboard Summary    ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo ""

    for project_name in "${!PROJECTS[@]}"; do
        local project_config="${PROJECTS[$project_name]}"
        IFS='|' read -r project_dir deploy_url deploy_path build_dir <<< "$project_config"

        local health_result=$(check_deployment_health "$project_dir" "$deploy_url" "$deploy_path")
        IFS='|' read -r health_status health_issues <<< "$health_result"

        case "$health_status" in
            "✅")
                ((healthy++))
                ;;
            "⚠️ ")
                ((warning++))
                ;;
            "❌")
                ((critical++))
                ;;
        esac
    done

    echo -e "${GREEN}Total Projects: ${NC}$total"
    echo -e "${GREEN}Healthy: ${NC}$healthy"
    echo -e "${YELLOW}Warnings: ${NC}$warning"
    echo -e "${RED}Critical: ${NC}$critical"
    echo ""
}

# Main function
main() {
    log "Project status check started"

    # Clear screen for better visibility
    clear

    # Display header
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}    Project Status Dashboard - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Display summary first
    display_summary

    # Display each project status
    local index=1
    for project_name in "${!PROJECTS[@]}"; do
        local project_config="${PROJECTS[$project_name]}"

        echo -e "${GRAY}[$index] ${NC}$project_name"
        display_project_status "$project_name" "$project_config"
        ((index++))
    done

    # Display next steps suggestion
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Quick Actions:${NC}"
    echo -e "  ${GREEN}cd${NC} <project_dir>        - Switch to project directory"
    echo -e "  ${GREEN}git status${NC}              - Check git status"
    echo -e "  ${GREEN}./scripts/deploy-and-restart.sh${NC} - Deploy project"
    echo -e "  ${GREEN}./scripts/project-status.sh${NC}   - Refresh this dashboard"
    echo ""

    log "Project status check completed"

    # Show recent alerts if any
    if [ -f "$HOME/deployment-alerts.log" ]; then
        local recent_alerts=$(tail -5 "$HOME/deployment-alerts.log" 2>/dev/null || echo "")
        if [ -n "$recent_alerts" ]; then
            echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${RED}Recent Alerts (last 5):${NC}"
            echo "$recent_alerts"
            echo ""
        fi
    fi
}

# Run main function
main "$@"
