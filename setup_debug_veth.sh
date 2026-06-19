#!/bin/bash

#
# Setup script for debugging linuxptp with software timestamping
# Creates virtual ethernet interfaces for master/slave PTP communication
#

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Virtual interface names
VETH_MASTER="veth_ptp_master"
VETH_SLAVE="veth_ptp_slave"
VETH_MASTER_IP="192.168.40.20"
VETH_SLAVE_IP="192.168.41.20"
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

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=0
    
    if ! command -v make &> /dev/null; then
        log_error "make not found"
        missing=1
    fi
    
    if ! command -v gcc &> /dev/null; then
        log_error "gcc not found"
        missing=1
    fi
    
    if ! command -v ip &> /dev/null; then
        log_error "ip command not found"
        missing=1
    fi
    
    if ! command -v ethtool &> /dev/null; then
        log_warn "ethtool not found (optional, but recommended)"
    fi
    
    if [[ $missing -eq 1 ]]; then
        log_error "Please install missing tools"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Compile the project
compile_project() {
    log_info "Compiling linuxptp project..."
    
    if [[ ! -f "$PROJECT_DIR/makefile" ]]; then
        log_error "makefile not found in $PROJECT_DIR"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    
    # Clean and rebuild
    make distclean 2>/dev/null || true
    
    if ! make -j$(nproc); then
        log_error "Compilation failed"
        exit 1
    fi
    
    log_success "Compilation completed"
    
    # Verify ptp4l was built
    if [[ ! -f "$PROJECT_DIR/ptp4l" ]]; then
        log_error "ptp4l binary not found after compilation"
        exit 1
    fi
}

# Clean up virtual interfaces
cleanup_veth() {
    log_info "Cleaning up any existing virtual interfaces..."
    
    # Remove the bridge if it exists
    if ip link show "$BRIDGE_NAME" &>/dev/null; then
        ip link set "$BRIDGE_NAME" down 2>/dev/null || true
        ip link del "$BRIDGE_NAME" 2>/dev/null || true
    fi
    
    # Remove veth pair if it exists
    if ip link show "$VETH_MASTER" &>/dev/null; then
        ip link del "$VETH_MASTER" 2>/dev/null || true
    fi
}

# Create virtual ethernet pair
create_veth() {
    log_info "Creating virtual ethernet interface pair..."
    
    # Create veth pair
    ip link add "$VETH_MASTER" type veth peer name "$VETH_SLAVE"
    ip addr add "$VETH_MASTER_IP"/24 dev "$VETH_MASTER"
    ip addr add "$VETH_SLAVE_IP"/24 dev "$VETH_SLAVE"
    
    # Set interfaces up
    ip link set "$VETH_MASTER" up
    ip link set "$VETH_SLAVE" up
    
    #ip addr show "$VETH_MASTER"
    #ip addr show "$VETH_SLAVE"

    log_success "Virtual ethernet pair created: $VETH_MASTER <-> $VETH_SLAVE"
}

# Configure virtual interfaces for software timestamping
check_timestamping_capabilities() {
    log_info "Check if software timestamping is available on virtual interfaces..."
    
    # Enable software timestamping
    for iface in "$VETH_MASTER" "$VETH_SLAVE"; do
        log_info "Configuring $iface..."
        
        # Check current timestamping capabilities
        if command -v ethtool &> /dev/null; then
            log_info "Current timestamping capabilities for $iface:"
            ethtool -T "$iface" || log_warn "Could not query timestamping capabilities"
        fi
    done
    
    #log_success "Software timestamping configured"
}

# Create PID files directory
create_pid_dir() {
    local pid_dir="/tmp/ptp_debug"
    mkdir -p "$pid_dir"
    chmod 755 "$pid_dir"
    echo "$pid_dir"
}


# Display interface status
show_interface_status() {
    log_info "Virtual interface status:"
    echo ""
    ip addr show "$VETH_MASTER"
    echo ""
    ip addr show "$VETH_SLAVE"
    echo ""
}

# Main execution
main() {
    log_info "==============================================="
    log_info "LinuxPTP Debug Setup with Virtual Ethernet"
    log_info "Software Timestamping"
    log_info "==============================================="
    echo ""
    
    check_root
    check_prerequisites
    cleanup_veth
    create_veth
    show_interface_status
    check_timestamping_capabilities
}

# Run main function
main "$@"
