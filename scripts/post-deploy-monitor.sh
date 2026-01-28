#!/bin/bash
#
# post-deploy-monitor.sh
#
# Monitor deployment health and send alerts on issues
# Can run as a one-time check or continuously as a daemon
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_NAME="mcp-agent-server"
DEPLOY_URL="https://forms.abyz-lab.work"
DEPLOY_PATH="/var/www/html/forms"
LOCAL_DEPLOY_PATH="$PROJECT_ROOT/forms-interface"

# Monitoring settings
CHECK_INTERVAL=300  # 5 minutes between checks
HTTP_TIMEOUT=10     # HTTP request timeout
DISK_WARNING=85    # Disk usage warning threshold (%)
DISK_CRITICAL=95   # Disk usage critical threshold (%)
SSL_WARNING_DAYS=30  # SSL expiration warning (days)

# Logging
LOG_FILE="$HOME/deployment-monitor.log"
ALERT_LOG="$HOME/deployment-alerts.log"
PID_FILE="$HOME/deployment-monitor.pid"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
mkdir -p "$(dirname "$ALERT_LOG")" 2>/dev/null || true

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Alert function
alert() {
    local severity="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log to alert file
    echo "[$timestamp] [$severity] $message" >> "$ALERT_LOG"

    # Send desktop notification if available
    if command -v notify-send &> /dev/null; then
        local urgency="normal"
        [ "$severity" = "CRITICAL" ] && urgency="critical"
        notify-send "Deployment Alert [$severity]" "$message" -u "$urgency" 2>/dev/null || true
    fi

    # Print to console with color
    case "$severity" in
        "CRITICAL")
            echo -e "${RED}[CRITICAL]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
    esac
}

# Check HTTP endpoint
check_http() {
    log "INFO" "Checking HTTP endpoint: $DEPLOY_URL"

    if ! command -v curl &> /dev/null; then
        log "WARNING" "curl not available, skipping HTTP check"
        return
    fi

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$HTTP_TIMEOUT" "$DEPLOY_URL" 2>/dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
        log "INFO" "HTTP check passed: 200 OK"
        return 0
    elif [ "$http_code" = "000" ]; then
        alert "CRITICAL" "Cannot connect to $DEPLOY_URL (connection timeout or DNS failure)"
        return 2
    else
        alert "CRITICAL" "HTTP $http_code - $DEPLOY_URL (expected 200)"
        return 2
    fi
}

# Check SSL certificate
check_ssl() {
    log "INFO" "Checking SSL certificate for: $DEPLOY_URL"

    # Extract domain from URL
    local domain=$(echo "$DEPLOY_URL" | sed -e 's|^[^/]*//||' -e 's|/.*||')

    # Check if domain has SSL (HTTPS)
    if [[ "$DEPLOY_URL" != https://* ]]; then
        log "INFO" "Not using HTTPS, skipping SSL check"
        return 0
    fi

    # Get certificate file path
    local cert_file="/etc/letsencrypt/live/$domain/cert.pem"

    if [ ! -f "$cert_file" ]; then
        # Try to get expiry from openssl s_client
        if command -v openssl &> /dev/null; then
            local expiry_date
            expiry_date=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || echo "")

            if [ -n "$expiry_date" ]; then
                local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo "0")
                local current_epoch=$(date +%s)
                local days_left=$(( ($expiry_epoch - $current_epoch) / 86400 ))

                if [ "$days_left" -lt 0 ]; then
                    alert "CRITICAL" "SSL certificate expired for $domain"
                    return 2
                elif [ "$days_left" -lt "$SSL_WARNING_DAYS" ]; then
                    alert "WARNING" "SSL certificate expires in $days_left days for $domain"
                    return 1
                else
                    log "INFO" "SSL certificate valid for $days_left more days"
                    return 0
                fi
            fi
        fi
    else
        # Check from file
        if command -v openssl &> /dev/null; then
            local expiry_date
            expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
            local expiry_epoch=$(date -d "$expiry_date" +%s)
            local current_epoch=$(date +%s)
            local days_left=$(( ($expiry_epoch - $current_epoch) / 86400 ))

            if [ "$days_left" -lt 0 ]; then
                alert "CRITICAL" "SSL certificate expired for $domain"
                return 2
            elif [ "$days_left" -lt "$SSL_WARNING_DAYS" ]; then
                alert "WARNING" "SSL certificate expires in $days_left days for $domain"
                return 1
            else
                log "INFO" "SSL certificate valid for $days_left more days"
                return 0
            fi
        fi
    fi

    return 0
}

