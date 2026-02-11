#!/bin/bash
source /home/hytale/scripts/machine.sh
source /home/hytale/scripts/download.sh
source /home/hytale/scripts/stop.sh

set -e

# Set file permissions
PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Using UID: $PUID  GID: $PGID"
groupmod -o -g "$PGID" hytale
usermod  -o -u "$PUID" hytale
chown -R "$PUID:$PGID" /home/hytale /data 2>/dev/null || true

# Set up persistent machine-id for encrypted auth
setup_machine-id

# Check server and download on start
if [ "${DOWNLOAD_ON_START:-true}" = "true" ]; then
  check_server
else
  echo "DOWNLOAD_ON_START is set to false, skipping server download"
fi

# shellcheck disable=SC2317
term_handler() {
    if ! shutdown_server; then
        # Force shutdown if graceful shutdown fails
        kill -SIGTERM "$(pgrep -f HytaleServer.jar)"
    fi
    tail --pid="$killpid" -f 2>/dev/null
}

trap 'term_handler' SIGTERM

# Start the server as hytale user
su hytale -c "export PATH=\"$PATH\" && cd /home/hytale/scripts/ && ./start.sh" &
killpid="$!"
wait "$killpid"
