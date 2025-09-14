#!/usr/bin/env bash
# Pi Bench • LITE (Linux) — minimal tests + pretty output
set -Eeuo pipefail

# Colors (only if tty)
if [[ -t 1 ]]; then
  NC="\033[0m"; ACC="\033[38;5;105m"; MUT="\033[38;5;110m"; OK="\033[38;5;84m"
else
  NC=""; ACC=""; MUT=""; OK=""
fi

bar(){ printf "${MUT}────────────────────────────────────────────────────────────${NC}\n"; }
title(){ printf "■ %s\n" "$1"; }
kv(){ printf "  %-20s %s\n" "$1" "$2"; }
bullet(){ printf "• %s\n" "$1"; }

# Ensure optional deps
need=()
for c in lscpu sysbench curl; do command -v "$c" >/dev/null || need+=("$c"); done
if ((${#need[@]})); then
  if command -v apt-get >/dev/null; then sudo apt-get update -y && sudo apt-get install -y "${need[@]}"; fi
fi

# -------- System --------
bar; title "System"; bar
MODEL="$(tr -d '\0' </proc/device-tree/model 2>/dev/null || true)"; [[ -z "${MODEL:-}" ]] && MODEL="$(lscpu | awk -F: '/Model name/{print $2}' | sed 's/^ *//')"
kv "Model 型號" "${MODEL:-unknown}"
kv "Cores 核心數" "$(nproc)"
kv "Kernel 版本" "$(uname -r)"
kv "OS 系統" "$(source /etc/os-release; echo "$PRETTY_NAME")"
kv "Arch 架構" "$(uname -m)"
kv "Uptime 開機時間" "$(uptime -p | sed 's/^up //')"

# -------- CPU / Memory --------
bar; title "CPU / Memory"; bar

# CPU freq
CPU_CUR=""; CPU_MIN=""; CPU_MAX=""
if [[ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
  CPU_CUR="$(awk '{printf \"%.2f\", $1/1000000}' /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) GHz"
  CPU_MIN="$(awk '{printf \"%.2f\", $1/1000000}' /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq) GHz"
  CPU_MAX="$(awk '{printf \"%.2f\", $1/1000000}' /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq) GHz"
fi
[[ -n "${CPU_CUR}" ]] && kv "CPU 時脈（目前）" "$CPU_CUR"
[[ -n "${CPU_MIN}" && -n "${CPU_MAX}" ]] && kv "CPU 時脈（Min ~ Max）" "$CPU_MIN ~ $CPU_MAX"

# Memory total/used
MEM_TOTAL_KB=$(awk '/MemTotal:/{print $2}' /proc/meminfo)
MEM_AVAIL_KB=$(awk '/MemAvailable:/{print $2}' /proc/meminfo)
MEM_USED_KB=$(( MEM_TOTAL_KB - MEM_AVAIL_KB ))
toGiB(){ awk -v v="$1" 'BEGIN{printf "%.2f GiB", v/1024/1024}'; }
PCT=$(awk -v u="$MEM_USED_KB" -v t="$MEM_TOTAL_KB" 'BEGIN{printf "%.1f%%", (u/t)*100}')
kv "記憶體總量（Total）" "$(toGiB "$MEM_TOTAL_KB")"
kv "已用記憶體（Used）"  "$(toGiB "$MEM_USED_KB") ($PCT)"

# sysbench CPU
bullet "CPU (sysbench prime=20000, threads=$(nproc))"
SYSCPU="$(sysbench cpu --threads="$(nproc)" --cpu-max-prime=20000 run 2>/dev/null || true)"
echo "$SYSCPU" | awk -F: '/events per second|total time|min:|avg:|max:/{gsub(/^ +/,"",$2); printf "  %s %s\n",$1,$2}'
# memory write
bullet "Memory write (512MB, threads=$(nproc))"
SYSMEM="$(sysbench memory --threads="$(nproc)" --memory-total-size=512M --memory-oper=write run 2>/dev/null || true)"
echo "$SYSMEM" | awk -F'[()]' '/transferred/{gsub(/^ +| MiB\/sec$/,"",$2); printf "  寫入傳輸量 (transferred) %s\n", $1; print "  平均吞吐量 (throughput) " $2 " MiB/sec"}'

# -------- Disk --------
bar; title "Disk"; bar
ROOTDEV="$(findmnt -n -o SOURCE / || true)"
kv "Root 根裝置" "${ROOTDEV:-unknown}"
if [[ "$ROOTDEV" =~ ^/dev/mmcblk ]]; then
  bullet "偵測到根目錄在 SD，跳過寫入測試以避免磨損。"
fi

# -------- Network Info --------
bar; title "Network Info"; bar
AES="Disabled"; grep -qi ' aes' /proc/cpuinfo && AES="Enabled"
kv "AES 加速 (AES/NI)" "$AES"

# IPv4/IPv6
get_json(){
  # try several public endpoints quietly
  curl -fsS --max-time 4 https://ipinfo.io/json ||
  curl -fsS --max-time 4 https://ifconfig.co/json ||
  curl -fsS --max-time 4 https://ipapi.co/json || true
}
J="$(get_json || true)"
if [[ -n "${J:-}" ]]; then
  kv "IPv4 狀態" "Online"
  IP="$(echo "$J" | sed -n 's/.*"ip"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\\1/p' | head -n1)"
  CITY="$(echo "$J" | sed -n 's/.*"city"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\\1/p' | head -n1)"
  REGION="$(echo "$J" | sed -n 's/.*"region"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\\1/p' | head -n1)"
  COUNTRY="$(echo "$J" | sed -n 's/.*"country"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\\1/p' | head -n1)"
  ORG="$(echo "$J" | sed -n 's/.*"org"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\\1/p' | head -n1)"
  if [[ -n "$IP" ]]; then kv "IP 位址 (Address)" "$IP"; fi
  if [[ -n "$REGION$COUNTRY" ]]; then kv "區域 (Region)" "${REGION:+$REGION / }${COUNTRY}"; fi
  if [[ -n "$ORG" ]]; then kv "組織 (Organization)" "$ORG"; fi
  if [[ -n "$CITY$REGION$COUNTRY" ]]; then kv "位置 (Location)" "${COUNTRY:+$COUNTRY / }${REGION:+$REGION / }${CITY}"; fi
else
  kv "IPv4 狀態" "Offline"
fi
kv "IPv6 狀態" "$( (curl -6 -fsS --max-time 3 https://ifconfig.co >/dev/null && echo Online) || echo Offline )"

bar; printf "${OK}✓ Done${NC}\n"; bar
