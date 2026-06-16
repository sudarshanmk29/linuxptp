#!/bin/bash

#
# View PTP debug logs
#

PID_DIR="/tmp/ptp_debug"

# Color output
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ $# -eq 0 ]]; then
    # No arguments - show both logs
    echo -e "${BLUE}=== Master Log ===${NC}"
    tail -f "$PID_DIR/master.log" &
    MASTER_PID=$!
    
    sleep 0.5
    
    echo -e "${BLUE}=== Slave Log ===${NC}"
    tail -f "$PID_DIR/slave.log" &
    SLAVE_PID=$!
    
    # Wait for both
    wait $MASTER_PID $SLAVE_PID 2>/dev/null
else
    case "$1" in
        master)
            echo -e "${BLUE}=== Master Log ===${NC}"
            tail -f "$PID_DIR/master.log"
            ;;
        slave)
            echo -e "${BLUE}=== Slave Log ===${NC}"
            tail -f "$PID_DIR/slave.log"
            ;;
        *)
            echo "Usage: $0 [master|slave]"
            echo "Without arguments, shows both logs"
            ;;
    esac
fi