# Check disk space
check_disk() {
    log "INFO" "Checking disk space"

    # Check both deployment path and home directory
    local paths=("$DEPLOY_PATH" "/var/www" "$HOME")

    for path in "${paths[@]}"; do
        if [ ! -d "$path" ]; then
            continue
        fi

        local disk_usage
        disk_usage=$(df "$path" | tail -1 | awk '{print $5}' | sed 's/%//')

        log "INFO" "Disk usage for $path: ${disk_usage}%"

        if [ "$disk_usage" -ge "$DISK_CRITICAL" ]; then
            alert "CRITICAL" "Disk usage at ${disk_usage}% for $path (threshold: ${DISK_CRITICAL}%)"
        elif [ "$disk_usage" -ge "$DISK_WARNING" ]; then
            alert "WARNING" "Disk usage at ${disk_usage}% for $path (threshold: ${DISK_WARNING}%)"
        fi
    done
}

# Check nginx status
check_nginx() {
    log "INFO" "Checking nginx status"

    if ! command -v systemctl &> /dev/null; then
        log "WARNING" "systemctl not available, skipping nginx check"
        return 0
    fi

    if systemctl is-active --quiet nginx; then
        log "INFO" "nginx is running"
        return 0
    else
        alert "CRITICAL" "nginx is not running"
        return 2
    fi
}

# Check file permissions
check_permissions() {
    log "INFO" "Checking file permissions"

    if [ ! -d "$LOCAL_DEPLOY_PATH" ]; then
        log "WARNING" "Local deploy path not found: $LOCAL_DEPLOY_PATH"
        return 0
    fi

    local files=(
        "$LOCAL_DEPLOY_PATH/index.html"
        "$LOCAL_DEPLOY_PATH/script.js"
        "$LOCAL_DEPLOY_PATH/styles.css"
    )

    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            alert "CRITICAL" "Required file not found: $file"
            continue
        fi

        local perms
        perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null || echo "000")

        # Check if files are read-only (444)
        if [ "$perms" = "444" ]; then
            log "INFO" "File permissions correct: $file ($perms)"
        else
            alert "WARNING" "Unexpected permissions for $file: $perms (expected 444)"
        fi
    done
}

# Check symlink
check_symlink() {
    log "INFO" "Checking deployment symlink"

    if [ ! -e "$DEPLOY_PATH" ]; then
        alert "CRITICAL" "Deployment path does not exist: $DEPLOY_PATH"
        return 2
    fi

    if [ -L "$DEPLOY_PATH" ]; then
        local target
        target=$(readlink -f "$DEPLOY_PATH")

        if [ -d "$target" ]; then
            log "INFO" "Symlink OK: $DEPLOY_PATH -> $target"
            return 0
        else
            alert "CRITICAL" "Broken symlink: $DEPLOY_PATH -> $target (target does not exist)"
            return 2
        fi
    else
        alert "WARNING" "Deployment path is not a symlink: $DEPLOY_PATH"
        return 1
    fi
}

# Run all checks
run_all_checks() {
    log "INFO" "Starting deployment health checks for $PROJECT_NAME"

    local exit_code=0

    # Run checks in order
    check_http || exit_code=$?
    check_ssl || exit_code=$?
    check_nginx || exit_code=$?
    check_symlink || exit_code=$?
    check_disk || exit_code=$?
    check_permissions || exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log "INFO" "All health checks passed"
        alert "INFO" "Deployment health check completed: All systems OK"
    else
        log "ERROR" "Some health checks failed"
    fi

    return $exit_code
}

