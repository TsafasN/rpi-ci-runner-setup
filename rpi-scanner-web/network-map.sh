#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Auto-detect the first active, non-loopback, non-virtual network interface
detect_interface() {
    ip -o link show | awk -F': ' '{print $2}' | while read -r iface; do
        if [[ "$iface" != "lo" && "$iface" != docker* && "$iface" != veth* && "$iface" != br* && "$iface" != vmnet* ]]; then
            state=$(cat /sys/class/net/"$iface"/operstate)
            if [[ "$state" == "up" ]]; then
                echo "$iface"
                return
            fi
        fi
    done
}

get_pi_model() {
    local mac="$1"
    local hostname="$2"
    local model=""

    # Check MAC OUI prefixes (lowercase)
    case "$mac" in
        b8:27:eb*) model="Raspberry Pi 1/Zero/Zero W" ;;
        dc:a6:32*) model="Raspberry Pi 3/4" ;;
        e4:5f:01*) model="Raspberry Pi 4+" ;;
        28:cd:c1*) model="Raspberry Pi 4B (newer batches)" ;;
        44:17:93*) model="Raspberry Pi 5" ;;
    esac

    # If no match by MAC, try hostname pattern matching
    if [[ -z "$model" ]]; then
        if [[ "$hostname" =~ raspberrypi ]]; then
            model="Raspberry Pi (model unknown)"
        fi
    fi

    echo "$model"
}

is_host_alive() {
    local ip=$1
    # Ping with 1 packet, wait max 1 second
    ping -c 1 -W 2 "$ip" &>/dev/null
    return $?
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: sudo $0"
    echo "Scans local network for devices and identifies Raspberry Pis."
    exit 0
fi

# Suggest sudo at the start if not run as root
if [[ $EUID -ne 0 ]]; then
  echo -e "${YELLOW}⚠️  This script requires root privileges to run arp-scan.${NC}"
  echo "Please run with sudo:"
  echo "sudo $0 $*"
  exit 1
fi

# Check for required tools
for cmd in arp-scan host; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "❌ Missing required command: $cmd. Please install it."
        exit 1
    fi
done

echo -e "\n🔍 Auto-detecting Host active network interface..."
iface=$(detect_interface)

if [[ -z "$iface" ]]; then
    echo -e "${RED}❌ No active non-loopback network interface found.${NC}"
    exit 1
fi

echo -e "✅ Host using interface: ${GREEN}$iface${NC}"
echo -e "\n🔍 Scanning network..."

# Run arp-scan and collect IP, MAC
results=$(sudo arp-scan --interface="$iface" --localnet | grep -Eo '([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+([a-fA-F0-9:]{17})')

if [[ -z "$results" ]]; then
    echo "⚠️  No devices found."
    exit 0
fi

declare -a devices=()

echo -e "${GREEN}✅ Devices Found 📋:${NC}"
printf "%-16s %-20s %-40s\n" "IP Address" "MAC Address" "Hostname"

while read -r line; do
    ip=$(echo "$line" | awk '{print $1}')
    mac=$(echo "$line" | awk '{print $2}' | tr '[:upper:]' '[:lower:]')

    if ! is_host_alive "$ip"; then
        # Optionally print or skip silently
        hostname="(unreachable)"
        printf "%-16s %-20s %-40s\n" "$ip" "$mac" "$hostname"
        echo -e "${YELLOW}⚠️ Host $ip is not responding to ping.${NC}"
        # Still store it if you want to include unreachable in devices array
        devices+=("$ip|$mac|$hostname")
        continue
    fi

    # Try reverse DNS
    hostname=$(host "$ip" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        hostname="(unknown)"
    else
        hostname=$(echo "$hostname" | awk '/domain name pointer/ {print $5}' | sed 's/\.$//')
        [[ -z "$hostname" || "$hostname" == "$ip" ]] && hostname="(unknown)"
    fi


    printf "%-16s %-20s %-40s\n" "$ip" "$mac" "$hostname"
    
    # Store for later use in RPi filtering
    devices+=("$ip|$mac|$hostname")
done <<< "$results"

# Raspberry Pi detection
echo -e "\n🔍 Searching for Raspberry Pis on your network..."
echo -e "${GREEN}✅ Raspberry Pi Devices 📋:${NC}"
printf "%-16s %-25s %-25s %-30s\n" "IP Address" "MAC Address" "Hostname" "Model"

for entry in "${devices[@]}"; do
    IFS='|' read -r ip mac hostname <<< "$entry"

    # Raspberry Pi MAC OUIs (prefixes)
    # b8:27:eb - Older Raspberry Pi Foundation Ethernet/Wi-Fi
    # dc:a6:32 - Raspberry Pi Wi-Fi
    # e4:5f:01 - Newer Raspberry Pi models
    # 28:cd:c1 - Recent Raspberry Pi MAC prefix
    # 44:17:93 - Pi 5 (Sony Corporation assigned MAC OUI)

    if [[ "$mac" == b8:27:eb:* || "$mac" == dc:a6:32:* || "$mac" == e4:5f:01:* || "$mac" == 28:cd:c1:* || "$mac" == 44:17:93:* ]]; then
        pi_model=$(get_pi_model "$mac" "$hostname")
        printf "%-16s %-25s %-25s %-30s\n" "$ip" "$mac" "$hostname" "$pi_model"
    fi
done
