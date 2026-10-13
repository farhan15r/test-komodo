#!/usr/bin/env bash
# 00-recon.sh — READ-ONLY: cek kondisi server sebelum install Komodo.
# Tidak mengubah apa pun di server.
# Jalankan dari laptop:
#   ssh -J farhan@ssh-pve-01.chumbucket.my.id farhan@192.168.100.215 'bash -s' < 00-recon.sh

section() { printf '\n===== %s =====\n' "$1"; }

section "OS / Kernel"
cat /etc/os-release 2>/dev/null | grep -E '^(PRETTY_NAME|ID|VERSION_ID)='
uname -a
echo "arch: $(uname -m)"

section "CPU"
echo "cores: $(nproc)"
grep -m1 'model name' /proc/cpuinfo
if grep -qw avx /proc/cpuinfo; then echo "AVX: YES (MongoDB 5+ OK)"; else echo "AVX: NO (pakai FerretDB/Postgres)"; fi

section "Memory / Disk"
free -h
df -h / /opt /var/lib/docker 2>/dev/null | awk '!seen[$0]++'

section "User / Sudo"
id
if sudo -n true 2>/dev/null; then echo "sudo: passwordless OK"; else echo "sudo: butuh password (atau tidak ada akses)"; fi

section "Docker"
if command -v docker >/dev/null 2>&1; then
  docker version --format 'client={{.Client.Version}} server={{.Server.Version}}' 2>&1
  docker compose version 2>&1
  echo "--- containers ---"
  docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>&1
  echo "--- volumes ---"
  docker volume ls 2>&1 | head -20
else
  echo "docker: TIDAK terpasang"
fi

section "Listening ports (cek 9120, 8120, 27017, 5432)"
ss -tlnH 2>/dev/null | awk '{print $4}' | sort -u
for p in 9120 8120 27017 5432; do
  if ss -tlnH 2>/dev/null | awk '{print $4}' | grep -qE "[:.]$p\$"; then echo "port $p: DIPAKAI"; else echo "port $p: free"; fi
done

section "Existing komodo dir?"
ls -ld /opt/komodo ~/komodo 2>&1

section "Connectivity"
for u in https://ghcr.io/v2/ https://raw.githubusercontent.com/moghtech/komodo/main/compose/compose.env https://download.docker.com; do
  code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$u" 2>/dev/null || echo ERR)
  echo "$u -> $code"
done

echo -e "\n===== DONE ====="