# Run as daemon (continuous monitoring)
run_as_daemon() {
    log "INFO" "Starting deployment monitor daemon (PID: $$)"
    echo "$$" > "$PID_FILE"

    alert "INFO" "Deployment monitoring started for $PROJECT_NAME"

    # Trap signals for graceful shutdown
    trap 'log "INFO" "Received shutdown signal, exiting..."; rm -f "$PID_FILE"; alert "INFO" "Deployment monitoring stopped"; exit 0' SIGTERM SIGINT

    # Continuous monitoring loop
    while true; do
        run_all_checks
        sleep "$CHECK_INTERVAL"
    done
}

# Stop daemon
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log "INFO" "Stopping deployment monitor daemon (PID: $pid)"
            kill "$pid"
            rm -f "$PID_FILE"
            alert "INFO" "Deployment monitoring stopped"
        else
            log "WARNING" "PID file exists but process not running, cleaning up"
            rm -f "$PID_FILE"
        fi
    else
        log "INFO" "No running deployment monitor found"
    fi
}

# Show daemon status
show_status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "✅ Deployment monitor is running (PID: $pid)"
            echo ""
            echo "Recent logs:"
            tail -10 "$LOG_FILE"
            exit 0
        else
            echo "❌ PID file exists but process not running"
            rm -f "$PID_FILE"
            exit 1
        fi
    else
        echo "⚠️  Deployment monitor is not running"
        exit 1
    fi
}

# Show recent alerts
show_alerts() {
    if [ -f "$ALERT_LOG" ]; then
        echo "Recent alerts (last 20):"
        echo "====================="
        tail -20 "$ALERT_LOG"
    else
        echo "No alerts recorded"
    fi
}

# Print usage
usage() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
  check       Run one-time health check (default)
  start       Start continuous monitoring daemon
  stop        Stop monitoring daemon
  restart     Restart monitoring daemon
  status      Show daemon status
  alerts      Show recent alerts
  help        Show this help message

Examples:
  $0 check                    # Run one-time check
  $0 start                    # Start monitoring in background
  $0 status                   # Check if monitor is running
  $0 stop                     # Stop monitoring

Configuration:
  Edit the script to configure:
    - DEPLOY_URL              Deployment URL to monitor
    - DEPLOY_PATH             Deployment path on server
    - CHECK_INTERVAL          Seconds between checks (default: 300)
    - DISK_WARNING            Disk warning threshold % (default: 85)
    - SSL_WARNING_DAYS        SSL warning days (default: 30)

EOF
}

# Main
main() {
    local command="${1:-check}"

    case "$command" in
        check)
            run_all_checks
            ;;
        start)
            # Check if already running
            if [ -f "$PID_FILE" ]; then
                echo "Deployment monitor is already running (PID: $(cat $PID_FILE))"
                echo "Use '$0 restart' to restart or '$0 stop' to stop"
                exit 1
            fi

            # Start in background
            log "INFO" "Starting deployment monitor in background..."
            nohup bash "$0" daemon > /dev/null 2>&1 &
            sleep 1

            if [ -f "$PID_FILE" ]; then
                echo "✅ Deployment monitor started (PID: $(cat $PID_FILE))"
                echo "Use '$0 status' to check status"
                echo "Use '$0 alerts' to view alerts"
                echo "Use '$0 stop' to stop monitoring"
            else
                echo "❌ Failed to start deployment monitor"
                exit 1
            fi
            ;;
        stop)
            stop_daemon
            ;;
        restart)
            stop_daemon
            sleep 1
            exec "$0" start
            ;;
        status)
            show_status
            ;;
        daemon)
            run_as_daemon
            ;;
        alerts)
            show_alerts
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo "Unknown command: $command"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"
