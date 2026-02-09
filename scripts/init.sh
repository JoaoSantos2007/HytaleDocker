#!/bin/bash
source /home/hytale/scripts/download.sh

set -e

echo "Set file permissions"

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Using UID: $PUID  GID: $PGID"

groupmod -o -g "$PGID" hytale
usermod  -o -u "$PUID" hytale

# Ajusta tudo que o container usa
chown -R "$PUID:$PGID" /home/hytale /data 2>/dev/null || true

init_server() {
  SERVER_DIR="/data"

  check_server
}

init_server