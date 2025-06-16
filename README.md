# systemd-ping-monitor

A lightweight systemd service that monitors network connectivity by pinging a target IP address.

## Quick Setup

```bash
# 1. Create service user
sudo useradd -r -s /bin/false pingwatchdog

# 2. Install files
sudo cp ping_watchdog.sh /usr/local/sbin/
sudo cp ping-watchdog.service /etc/systemd/system/
sudo chmod +x /usr/local/sbin/ping_watchdog.sh
sudo chown pingwatchdog:pingwatchdog /usr/local/sbin/ping_watchdog.sh

# 3. Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ping-watchdog
sudo systemctl start ping-watchdog
```

## Configuration

Edit `/etc/systemd/system/ping-watchdog.service` to customize:
- `PING_TARGET`: IP to monitor (default: 8.8.8.8)
- `PING_INTERVAL`: Check frequency in seconds (default: 60)
- `PING_TIMEOUT`: Ping timeout in seconds (default: 5)

## Monitoring

```bash
# Check service status
systemctl status ping-watchdog

# View logs
journalctl -u ping-watchdog -f
```

## Features
- Monitors network availability
- Logs only on state changes (up/down)
- Uses systemd-notify for efficient health checking
- Automatically restarts on failure or timeout
