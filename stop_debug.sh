#!/bin/bash

#
# Stop script for PTP debug session
# Cleans up virtual interfaces and stops processes
#

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_DIR="/tmp/ptp_debug"

# Virtual interface names
VETH_MASTER="veth_ptp_master"
VETH_SLAVE="veth_ptp_slave"
BRIDGE_NAME="br_ptp"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Stop PTP processes
stop_processes() {
    log_info "Stopping PTP processes..."
    
    local master_pid_file="$PID_DIR/master.pid"
    local slave_pid_file="$PID_DIR/slave.pid"
    
    # Stop master
    if [[ -f "$master_pid_file" ]]; then
        local master_pid=$(cat "$master_pid_file")
        if ps -p "$master_pid" > /dev/null 2>&1; then
            log_info "Stopping PTP master (PID: $master_pid)"
            kill "$master_pid" 2>/dev/null || true
            sleep 1
        fi
        rm "$master_pid_file"
    fi
    
    # Stop slave
    if [[ -f "$slave_pid_file" ]]; then
        local slave_pid=$(cat "$slave_pid_file")
        if ps -p "$slave_pid" > /dev/null 2>&1; then
            log_info "Stopping PTP slave (PID: $slave_pid)"
            kill "$slave_pid" 2>/dev/null || true
            sleep 1
        fi
        rm "$slave_pid_file"
    fi
    
    # Forcefully kill any remaining ptp4l processes
    pkill -f "ptp4l.*veth_ptp" 2>/dev/null || true
    
    log_success "PTP processes stopped"
}

# Remove virtual interfaces
cleanup_veth() {
    log_info "Cleaning up virtual interfaces..."
    
    # Remove the bridge if it exists
    if ip link show "$BRIDGE_NAME" &>/dev/null; then
        ip link set "$BRIDGE_NAME" down 2>/dev/null || true
        ip link del "$BRIDGE_NAME" 2>/dev/null || true
    fi
    
    # Remove veth pair if it exists
    if ip link show "$VETH_MASTER" &>/dev/null; then
        ip link set "$VETH_MASTER" down 2>/dev/null || true
        ip link del "$VETH_MASTER" 2>/dev/null || true
    fi
    
    log_success "Virtual interfaces cleaned up"
}

# Archive logs
archive_logs() {
    if [[ -d "$PID_DIR" ]]; then
        log_info "Archiving logs..."
        
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local archive_dir="$PROJECT_DIR/debug_logs_$timestamp"
        
        if [[ -f "$PID_DIR/master.log" ]] || [[ -f "$PID_DIR/slave.log" ]]; then
            mkdir -p "$archive_dir"
            cp "$PID_DIR"/*.log "$archive_dir" 2>/dev/null || true
            log_success "Logs archived to: $archive_dir"
        fi
    fi
}

# Main execution
main() {
    log_info "==============================================="
    log_info "Stopping PTP Debug Session"
    log_info "==============================================="
    echo ""
    
    check_root
    stop_processes
    cleanup_veth
    archive_logs
    
    echo ""
    log_success "Debug session stopped and cleaned up."
    echo ""
}

# Run main function
main "$@"
