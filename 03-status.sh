#!/usr/bin/env bash
# 03-status.sh — READ-ONLY: cek status Komodo.
#   ssh -J farhan@ssh-pve-01.chumbucket.my.id farhan@192.168.100.215 'bash -s' < 03-status.sh
DC="sudo docker compose -p komodo -f /opt/komodo/mongo.compose.yaml --env-file /opt/komodo/compose.env"
$DC ps
echo "--- UI http ---"; curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:9120
for s in core periphery mongo; do echo "--- $s ---"; $DC logs --tail 5 --no-log-prefix $s; done
