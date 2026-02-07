#!/bin/bash

# ─────────────────────────────────────────────
# Anonymizer Script v1.3
# Author: 0warn
# Date: 2025-06-28
# Description: Advanced MAC/IP/Tor anonymization tool
# ─────────────────────────────────────────────

# Global vars
version="v1.3"
interface=""
original_mac=""
original_ip=""
tor_service="tor"
show_banner=true
log_file="/var/log/harekrishna.log"
state_file="/tmp/harekrishna.state"
session_id=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
debug_mode=false

# ─────────────────────────────────────────────

log() {
    echo -e "[\033[0;32m$(date +'%F %T')\033[0m] [\033[0;34m$session_id\033[0m] $1" | tee -a "$log_file"
}


display_banner() {
    echo -e "\033[1;36m"
    echo "       ╔════════════════════════════════════════════╗"
    echo "       ║            🔒 HARE KRISHNA  v1.3           ║"
    echo "       ╠════════════════════════════════════════════╣"
    echo "       ║  MAC/IP randomizer & Tor-based proxy tool  ║"
    echo "       ╚════════════════════════════════════════════╝"
    echo -e "\033[0m"
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -st, --start                 Start anonymization
  -sp, --stop                  Stop anonymization
  -cp, --changeip              Change IP address (via Tor)
  -cm -m <mac>, --changemac    Change MAC address to specific value
  -ss, --status                Show anonymization status
  -l, --logs                   View anonymizer logs
  -d, --debug                  Enable debug output
  -cip, --checkip              Check your public ip address in tor
  -v, --version                Show Version of this script
  -h, --help                   Show help message
  -a, --auto                   Auto change ip and mac address as your time for infinity loop until you stop it

Example:
  sudo bash $0 -st
  sudo bash $0 -cm -m 00:11:22:33:44:55
Else:
  sudo bash hare-krishna.sh -h (to see the help)
EOF
    exit 0
}

check_dependencies() {
    for cmd in ip curl macchanger systemctl tor; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required tool '$cmd' is missing." >&2
            exit 1
        fi
    done
}

detect_interface() {
    interface=$(ip route | awk '/default/ {print $5; exit}')
    if [ -z "$interface" ]; then
        interface=$(ls /sys/class/net | grep -Ev 'lo|docker' | head -n 1)
    fi
    if [ -z "$interface" ]; then
        echo "Error: Could not detect a valid network interface." >&2
        exit 1
    fi
    $debug_mode && echo "[DEBUG] Detected interface: $interface"
}

