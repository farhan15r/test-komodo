#!/usr/bin/env bash
# 01b-reboot-and-start-docker.sh — Lanjutan 01 setelah docker gagal start.
# Penyebab: kernel-modules-extra (modul netfilter/xt) terpasang untuk kernel baru,
# kernel yang jalan masih lama -> iptables NAT gagal. Solusi: reboot ke kernel baru.
#
# Langkah A (reboot) — jalankan dari laptop:
#   ssh -J farhan@ssh-pve-01.chumbucket.my.id farhan@192.168.100.215 'sudo systemctl reboot'
#
# Langkah B (setelah VM up lagi, ~1 menit) — jalankan script ini:
#   ssh -J farhan@ssh-pve-01.chumbucket.my.id farhan@192.168.100.215 'bash -s' < 01b-reboot-and-start-docker.sh
set -euo pipefail

TARGET_USER="${TARGET_USER:-farhan}"

echo "== Kernel aktif: $(uname -r) =="

echo "== Start docker =="
sudo systemctl reset-failed docker.service || true
sudo systemctl enable --now docker
systemctl is-active docker

echo "== Tambah $TARGET_USER ke grup docker =="
sudo usermod -aG docker "$TARGET_USER"

echo "== Verifikasi =="
sudo docker version --format 'client={{.Client.Version}} server={{.Server.Version}}'
sudo docker compose version
sudo docker run --rm hello-world | head -3

echo "== DONE =="
