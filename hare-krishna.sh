#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────
# Anonymizer Script v1.3
# Author: 0warn
# Date: 2025-06-28
# Description: Advanced MAC/IP/Tor anonymization tool
# ─────────────────────────────────────────────

CONFIG_FILE="/etc/hare-krishna/hare-krishna.conf" # Default path

# Load configuration if available
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Warning: Configuration file not found at $CONFIG_FILE. Using default settings." >&2
fi

# Global vars (overridden by config if present)
version="v1.5"
interface="${INTERFACE:-}" # Use INTERFACE from config, or empty
original_mac=""
original_ip=""
tor_service="tor"
show_banner=true # Always show banner initially
log_file="${LOG_FILE:-/var/log/harekrishna.log}" # Use LOG_FILE from config, or default
state_file="${STATE_FILE:-/tmp/harekrishna.state}" # Use STATE_FILE from config, or default
session_id=$(uuidgen)
debug_mode=false

# ─────────────────────────────────────────────

log() {
    echo -e "[\033[0;32m$(date +'%F %T')\033[0m] [\033[0;34m$session_id\033[0m] $1" | tee -a "$log_file"
}

debug_log() {
    if $debug_mode; then
        log "[DEBUG] $1"
    fi
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
    for cmd in ip curl macchanger systemctl tor uuidgen iptables; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required tool '$cmd' is missing. Please install it." >&2
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
    debug_log "Detected interface: $interface"
}

