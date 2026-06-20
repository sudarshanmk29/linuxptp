# LinuxPTP Debug Setup with Software Timestamping

This guide helps you set up a debugging environment for LinuxPTP using software timestamping with virtual ethernet interfaces.

## Overview

The setup creates:

- **Virtual Ethernet Pair**: `veth_ptp_master` ↔ `veth_ptp_slave`
- **PTP Master Process**: Running on `/var/run/ptp/ptp4l_master` interface
- **PTP Slave Process**: Running on `/var/run/ptp/ptp4l_slave` interface
- **Software Timestamping**: Using the `SO_TIMESTAMPING` socket option

## Prerequisites

```bash
# Required tools
- make
- gcc
- root/sudo privileges
- ip command (iproute2)
- ethtool (recommended, for checking capabilities)
```

Install on Ubuntu/Debian:

```bash
sudo apt-get install build-essential iproute2 ethtool
```

## Quick Start

### 1. Setup and Start

```bash
cd /home/sudarshanmk/Documents/linuxptp

# Run setup (requires sudo)
sudo bash setup_debug_veth.sh
```

This script will:

- ✓ Clean up any existing virtual interfaces
- ✓ Create virtual ethernet pair
- ✓ Configure software timestamping

```bash
#Compile the project in Release Configuration
make clean && make

#Compile the project in Debug Configuration
make clean && make DEBUG="-g -O0"
```

```bash
#Start master process
sudo ./ptp4l -i veth_ptp_master -f configs/automotive-master.cfg -m

#Start Slave process
sudo ./ptp4l -i veth_ptp_slave -f configs/automotive-slave.cfg -m -s
```

## Configuration Details

### Master Configuration (`automotive-master.cfg`)

Key settings:

- `time_stamping = software` - Enable software timestamping
- `network_transport = UDPv4` - Use UDP for easier software timestamping
- `delay_mechanism = E2E` - End-to-end delay mechanism
- `serverOnly = 1` - Act as master
- `logging_level = 7` - Maximum verbosity for debugging
- `logSyncInterval = -3` - Sync interval (1 message per 8 seconds)

### Slave Configuration (`automotive-slave.cfg`)

Key settings:

- `time_stamping = software` - Enable software timestamping
- `network_transport = UDPv4` - Use UDP for easier software timestamping
- `clientOnly = 1` - Act as slave/client
- `logging_level = 7` - Maximum verbosity for debugging
- Enhanced servo settings for faster convergence

## Virtual Interface Details

The setup creates a virtual ethernet pair using Linux kernel's veth driver:

```
┌─────────────────────┐         ┌─────────────────────┐
│   ptp4l Master      │         │   ptp4l Slave       │
│                     │         │                     │
│  veth_ptp_master   ◄─────────►  veth_ptp_slave     │
└─────────────────────┘         └─────────────────────┘
```

Both interfaces:

- Support software timestamping via `SO_TIMESTAMPING`
- Are configured with full loopback for testing
- Use UDP/IPv4 multicast for PTP communication
- Have high debug logging enabled

## Understanding the Output

### Master Output Example

```
ptp4l[1234.567]: selected best master clock 8c0b.6600.38f9ef
ptp4l[1234.567]: MASTER_ONLY
ptp4l[1234.567]: port 1: LISTENING
ptp4l[1234.567]: port 1: MASTER
```

### Slave Output Example

```
ptp4l[1234.789]: selected best master clock 8c0b.6600.38f9ef
ptp4l[1234.789]: port 1: LISTENING
ptp4l[1234.789]: port 1: MASTER
ptp4l[1234.789]: port 1: UNCALIBRATED
ptp4l[1234.789]: port 1: SLAVE
ptp4l[1234.789]: rms   12345 max   23456 freq  +234567 +/-  45678 delay    567 +/-   678
```

The `rms`, `max`, `freq`, and `delay` values show synchronization quality.

