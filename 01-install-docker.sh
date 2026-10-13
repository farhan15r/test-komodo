#!/usr/bin/env bash
# 01-install-docker.sh — Install Docker Engine + compose plugin di Rocky Linux 10
# dari repo resmi Docker (rhel), enable service, tambahkan user ke grup docker.
# Jalankan dari laptop:
#   ssh -J farhan@ssh-pve-01.chumbucket.my.id farhan@192.168.100.215 'bash -s' < 01-install-docker.sh
set -euo pipefail

TARGET_USER="${TARGET_USER:-farhan}"

echo "== Hapus paket yang konflik (podman/buildah/runc) jika terpasang =="
conflicts=$(rpm -q podman buildah runc docker docker-client docker-common docker-engine 2>/dev/null | grep -v 'not installed' || true)
if [ -n "$conflicts" ]; then
  echo "Akan dihapus: $conflicts"
  sudo dnf remove -y $conflicts
else
  echo "Tidak ada paket konflik."
fi

echo "== Tambah repo Docker CE (rhel) =="
sudo curl -fsSL https://download.docker.com/linux/rhel/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo

echo "== Install Docker Engine + plugins =="
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "== Enable & start docker =="
sudo systemctl enable --now docker

echo "== Tambah $TARGET_USER ke grup docker =="
sudo usermod -aG docker "$TARGET_USER"

echo "== Verifikasi =="
sudo docker version --format 'client={{.Client.Version}} server={{.Server.Version}}'
sudo docker compose version
sudo docker run --rm hello-world | head -3

echo "== DONE (grup docker aktif di sesi ssh berikutnya) =="
