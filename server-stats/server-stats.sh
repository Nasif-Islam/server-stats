#!/usr/bin/env bash
set -euo pipefail

get_cpu_usage() {
  # Using iostat on macOS, get CPU idle and calculate usage
  iostat -c 2 | tail -n 1 | awk '{usage=100 - $6; printf "%.1f", usage}'
}

get_mem_usage() {
  mem_used=$(vm_stat | awk '/Pages active:/ {active=$3} /Pages wired down:/ {wired=$4} /Pages speculative:/ {spec=$3} END {print active + wired + spec}')
  mem_free=$(vm_stat | awk '/Pages free:/ {print $3}')
  page_size=$(sysctl -n hw.pagesize)
  mem_used_bytes=$((mem_used * page_size))
  mem_free_bytes=$((mem_free * page_size))
  mem_total_bytes=$(sysctl -n hw.memsize)
  
  mem_used_mb=$((mem_used_bytes / 1024 / 1024))
  mem_total_mb=$((mem_total_bytes / 1024 / 1024))
  usage_percent=$(awk -v used="$mem_used_mb" -v total="$mem_total_mb" 'BEGIN {printf "%.1f", used / total * 100}')
  printf "%dMB / %dMB (%.1f%%)" "$mem_used_mb" "$mem_total_mb" "$usage_percent"
}

get_disk_usage() {
  df -h / | awk 'NR==2 {printf "%s used of %s (%s)", $3, $2, $5}'
}

get_top_by_cpu() {
  echo "PID USER %CPU %MEM COMMAND"
  ps -Ao pid,user,%cpu,%mem,comm -r | head -n 6
}

get_top_by_mem() {
  echo "PID USER %CPU %MEM COMMAND"
  ps -Ao pid,user,%cpu,%mem,comm -m | head -n 6
}

get_os() {
  sw_vers -productName && sw_vers -productVersion
}

get_uptime() {
  uptime | sed 's/^.*up \([^,]*\), .*/\1/'
}

get_loadavg() {
  sysctl -n vm.loadavg | awk '{print $2, $3, $4}'
}

get_users() {
  who | wc -l
}

get_failed_logins() {
  # macOS does not have standard /var/log/auth.log or /var/log/secure
  echo "N/A"
}

echo "===== Server Stats — $(date) ====="
echo "OS: $(get_os)"
echo "Uptime: $(get_uptime)"
echo "Load avg (1/5/15m): $(get_loadavg)"
echo "Logged in users: $(get_users)"
echo "Failed login attempts: $(get_failed_logins)"
echo
echo "CPU usage: $(get_cpu_usage)%"
echo "Memory: $(get_mem_usage)"
echo "Disk /: $(get_disk_usage)"
echo
echo "=== Top 5 processes by CPU ==="
get_top_by_cpu
echo
echo "=== Top 5 processes by Memory ==="
get_top_by_mem

