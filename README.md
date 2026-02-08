# 🔒 HARE KRISHNA - Anonymizer Tool v1.5

![banner](https://img.shields.io/badge/Bash-Anonymizer-blue.svg) ![license](https://img.shields.io/badge/License-MIT-green.svg)

> ⚔️ **By 0warn**  
> Advanced Linux-based MAC/IP randomizer + Tor anonymizer  
> Protect your identity. Defend your network. Stay hidden like a ghost. 🛡️

---

```
'##::::'##::::'###::::'########::'########::::'##:::'##:'########::'####::'######::'##::::'##:'##::: ##::::'###::::
 ##:::: ##:::'## ##::: ##.... ##: ##.....::::: ##::'##:: ##.... ##:. ##::'##... ##: ##:::: ##: ###:: ##:::'## ##:::
 ##:::: ##::'##:. ##:: ##:::: ##: ##:::::::::: ##:'##::: ##:::: ##:: ##:: ##:::..:: ##:::: ##: ####: ##::'##:. ##::
 #########:'##:::. ##: ########:: ######:::::: #####:::: ########::: ##::. ######:: #########: ## ## ##:'##:::. ##:
 ##.... ##: #########: ##.. ##::: ##...::::::: ##. ##::: ##.. ##:::: ##:::..... ##: ##.... ##: ##. ####: #########:
 ##:::: ##: ##.... ##: ##::. ##:: ##:::::::::: ##:. ##:: ##::. ##::: ##::'##::: ##: ##:::: ##: ##:. ###: ##.... ##:
 ##:::: ##: ##:::: ##: ##:::. ##: ########:::: ##::. ##: ##:::. ##:'####:. ######:: ##:::: ##: ##::. ##: ##:::: ##:
..:::::..::..:::::..::..:::::..::........:::::..::::..::..:::::..::....:::......:::..:::::..::..::::..::..:::::..::

                                🛕 Ancient name. ⚔️ Modern defense. 🔒
```

---

## 🎯 Purpose

`HARE-KRISHNA` is a terminal-based anonymization tool for Linux systems.  
It combines **MAC address spoofing**, **IP obfuscation**, and **Tor-based routing** to make your device harder to track and fingerprint.

---

## ⚙️ Features

✅ MAC Address randomizer  
✅ IP change via Tor (`socks5h`)  
✅ Start/Stop anonymization sessions  
✅ System-wide proxy with Tor  
✅ DNS Leak Protection (via `iptables`)  
✅ Robust Kill Switch (via `iptables`)  
✅ Configuration file for easy customization  
✅ Built-in log viewer  
✅ Works on Kali, Parrot, Arch, Ubuntu, Debian, and more  
✅ Failsafe rollback on update failure  
✅ Clean CLI interface with banner, help, and status report

---

## 📥 Installation

### 🔧 Using `setup.sh` (Recommended)

```bash
git clone https://github.com/0warn/Hare-Krishna.git
cd Hare-Krishna
chmod +x setup.sh
sudo ./setup.sh
```
The `setup.sh` script will install necessary dependencies, copy the `hare-krishna` executable to `/usr/local/bin`, and place the configuration file `hare-krishna.conf` into `/etc/hare-krishna/`.

➡️ After setup, run the tool via:

```bash
sudo hare-krishna -h/--help
```
---

## 💻 Usage

```bash
sudo ./hare-krishna.sh -st/--start          # Start anonymization
sudo ./hare-krishna.sh -sp/--stop           # Stop and restore original state
sudo ./hare-krishna.sh -cm -m XX:XX:XX:XX:XX:XX/--changemac XX:XX:XX:XX:XX:XX   # Change MAC manually
sudo ./hare-krishna.sh -cp/--changeip       # Change IP via Tor
sudo ./hare-krishna.sh -ss/--status         # Show anonymization status
sudo ./hare-krishna.sh --cip/--checkip      # To show your tor ip address 
sudo ./hare-krishna.sh -l/--logs            # View logs
sudo ./hare-krishna.sh -v/--version         # Show tool version
sudo ./hare-kirhsna.sh -a/--auto [INTERVAL_SECONDS] # Auto change IP (and MAC if configured) at specified intervals (default: 300 seconds)
```

---

## 🧩 Command Reference

| Flag       | Description                             |
|------------|-----------------------------------------|
| `-st`, `--start`      | Start anonymization                     |
| `-sp`, `--stop`      | Stop and restore                        |
| `-cm -m`, `--changemac`  | Change MAC to custom address            |
| `-cp`, `--changeip`     | Change IP (restart Tor)                 |
| `-ss`, `--status`       | Show status                             |
| `-l`, `--logs`   | View log history                        |
| `-cip`, `--checkip`    | To see tor ip address                   |
| `-v`, `--version`| Show current version                    |
| `-d`, `--debug`  | Enable debug output                     |
| `-h`, `--help`      | Help / usage guide                      |
| `-a`, `--auto`      | Auto change IP (and MAC if configured) at specified intervals (default: 300 seconds)                    |

---

## ⚙️ Configuration

`HARE-KRISHNA` can be configured using the `hare-krishna.conf` file. During installation, this file is copied to `/etc/hare-krishna/hare-krishna.conf`. The script reads settings from this file, allowing you to customize its behavior without modifying the main script.

### Default Configuration (located at `/etc/hare-krishna/hare-krishna.conf`):
```
# HARE-KRISHNA Configuration File
# ----------------------------------

# Default network interface to use. Leave empty to auto-detect.
# Example: INTERFACE="eth0"
INTERFACE=""

# Tor SOCKS proxy port
TOR_PORT="9050"

# Tor DNS port (used for DNS leak protection)
DNS_PORT="5353"

# Log file path
LOG_FILE="/var/log/harekrishna.log"

# State file path
STATE_FILE="/tmp/harekrishna.state"
```

---

## [^_^] Supported OS 

- Kali Linux
- Parrot os
- Ubuntu os
- Arch Linux
- Athena os
- Linux Mint
- Garuda Linux

## 🔐 Security Considerations

⚠️ This tool **modifies your network interfaces**, routes traffic via **Tor**, and makes low-level system changes.  
Always run as **root or with sudo**, and make sure to:

- Trust the Tor network  
- Understand your legal responsibilities  
- Use in a **controlled or ethical** environment
- The tool now includes a **Robust Kill Switch** and **DNS Leak Protection** via `iptables` to further enhance anonymity and prevent accidental leaks.

---

## 🛠️ Fixing Proxy setting

1. `FOR SYSTEM WIDE TOR ROUTING` -> Go to `settings/control center` > `Network` > Look for `proxy` > `turn on` if it is off by defult and switch to `manual` > Add `127.0.0.1` at socks host and add `9050` on port > Save it > Your system now run on `tor`.

2. `FOR BROWSER ONLY` -> Open your favourite browser > Go to `settings` > Search for `network` > There you can see a `Network Settings` > Open it > Switch to `Manual proxy configuration` > Add `127.0.0.1` and port `9050` on `SOCKS Host` only > choose `SOCKS v4` & `SOCKS v5` both > Save it by clicking on `OK` button > Now you are ready to go. 

- Now if you want stop this then just `turn off proxy on your settings` & for browser switch to `Use system proxy settings`
### Note - Just a reminder when you set `Proxy` system wide then if you select with your `setting or control center` then if you choose on your browser `Use system proxy settings` this setting on your `network setting` your browser also then use `tor` network.

--- 

## 🛠️ Troubleshooting

| Issue                        | Solution |
|-----------------------------|----------|
| `Tor failed to start`       | `sudo systemctl restart tor` |
| `MAC not changing`          | Ensure interface is down during change |
| `No internet after start`   | Check DNS leaks or firewall rules. The new kill switch feature might also be a reason. |
| `proxy-setting`             | Make sure you fix your browser and system proxy setting to use it. |

--- 

## 🧠 Contributions

Pull requests, improvements, and suggestions are always welcome.

📧 Author: 0warn  
🔗 GitHub: [0warn](https://github.com/0warn)  
🛕 Inspired by ancient wisdom, coded for modern defense.

---

## 📜 License

This project is licensed under the **MIT License**.  
Feel free to modify, share, and use with credit.

---

> “Hare Krishna Hare Krishna, Krishna Krishna Hare Hare  
>  Hare Rama Hare Rama, Rama Rama Hare Hare.”  
>  — Chant for liberation, now protecting your packets.