## Monitoring PTP Messages

### Option 1: Using tcpdump

```bash
# Monitor PTP messages on master interface
sudo tcpdump -i veth_ptp_master -n -A port 319 or port 320

# Monitor on slave
sudo tcpdump -i veth_ptp_slave -n -A port 319 or port 320
```

### Option 2: Check process status

```bash
# Check if processes are running
ps aux | grep ptp4l | grep veth

# Check network statistics
netstat -un | grep 319
netstat -un | grep 320
```

## Troubleshooting

### Issue: "Permission denied" when running setup

**Solution**: Run with sudo

```bash
sudo bash setup_debug_veth.sh
```

### Issue: "No synchronization" after waiting

**Check**:

```bash
# Verify interfaces exist
ip link show | grep veth

# Check if ptp4l processes are running
ps aux | grep ptp4l
```

**Common causes**:

- Port 319/320 already in use (kill existing ptp4l processes)
- Interface not properly created (check `ip addr show`)
- Configuration file issues (validate `automotive-master.cfg` and `automotive-slave.cfg`)

### Issue: Compilation fails

**Check prerequisites**:

```bash
make --version
gcc --version
```

**Clean and retry**:

```bash
cd /home/sudarshanmk/Documents/linuxptp
make distclean
make -j$(nproc)
```

## Advanced Configuration

### To use Raw Ethernet (Layer 2) instead of UDP

Edit `automotive-master.cfg` and `automotive-slave.cfg`:

```cfg
# Change from:
network_transport UDPv4

# To:
network_transport L2
```

Also change the delay mechanism for Layer 2:

```cfg
# For peer-to-peer
delay_mechanism  P2P

# Or for end-to-end
delay_mechanism  E2E
```

### To use different timestamps

Edit the config files:

```cfg
# For software timestamping (default)
time_stamping  software

# For hardware timestamping (if supported)
time_stamping  hardware

# For hardware with fallback to software
time_stamping  hardware_or_software
```

## File Locations

| File | Purpose |
|------|---------|
| `configs/automotive-master.cfg` | Master node configuration |
| `configs/automotive-slave.cfg` | Slave node configuration |
| `setup_debug_veth.sh` | Virtual Ethernet Setup Script |

## Architecture

```
Host System
├── Virtual Interface Layer
│   ├── veth_ptp_master (virtual ethernet device)
│   └── veth_ptp_slave (virtual ethernet device)
├── PTP Master Process
│   ├── Sends Announce, Sync, Follow_Up messages
│   ├── Receives Delay_Req from slave
│   └── Uses software timestamping
└── PTP Slave Process
    ├── Receives Announce, Sync, Follow_Up messages
    ├── Sends Delay_Req to master
    ├── Calculates clock offset and drift
    └── Adjusts local clock using phc2sys or clock_adjtimex
```

## Next Steps

### 1. Debug PTP Message Flow

```bash
# Terminal 3: Monitor network traffic
sudo tcpdump -i veth_ptp_master -n 'udp port 319 or udp port 320'
```

### 2. Modify Configuration

Edit `automotive-master.cfg` and `automotive-slave.cfg` for:

- Different sync intervals
- Different delay mechanisms
- Different transport protocols
- Additional logging

### 3. Add Clock Adjustment

To synchronize system clock with PTP:

```bash
sudo phc2sys -s /dev/ptp0 -c CLOCK_REALTIME -w -m
```

Or adjust clock without hardware PTP clock:

```bash
# The slave ptp4l will write clock adjustments to ntpshm
# which can be consumed by ntpd or chrony
```

## References

- LinuxPTP Project: <http://linuxptp.sourceforge.net/>
- PTP IEEE 1588: <https://en.wikipedia.org/wiki/Precision_Time_Protocol>
- Linux SO_TIMESTAMPING: <https://www.kernel.org/doc/html/latest/networking/timestamping.html>