save_original_state() {
    if [[ -f "$state_file" ]]; then
        $debug_mode && echo "[DEBUG] Original MAC/IP already saved."
        return
    fi
    original_mac=$(cat /sys/class/net/$interface/address)
    original_ip=$(curl -s http://api.ipify.org)
    echo "$original_mac|$original_ip" > "$state_file"
    $debug_mode && echo "[DEBUG] Original MAC/IP saved to $state_file"
}

load_original_state() {
    if [[ -f "$state_file" ]]; then
        IFS="|" read -r original_mac original_ip < "$state_file"
    fi
}

start_tor() {
    sudo systemctl start "$tor_service"
    sleep 5
    if ! pgrep -x "$tor_service" &>/dev/null; then
        echo "Error: Tor failed to start."
        exit 1
    fi
}

start_anonymization() {
    detect_interface

    if [[ -f "$state_file" ]]; then
        echo "⚠️  Anonymization session already active. Use '-sp' to stop first."
        exit 1
    fi

    save_original_state
    log "Original MAC: $original_mac"
    log "Original IP : $original_ip"

    sudo ip link set "$interface" down
    new_mac=$(macchanger -r "$interface" | grep "New MAC" | awk '{print $3}')
    sudo ip link set "$interface" up
    log "MAC changed to: $new_mac"

    start_tor
    export http_proxy="socks5h://127.0.0.1:9050"
    export https_proxy="socks5h://127.0.0.1:9050"

    log "Anonymization started."
    echo -e "\033[1;31m"
    echo "✅ Anonymization complete."
    echo -e "\033[0m"
}

stop_anonymization() {
    detect_interface
    load_original_state

    if [[ -n "$original_mac" ]]; then
        sudo ip link set "$interface" down
        sudo macchanger -m "$original_mac" "$interface"
        sudo ip link set "$interface" up
        log "MAC restored: $original_mac"
    fi

    sudo systemctl stop "$tor_service"
    unset http_proxy https_proxy
    log ">> Tor stopped. Original settings restored. Don't worry"

    rm -f "$state_file"
}

change_mac() {
    detect_interface
    if [[ ! "$1" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        echo "Invalid MAC format."
        exit 1
    fi
    sudo ip link set "$interface" down
    sudo macchanger -m "$1" "$interface"
    sudo ip link set "$interface" up
    log "Manually set MAC to: $1"
}

change_ip() {
    echo -e "\033[1;31m"
    echo "[*] Wait a minute, Your IP address is changing......."
    echo -e "\033[0m"
    sudo systemctl restart "$tor_service"
    sleep 5
    tor_ip=$(curl --max-time 10 -s --proxy socks5h://127.0.0.1:9050 http://api.ipify.org)
    log "New Tor IP  : ${tor_ip:-Unavailable}"
}

status() {
    detect_interface
    echo "───────────── STATUS REPORT ─────────────"
    echo "Interface   : $interface"
    if [[ -f "/sys/class/net/$interface/address" ]]; then
        echo "MAC Address : $(cat /sys/class/net/$interface/address)"
    else
        echo "MAC Address : Unavailable"
    fi
    echo "Tor Running : $(systemctl is-active "$tor_service")"
    echo "───────────── END REPORT ────────────────"
}

show_version() {
    echo "🔖 Hare Krishna Tool Version: $version"
}

check_ip_tor() {
    echo -e "\033[1;33m"
    echo "  ->> Wait for 15 secound. Tor can take some time. Your IP address will show." 
    echo -e "\033[0m"
    sleep 5
    tor_ip=$(curl --max-time 10 -s --proxy socks5h://127.0.0.1:9050 http://api.ipify.org)
    log "YOUR TOR IP  : ${tor_ip:-Unavailable}"
}

trap_ctrlc() {
    echo ""
    echo "CTRL+C detected. Restoring original state..."
    stop_anonymization
    exit 0
}
trap trap_ctrlc INT

view_logs() {
    [[ -f "$log_file" ]] && (echo -e "\033[0;34mLogs:\033[0m" && cat "$log_file") || echo "No logs found."
}

auto_change_ip() {
    detect_interface
    save_original_state

    interval="${1:-300}"  # Default to 300 seconds (5 mins)
    echo -e "\033[1;35m[INFO]\033[0m Starting advanced Tor IP changer. Interval: $interval seconds"
    log "[#] Auto IP changer initialized. Will rotate IP every $interval seconds."

    while true; do
        echo -e "\033[1;33m[*]\033[0m Restarting Tor service to request a new identity..."
        sudo systemctl restart "$tor_service"
        sleep 10

        # Loop to verify Tor is up and proxy is working
        tor_ready=false
        for attempt in {1..5}; do
            echo -ne "\033[1;36m[~]\033[0m Checking Tor status (attempt $attempt)... "
            test_ip=$(curl -s --max-time 10 --proxy socks5h://127.0.0.1:9050 http://ifconfig.me)
            if [[ -n "$test_ip" ]]; then
                tor_ready=true
                break
            else
                echo "Unavailable"
                sleep 5
            fi
        done

        if [[ "$tor_ready" = true ]]; then
            log "[✓] New Tor IP: $test_ip"
            echo -e "\033[1;32m[✓] New Tor IP: $test_ip\033[0m"
        else
            log "[✗] Failed to fetch new Tor IP after 5 attempts"
            echo -e "\033[1;31m[✗] Tor did not respond in time. Skipping this cycle.\033[0m"
        fi

        echo -e "\033[1;36m[*]\033[0m Sleeping for $interval seconds before next IP change...\n"
        sleep "$interval"
    done
}

# ─────────────────────────────────────────────
# MAIN
check_dependencies
[[ "$EUID" -ne 0 ]] && { echo "Run as root."; exit 1; }

$show_banner && display_banner

action_run=false
args=("$@")

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -st|--start) start_anonymization; action_run=true ;;
        -sp|--stop) stop_anonymization; action_run=true ;;
        -cp|--changeip) change_ip; action_run=true ;;
        -cm|--changemac) shift; [[ -z "$1" ]] && { echo "MAC address missing."; exit 1; }; change_mac "$1"; action_run=true ;;
        -ss|--status) status; action_run=true ;;
        -l|--logs) view_logs; exit 0 ;;
        -d|--debug) debug_mode=true ;;
        -nb) show_banner=false ;;
        -cip|--checkip) check_ip_tor; action_run=true;;
        -v|--version) show_version; exit 0 ;;
        -h|--help) usage ;;
        -a|--auto) shift; auto_change_ip "$1"; action_run=true ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

[[ "$action_run" = false ]] && status
