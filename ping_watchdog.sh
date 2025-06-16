#!/bin/bash

# Default configuration
TARGET=${PING_TARGET:-"8.8.8.8"}
PING_INTERVAL=${PING_INTERVAL:-60}
PING_TIMEOUT=${PING_TIMEOUT:-5}
PING_COUNT=${PING_COUNT:-1}
SERVICE_TAG="ping-watchdog"
LAST_STATUS="unknown"
LOG_FILE="/var/log/ping-watchdog.log"

# Function to log messages with timestamp
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | logger -t $SERVICE_TAG
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a ip_parts <<< "$ip"
        for part in "${ip_parts[@]}"; do
            if [ "$part" -gt 255 ] || [ "$part" -lt 0 ]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Function to handle script termination
cleanup() {
    log_message "Service stopping. Last status: $LAST_STATUS"
    exit 0
}

# Set up signal handling
trap cleanup SIGTERM SIGINT

# Validate target IP
if ! validate_ip "$TARGET"; then
    log_message "ERROR - Invalid IP address: $TARGET"
    exit 1
fi

log_message "Service started. Monitoring $TARGET (Interval: ${PING_INTERVAL}s, Timeout: ${PING_TIMEOUT}s)"

# Notify systemd the service is ready
systemd-notify --ready

while true; do
    # Get ping statistics
    ping_result=$(ping -c $PING_COUNT -W $PING_TIMEOUT "$TARGET" 2>&1)
    ping_exit=$?

    if [ $ping_exit -eq 0 ]; then
        # Extract packet loss and latency information
        packet_loss=$(echo "$ping_result" | grep "packet loss" | awk '{print $6}')
        latency=$(echo "$ping_result" | grep "min/avg/max" | awk '{print $4}')

        if [ "$LAST_STATUS" != "up" ]; then
            log_message "Network UP - $TARGET is reachable (Packet Loss: $packet_loss, Latency: $latency)"
            LAST_STATUS="up"
        fi
    else
        if [ "$LAST_STATUS" != "down" ]; then
            log_message "Network DOWN - $TARGET is not reachable! (Error: $ping_exit)"
            LAST_STATUS="down"
        fi
    fi

    # Tell systemd the service is still healthy
    systemd-notify WATCHDOG=1
    sleep $PING_INTERVAL
done