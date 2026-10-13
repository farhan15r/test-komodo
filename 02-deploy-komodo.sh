#!/usr/bin/env bash
# 02-deploy-komodo.sh — Deploy Komodo v2 (Core + Periphery + MongoDB) via docker compose.
# - Compose dir : /opt/komodo
# - Periphery root / backups : /etc/komodo
# - Core UI hanya bind ke 127.0.0.1:9120 (akses via SSH tunnel)
# Jalankan dari laptop:
#   ssh -J farhan@ssh-pve-01.chumbucket.my.id farhan@192.168.100.215 'bash -s' < 02-deploy-komodo.sh
set -euo pipefail

DIR=/opt/komodo
RAW=https://raw.githubusercontent.com/moghtech/komodo/main/compose
COMPOSE="$DIR/mongo.compose.yaml"
ENVF="$DIR/compose.env"

if [ -f "$ENVF" ]; then
  echo "ERROR: $ENVF sudah ada, batal (hindari overwrite secret). Hapus dulu atau pakai 99-uninstall.sh."
  exit 1
fi

rnd() { openssl rand -hex "$1"; }

echo "== Siapkan direktori =="
sudo mkdir -p "$DIR" /etc/komodo/backups

echo "== Download compose resmi =="
sudo curl -fsSL "$RAW/mongo.compose.yaml" -o "$COMPOSE"
sudo curl -fsSL "$RAW/compose.env"        -o "$ENVF"

echo "== Konfigurasi compose.env =="
ADMIN_PW=$(rnd 12)
sudo sed -i \
  -e "s|^KOMODO_DATABASE_PASSWORD=.*|KOMODO_DATABASE_PASSWORD=$(rnd 24)|" \
  -e "s|^TZ=.*|TZ=Asia/Jakarta|" \
  -e "s|^KOMODO_HOST=.*|KOMODO_HOST=http://localhost:9120|" \
  -e "s|^KOMODO_INIT_ADMIN_PASSWORD=.*|KOMODO_INIT_ADMIN_PASSWORD=$ADMIN_PW|" \
  -e "s|^KOMODO_FIRST_SERVER_NAME=.*|KOMODO_FIRST_SERVER_NAME=komodo-01|" \
  -e "s|^KOMODO_WEBHOOK_SECRET=.*|KOMODO_WEBHOOK_SECRET=$(rnd 24)|" \
  -e "s|^KOMODO_JWT_SECRET=.*|KOMODO_JWT_SECRET=$(rnd 32)|" \
  "$ENVF"
sudo chmod 600 "$ENVF"

echo "== Bind Core hanya ke localhost =="
sudo sed -i 's|^\(\s*\)- 9120:9120|\1- 127.0.0.1:9120:9120|' "$COMPOSE"
grep -n '9120:9120' "$COMPOSE"

echo "== Simpan password admin awal =="
echo "admin / $ADMIN_PW" | sudo tee "$DIR/admin-credentials.txt" >/dev/null
sudo chmod 600 "$DIR/admin-credentials.txt"

echo "== docker compose up =="
cd "$DIR"
sudo docker compose -p komodo -f "$COMPOSE" --env-file "$ENVF" up -d

echo "== Tunggu Core siap =="
for i in $(seq 1 30); do
  if curl -fs -o /dev/null http://127.0.0.1:9120; then echo "Core UP"; break; fi
  sleep 3
done

sudo docker compose -p komodo -f "$COMPOSE" --env-file "$ENVF" ps
echo "--- core logs ---"
sudo docker compose -p komodo -f "$COMPOSE" --env-file "$ENVF" logs --tail 20 core
echo "--- periphery logs ---"
sudo docker compose -p komodo -f "$COMPOSE" --env-file "$ENVF" logs --tail 10 periphery

echo
echo "== DONE =="
echo "Login awal: admin / $ADMIN_PW  (tersimpan di $DIR/admin-credentials.txt) — ganti setelah login."
