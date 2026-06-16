#!/bin/bash

#
# Quick reference guide for PTP debugging
#

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║          LinuxPTP Software Timestamping Debug Setup - Quick Guide           ║
╚════════════════════════════════════════════════════════════════════════════╝

█ QUICK START
═════════════════════════════════════════════════════════════════════════════

1. Start the debug session:
   sudo bash setup_debug_veth.sh

2. Monitor in real-time:
   bash monitor_debug.sh

3. Stop when done:
   sudo bash stop_debug.sh


█ DETAILED STEPS
═════════════════════════════════════════════════════════════════════════════

STEP 1: Initial Setup
──────────────────────
$ cd /home/sudarshanmk/Documents/linuxptp
$ sudo bash setup_debug_veth.sh

What it does:
  • Compiles the linuxptp project
  • Creates virtual ethernet pair (veth_ptp_master ↔ veth_ptp_slave)
  • Configures software timestamping on both interfaces
  • Starts PTP master process on veth_ptp_master
  • Starts PTP slave process on veth_ptp_slave
  • Waits for synchronization


STEP 2: Real-time Monitoring
─────────────────────────────
$ bash monitor_debug.sh

Interactive commands:
  • r - Force refresh
  • l - View full master log
  • s - View full slave log
  • t - Capture network traffic (tcpdump)
  • q - Quit

Or view logs directly:
$ bash view_debug.sh                    # View both logs side-by-side
$ bash view_debug.sh master             # View master log only
$ bash view_debug.sh slave              # View slave log only
$ tail -f /tmp/ptp_debug/master.log     # Raw tail of master
$ tail -f /tmp/ptp_debug/slave.log      # Raw tail of slave


STEP 3: Network Debugging
──────────────────────────
View PTP messages in real-time:
$ sudo tcpdump -i veth_ptp_master -n 'udp port 319 or udp port 320'
$ sudo tcpdump -i veth_ptp_slave -n 'udp port 319 or udp port 320'

Check active connections:
$ netstat -un | grep -E '319|320'

Monitor interface statistics:
$ watch -n 1 'ip -s link show veth_ptp_master'
$ watch -n 1 'ip -s link show veth_ptp_slave'


STEP 4: Stop and Cleanup
──────────────────────────
$ sudo bash stop_debug.sh

What it does:
  • Stops PTP master and slave processes
  • Removes virtual ethernet interfaces
  • Archives logs with timestamp in debug_logs_YYYYMMDD_HHMMSS/
  • Cleans up PID files


█ CONFIGURATION CUSTOMIZATION
═════════════════════════════════════════════════════════════════════════════

To modify sync intervals:
  Edit debug_master.cfg and debug_slave.cfg
  Look for: logSyncInterval, logMinPdelayReqInterval

To change transport protocol:
  Edit network_transport setting:
    UDPv4   - UDP over IPv4 (current)
    L2      - Raw Ethernet (Layer 2)

To enable hardware timestamping (if available):
  Edit time_stamping setting:
    software  - Software timestamping (current)
    hardware  - Hardware timestamping (if NIC supports it)

After making changes, restart:
  sudo bash stop_debug.sh
  sudo bash setup_debug_veth.sh


█ TROUBLESHOOTING
═════════════════════════════════════════════════════════════════════════════

❌ "Permission denied":
   • Use: sudo bash setup_debug_veth.sh

❌ No synchronization after several minutes:
   • Check logs: bash view_debug.sh
   • Verify interfaces: ip link show | grep veth
   • Kill old processes: sudo pkill -f ptp4l

❌ "Port already in use":
   • Find process: sudo netstat -tulpn | grep 319
   • Kill it: sudo kill -9 <PID>

❌ Compilation errors:
   • Install tools: sudo apt-get install build-essential gcc make
   • Clean: make distclean
   • Rebuild: make -j$(nproc)

❌ Virtual interfaces won't create:
   • Check if already exist: ip link show veth_ptp_*
   • Remove manually: sudo ip link del veth_ptp_master
   • Try setup again


█ UNDERSTANDING OUTPUT
═════════════════════════════════════════════════════════════════════════════

Master Log:
  ptp4l[timestamp]: selected best master clock 8c0b.6600.38f9ef
  ptp4l[timestamp]: port 1: MASTER

Slave Log:
  ptp4l[timestamp]: selected best master clock 8c0b.6600.38f9ef
  ptp4l[timestamp]: port 1: SLAVE
  ptp4l[timestamp]: rms   12345 max   23456 freq  +234567 +/-  45678 delay    567 +/-   678

Sync Statistics Meaning:
  • rms     - Root Mean Square offset (clock error)
  • max     - Maximum clock offset observed
  • freq    - Frequency correction being applied
  • +/-     - Frequency stability (smaller is better)
  • delay   - Network propagation delay


█ ARCHITECTURE
═════════════════════════════════════════════════════════════════════════════

       Master Process                    Slave Process
              ▲                                 ▲
              │                                 │
              │ SO_TIMESTAMPING                 │ SO_TIMESTAMPING
              │ (Software)                      │ (Software)
              │                                 │
    ┌─────────┴─────────┐           ┌─────────┴─────────┐
    │ veth_ptp_master   │◄─────────►│ veth_ptp_slave    │
    │ (Virtual NIC)     │ UDP 319/  │ (Virtual NIC)     │
    │                   │ 320       │                   │
    └─────────┬─────────┘           └─────────┬─────────┘
              │                                 │
              └─────────────┬───────────────────┘
                            │
                   Kernel Network Stack
                   (Software Timestamping)


█ FILE LOCATIONS
═════════════════════════════════════════════════════════════════════════════

Configuration files:
  • debug_master.cfg          - Master PTP configuration
  • debug_slave.cfg           - Slave PTP configuration

Control scripts:
  • setup_debug_veth.sh       - Start debug session (requires sudo)
  • stop_debug.sh             - Stop debug session (requires sudo)
  • view_debug.sh             - View log files
  • monitor_debug.sh          - Real-time monitoring dashboard
  • quick_guide.sh            - This file

Log files:
  • /tmp/ptp_debug/master.log - Master process output
  • /tmp/ptp_debug/slave.log  - Slave process output
  • debug_logs_*/             - Archived logs (after stop)

PID files:
  • /tmp/ptp_debug/master.pid - Master process ID
  • /tmp/ptp_debug/slave.pid  - Slave process ID


█ ADVANCED USAGE
═════════════════════════════════════════════════════════════════════════════

Run only master (no slave):
  $ sudo ./ptp4l -i veth_ptp_master -f debug_master.cfg -m

Run only slave (no master):
  $ sudo ./ptp4l -i veth_ptp_slave -f debug_slave.cfg

Capture network traffic to file:
  $ sudo tcpdump -i veth_ptp_master -w ptp_traffic.pcap -n 'udp port 319'

View captured traffic:
  $ sudo tcpdump -r ptp_traffic.pcap -A

Monitor clock adjustments (if hardware clock available):
  $ watch -n 1 'cat /proc/net/ptp/*/clock_name 2>/dev/null'


█ MORE INFORMATION
═════════════════════════════════════════════════════════════════════════════

Full documentation: DEBUG_SETUP.md
LinuxPTP homepage: http://linuxptp.sourceforge.net/
PTP RFC 5905:      https://tools.ietf.org/html/rfc5905


Press Ctrl+C to exit this guide.

EOF
