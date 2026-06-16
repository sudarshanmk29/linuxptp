#!/bin/bash

#
# Advanced monitoring script for PTP debug session
# Shows real-time statistics and network activity
#

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PID_DIR="/tmp/ptp_debug"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

show_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           LinuxPTP Software Timestamping Debug             ║${NC}"
    echo -e "${CYAN}║                  Real-time Monitor                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_process_status() {
    echo -e "${YELLOW}═══ Process Status ═══${NC}"
    
    local master_pid=$(cat "$PID_DIR/master.pid" 2>/dev/null)
    local slave_pid=$(cat "$PID_DIR/slave.pid" 2>/dev/null)
    
    if [[ -n "$master_pid" ]] && ps -p "$master_pid" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Master PID: $master_pid"
        echo "   Command: $(ps -o cmd= -p $master_pid | head -c 60)..."
    else
        echo -e "${RED}✗${NC} Master: Not running"
    fi
    
    if [[ -n "$slave_pid" ]] && ps -p "$slave_pid" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Slave PID: $slave_pid"
        echo "   Command: $(ps -o cmd= -p $slave_pid | head -c 60)..."
    else
        echo -e "${RED}✗${NC} Slave: Not running"
    fi
    
    echo ""
}

show_interface_stats() {
    echo -e "${YELLOW}═══ Interface Statistics ═══${NC}"
    
    for iface in veth_ptp_master veth_ptp_slave; do
        if ip link show "$iface" &>/dev/null; then
            local stats=$(cat /proc/net/dev | grep "$iface" | awk '{print $2, $3, $10, $11}')
            if [[ -n "$stats" ]]; then
                read rx tx txerr rxdrop <<<$(echo $stats)
                echo -e "${BLUE}$iface:${NC}"
                echo "   RX: $rx bytes | TX: $tx bytes"
                echo "   RX Drop: $rxdrop | TX Err: $txerr"
            fi
        fi
    done
    
    echo ""
}

show_ptp_stats() {
    echo -e "${YELLOW}═══ Recent PTP Activity ═══${NC}"
    
    echo -e "${BLUE}Master (last 3 lines):${NC}"
    tail -n 3 "$PID_DIR/master.log" 2>/dev/null | sed 's/^/  /'
    
    echo ""
    
    echo -e "${BLUE}Slave (last 3 lines):${NC}"
    tail -n 3 "$PID_DIR/slave.log" 2>/dev/null | sed 's/^/  /'
    
    echo ""
}

show_sync_status() {
    echo -e "${YELLOW}═══ Synchronization Status ═══${NC}"
    
    if grep -q "rms" "$PID_DIR/slave.log" 2>/dev/null; then
        local last_stats=$(grep "rms" "$PID_DIR/slave.log" | tail -n 1)
        echo -e "${GREEN}✓ Synchronized${NC}"
        echo "   $last_stats"
    else
        echo -e "${YELLOW}! Synchronizing...${NC}"
    fi
    
    echo ""
}

show_udp_connections() {
    echo -e "${YELLOW}═══ UDP Connections (PTP Ports 319-320) ═══${NC}"
    
    netstat -un 2>/dev/null | grep -E '319|320' || echo "  No active connections"
    
    echo ""
}

show_help() {
    echo -e "${YELLOW}═══ Commands ═══${NC}"
    echo "  'q'  - Quit"
    echo "  'r'  - Refresh (default refresh every 5 seconds)"
    echo "  'l'  - Show full master log"
    echo "  's'  - Show full slave log"
    echo "  't'  - Show tcpdump traffic"
    echo ""
}

show_tcpdump() {
    echo -e "${YELLOW}═══ PTP Network Traffic (press Ctrl+C to stop) ═══${NC}"
    echo ""
    
    if command -v tcpdump &> /dev/null; then
        # Check if we can use tcpdump (requires root)
        if [[ $EUID -eq 0 ]]; then
            tcpdump -i veth_ptp_master -n 'udp port 319 or udp port 320' -c 20
        else
            echo -e "${RED}tcpdump requires root privileges${NC}"
        fi
    else
        echo -e "${RED}tcpdump not installed${NC}"
    fi
}

# Main loop
main() {
    if [[ ! -d "$PID_DIR" ]]; then
        echo -e "${RED}Error: PTP debug session not found ($PID_DIR)${NC}"
        exit 1
    fi
    
    local auto_refresh=5
    
    while true; do
        show_header
        show_process_status
        show_interface_stats
        show_ptp_stats
        show_sync_status
        show_udp_connections
        show_help
        
        echo -e "${CYAN}Next refresh in ${auto_refresh}s (or press a key)${NC}"
        read -t "$auto_refresh" -n 1 cmd
        
        case "$cmd" in
            q|Q)
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            r|R)
                continue
                ;;
            l|L)
                echo -e "${YELLOW}Full Master Log:${NC}"
                cat "$PID_DIR/master.log"
                read -p "Press Enter to continue..."
                ;;
            s|S)
                echo -e "${YELLOW}Full Slave Log:${NC}"
                cat "$PID_DIR/slave.log"
                read -p "Press Enter to continue..."
                ;;
            t|T)
                show_tcpdump
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run main function
main "$@"
