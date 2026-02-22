#!/usr/bin/env bash
set -euo pipefail

# =========================
# 4NG3RS0N DNS Jumper (Linux)
# Airgeddon-ish TUI vibes 😈
# =========================

# ---- Colors (no hard dependency)
RED="\e[31m"; GRN="\e[32m"; YLW="\e[33m"; BLU="\e[34m"; MAG="\e[35m"; CYN="\e[36m"; WHT="\e[37m"; DIM="\e[2m"; RST="\e[0m"
BOLD="\e[1m"

cleanup() { tput cnorm 2>/dev/null || true; echo -e "${RST}"; }
trap cleanup EXIT

need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo -e "${RED}Run as root:${RST} sudo $0"
    exit 1
  fi
}

has_resolvectl() { command -v resolvectl >/dev/null 2>&1; }

default_iface() {
  ip route 2>/dev/null | awk '/default/ {print $5; exit}'
}

flush_cache() {
  if has_resolvectl; then
    resolvectl flush-caches >/dev/null 2>&1 || true
  fi
}

set_dns_resolved() {
  local iface="$1" d1="$2" d2="$3"
  resolvectl dns "$iface" "$d1" "$d2" >/dev/null
  flush_cache
}

set_dns_resolvconf() {
  local d1="$1" d2="$2"
  cat > /etc/resolv.conf <<EOF
# Set by 4NG3RS0N DNS Jumper
nameserver $d1
nameserver $d2
EOF
}

apply_dns() {
  local name="$1" d1="$2" d2="$3"
  local iface; iface="$(default_iface || true)"

  echo -e "${DIM}Using interface:${RST} ${CYN}${iface:-unknown}${RST}"
  echo -e "${DIM}Setting DNS:${RST} ${YLW}$name${RST} -> ${GRN}$d1${RST} / ${GRN}$d2${RST}"

  if has_resolvectl && [[ -n "${iface:-}" ]]; then
    set_dns_resolved "$iface" "$d1" "$d2"
  else
    set_dns_resolvconf "$d1" "$d2"
  fi

  echo -e "${GRN}Done.${RST}"
}

restore_default() {
  local iface; iface="$(default_iface || true)"
  echo -e "${YLW}Restoring DHCP/default DNS...${RST}"

  if has_resolvectl && [[ -n "${iface:-}" ]]; then
    resolvectl revert "$iface" >/dev/null
    flush_cache
    echo -e "${GRN}Reverted DNS for:${RST} ${CYN}$iface${RST}"
  else
    echo -e "${RED}Note:${RST} Your system may manage /etc/resolv.conf automatically (NetworkManager/systemd-resolved)."
    echo -e "${DIM}Try:${RST} sudo systemctl restart NetworkManager  (or reboot)"
  fi
}

show_current() {
  echo -e "${BOLD}${CYN}=== Current DNS ===${RST}"
  if has_resolvectl; then
    resolvectl status | sed -n '1,140p'
  else
    cat /etc/resolv.conf
  fi
}

# ---- 28 Providers (Name | DNS1 | DNS2)
PROVIDERS=(
  "Cloudflare|1.1.1.1|1.0.0.1"
  "Cloudflare (Malware)|1.1.1.2|1.0.0.2"
  "Cloudflare (Family)|1.1.1.3|1.0.0.3"
  "Google DNS|8.8.8.8|8.8.4.4"
  "Quad9 (Secure)|9.9.9.9|149.112.112.112"
  "Quad9 (ECS)|9.9.9.11|149.112.112.11"
  "OpenDNS|208.67.222.222|208.67.220.220"
  "OpenDNS FamilyShield|208.67.222.123|208.67.220.123"
  "AdGuard DNS|94.140.14.14|94.140.15.15"
  "AdGuard Family|94.140.14.15|94.140.15.16"
  "AdGuard Unfiltered|94.140.14.140|94.140.14.141"
  "CleanBrowsing Security|185.228.168.9|185.228.169.9"
  "CleanBrowsing Family|185.228.168.168|185.228.169.168"
  "CleanBrowsing Adult|185.228.168.10|185.228.169.11"
  "Comodo Secure DNS|8.26.56.26|8.20.247.20"
  "DNS.WATCH|84.200.69.80|84.200.70.40"
  "Verisign Public DNS|64.6.64.6|64.6.65.6"
  "UncensoredDNS|91.239.100.100|89.233.43.71"
  "FreeDNS (freeDNS.zone)|37.235.1.174|37.235.1.177"
  "DNS.SB|185.222.222.222|45.11.45.11"
  "Neustar Recursive|156.154.70.1|156.154.71.1"
  "Neustar Threat Protection|156.154.70.2|156.154.71.2"
  "Neustar Family Secure|156.154.70.3|156.154.71.3"
  "Level3 DNS (A)|4.2.2.1|4.2.2.2"
  "Level3 DNS (B)|4.2.2.3|4.2.2.4"
  "Quad101 (Taiwan)|101.101.101.101|101.102.103.104"
  "Yandex DNS|77.88.8.8|77.88.8.1"
  "Zen Internet DNS|212.23.3.100|212.23.6.100"
)

