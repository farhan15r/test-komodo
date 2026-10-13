#!/usr/bin/env bash
# 99-uninstall.sh — HAPUS Komodo beserta data (volume mongo, keys) & /opt/komodo.
# /etc/komodo (stacks/repos/backups) tidak dihapus kecuali PURGE_ETC=1.
#   ssh -J farhan@ssh-pve-01.chumbucket.my.id farhan@192.168.100.215 'bash -s' < 99-uninstall.sh
set -euo pipefail
sudo docker compose -p komodo -f /opt/komodo/mongo.compose.yaml --env-file /opt/komodo/compose.env down -v
sudo rm -rf /opt/komodo
[ "${PURGE_ETC:-0}" = 1 ] && sudo rm -rf /etc/komodo
echo DONE
