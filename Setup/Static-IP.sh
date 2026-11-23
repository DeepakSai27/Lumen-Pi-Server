#!/bin/bash
# Set a static IPv4 address on the wired connection (NetworkManager, Bookworm).
# Usage: sudo ./Static-IP.sh [ip/prefix] [gateway] ["dns1 dns2"]
set -e
ADDR=${1:-192.168.1.45/24}
GW=${2:-192.168.1.1}
DNS=${3:-"172.64.36.1 172.64.36.2"}
CON=$(nmcli -t -f NAME,DEVICE con show --active | grep ':eth0$' | cut -d: -f1)
[ -n "$CON" ] || { echo "no active eth0 connection"; exit 1; }

nmcli con mod "$CON" ipv4.method manual ipv4.addresses "$ADDR" ipv4.gateway "$GW" ipv4.dns "$DNS"
nmcli con up "$CON"
nmcli -g ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns con show "$CON"