# ---- Animated header (lightning moves)
FRAMES=(
'   ⚡      '
'    ⚡     '
'     ⚡    '
'      ⚡   '
'     ⚡    '
'    ⚡     '
)

# Pure ASCII fallback if your terminal doesn't like ⚡ friend:
# FRAMES=('   /\/\   ' '    /\/\  ' '     /\/\ ' '      /\/\' '     /\/\ ' '    /\/\  ')

draw_banner() {
  local frame="$1"
  clear
  tput civis 2>/dev/null || true

  echo -e "${MAG}${BOLD}"
  cat <<'ASCII'
   _____                                ________    _______    _________      ____.                                  
  /  _  \   ____    ___________ ___.__. \______ \   \      \  /   _____/     |    |__ __  _____ ______   ___________ 
 /  /_\  \ /    \  / ___\_  __ <   |  |  |    |  \  /   |   \ \_____  \      |    |  |  \/     \\____ \_/ __ \_  __ \
/    |    \   |  \/ /_/  >  | \/\___  |  |    `   \/    |    \/        \ /\__|    |  |  /  Y Y  \  |_> >  ___/|  | \/
\____|__  /___|  /\___  /|__|   / ____| /_______  /\____|__  /_______  / \________|____/|__|_|  /   __/ \___  >__|   
        \/     \//_____/        \/              \/         \/        \/                       \/|__|        \/       

ASCII
  echo -e "${RST}${DIM}by:${RST} ${BOLD}Saad Nssiri${RST}\n"
  echo -e "${BOLD}https://github.com/4NG3RS0N${RST}\n"

  # Angry alien + moving lightning beside it
  echo -e "${YLW}${BOLD} ${frame} ${RST}${RED}${BOLD}
 ${frame}   .-""""-.
 ${frame}  /  _  _  \
 ${frame} |  (o)(o)  |   ${RST}${RED}${BOLD}>> ANGRY ALIEN :) <<${RST}
 ${frame} |    __    |
 ${frame} |  .____.  |
 ${frame}  \________/${RST}"

  echo
  echo -e "${CYN}${BOLD}Select a DNS provider:${RST}"
  echo -e "${DIM}(systemd-resolved: resolvectl if available; otherwise writes /etc/resolv.conf)${RST}"
  echo
}

menu() {
  local i=1
  for entry in "${PROVIDERS[@]}"; do
    IFS='|' read -r name d1 d2 <<< "$entry"
    printf "  %2d) %-28s  %s / %s\n" "$i" "$name" "$d1" "$d2"
    ((i++))
  done
  echo
  echo -e "  ${YLW}d)${RST} Restore DHCP/default"
  echo -e "  ${YLW}s)${RST} Show current DNS"
  echo -e "  ${YLW}q)${RST} Quit"
  echo
}

main() {
  need_root

  local frame_idx=0
  while true; do
    draw_banner "${FRAMES[$frame_idx]}"
    menu

    frame_idx=$(( (frame_idx + 1) % ${#FRAMES[@]} ))

    read -rp "Choice: " choice
    echo

    case "${choice,,}" in
      q) exit 0 ;;
      d) restore_default; read -rp "Press Enter..." _ ;;
      s) show_current; read -rp "Press Enter..." _ ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#PROVIDERS[@]} )); then
          IFS='|' read -r name d1 d2 <<< "${PROVIDERS[$((choice-1))]}"
          apply_dns "$name" "$d1" "$d2"
          read -rp "Press Enter..." _
        else
          echo -e "${RED}Invalid choice.${RST}"
          sleep 0.8
        fi
        ;;
    esac
  done
}

main