save_original_state() {
    if [[ -f "$state_file" ]]; then
        debug_log "Original MAC/IP already saved."
        return
    fi
    original_mac=$(cat /sys/class/net/$interface/address)
    original_ip=$(curl -s --max-time 5 http://api.ipify.org || echo "0.0.0.0")
    if [[ "$original_ip" == "0.0.0.0" ]]; then
        debug_log "Could not fetch original IP, defaulting to 0.0.0.0"
    fi
    echo "$original_mac|$original_ip" > "$state_file"
    debug_log "Original MAC/IP saved to $state_file"
}

load_original_state() {
    if [[ -f "$state_file" ]]; then
        IFS="|" read -r original_mac original_ip < "$state_file"
    fi
}

start_tor() {
    if ! sudo systemctl start "$tor_service"; then
        echo "Error: Failed to start Tor service." >&2
        exit 1
    fi
    sleep 5
    if ! pgrep -x "$tor_service" &>/dev/null; then
        echo "Error: Tor failed to start after delay." >&2
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
    export http_proxy="socks5h://127.0.0.1:$TOR_PORT"
    export https_proxy="socks5h://127.0.0.1:$TOR_PORT"

    add_dns_redirect_rules
    activate_kill_switch

    log "Anonymization started."
    echo -e "\033[1;31m"
    echo "✅ Anonymization complete."
    echo -e "\033[0m"
}

add_dns_redirect_rules() {
    debug_log "Adding DNS redirect rules."
    sudo iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports "$DNS_PORT"
    sudo iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports "$DNS_PORT"
    log "DNS traffic redirected to Tor's port $DNS_PORT."
}

remove_dns_redirect_rules() {
    debug_log "Removing DNS redirect rules."
    # Use -C (check) first to avoid errors if rule doesn't exist
    sudo iptables -t nat -C OUTPUT -p udp --dport 53 -j REDIRECT --to-ports "$DNS_PORT" &>/dev/null && sudo iptables -t nat -D OUTPUT -p udp --dport 53 -j REDIRECT --to-ports "$DNS_PORT"
    sudo iptables -t nat -C OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports "$DNS_PORT" &>/dev/null && sudo iptables -t nat -D OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports "$DNS_PORT"
    log "DNS redirect rules removed."
}

activate_kill_switch() {
    debug_log "Activating kill switch."
    # Drop all outgoing traffic by default
    sudo iptables -P OUTPUT DROP
    # Allow traffic to loopback
    sudo iptables -A OUTPUT -o lo -j ACCEPT
    # Allow traffic to Tor ports (for Tor daemon)
    sudo iptables -A OUTPUT -p tcp --dport "$TOR_PORT" -j ACCEPT
    sudo iptables -A OUTPUT -p udp --dport "$TOR_PORT" -j ACCEPT
    # Allow DNS queries to Tor's DNS port
    sudo iptables -A OUTPUT -p udp --dport "$DNS_PORT" -j ACCEPT
    sudo iptables -A OUTPUT -p tcp --dport "$DNS_PORT" -j ACCEPT

    log "Kill switch activated. All non-Tor traffic blocked."
}

deactivate_kill_switch() {
    debug_log "Deactivating kill switch."
    # Remove specific rules first
    sudo iptables -D OUTPUT -o lo -j ACCEPT || true
    sudo iptables -D OUTPUT -p tcp --dport "$TOR_PORT" -j ACCEPT || true
    sudo iptables -D OUTPUT -p udp --dport "$TOR_PORT" -j ACCEPT || true
    sudo iptables -D OUTPUT -p udp --dport "$DNS_PORT" -j ACCEPT || true
    sudo iptables -D OUTPUT -p tcp --dport "$DNS_PORT" -j ACCEPT || true

    # Set default policy back to ACCEPT
    sudo iptables -P OUTPUT ACCEPT
    log "Kill switch deactivated. All traffic allowed."
}

stop_anonymization() {
    debug_log "Stopping anonymization."
    detect_interface
    load_original_state

    deactivate_kill_switch
    remove_dns_redirect_rules

    if [[ -n "$original_mac" ]]; then
        debug_log "Restoring original MAC address: $original_mac"
        sudo ip link set "$interface" down
        sudo macchanger -m "$original_mac" "$interface"
        sudo ip link set "$interface" up
        log "MAC restored: $original_mac"
    else
        debug_log "No original MAC address found to restore."
    fi

    if ! sudo systemctl stop "$tor_service"; then
        log "Warning: Failed to stop Tor service."
        echo "Warning: Tor service might still be running." >&2
    else
        debug_log "Tor service stopped."
    fi
    unset http_proxy https_proxy
    log ">> Tor stopped. Original settings restored. Don't worry"

    if [[ -f "$state_file" ]]; then
        debug_log "Removing state file: $state_file"
        rm -f "$state_file"
    else
        debug_log "State file not found: $state_file"
    fi
}

change_mac() {
    debug_log "Changing MAC to specific value: $1"
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
    if ! sudo systemctl restart "$tor_service"; then
        echo "Error: Failed to restart Tor service for IP change." >&2
        return 1
    fi
    sleep 5
    # Attempt to get IP, if fails, set to "Unavailable"
    tor_ip=$(curl --max-time 10 -s --proxy socks5h://127.0.0.1:$TOR_PORT http://api.ipify.org || echo "Unavailable")
    log "New Tor IP  : ${tor_ip}"
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
    # Attempt to get IP, if fails, set to "Unavailable"
    tor_ip=$(curl --max-time 10 -s --proxy socks5h://127.0.0.1:$TOR_PORT http://api.ipify.org || echo "Unavailable")
    log "YOUR TOR IP  : ${tor_ip}"
}
trap_ctrlc() {
    echo ""
    echo "CTRL+C detected. Restoring original state..."
    deactivate_kill_switch # Ensure kill switch is deactivated
    remove_dns_redirect_rules # Ensure DNS rules are cleaned up
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
        if ! sudo systemctl restart "$tor_service"; then
            log "[✗] Failed to restart Tor service for auto IP change. Skipping this cycle."
            echo -e "\033[1;31m[✗] Failed to restart Tor. Skipping this IP change cycle.\033[0m"
            sleep "$interval"
            continue
        fi
        sleep 10

        # Loop to verify Tor is up and proxy is working
        tor_ready=false
        for attempt in {1..5}; do
            echo -ne "\033[1;36m[~]\033[0m Checking Tor status (attempt $attempt)... "
            test_ip=$(curl -s --max-time 10 --proxy socks5h://127.0.0.1:$TOR_PORT http://ifconfig.me || echo "Unavailable")
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
