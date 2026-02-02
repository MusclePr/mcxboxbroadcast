#!/usr/bin/env bash
set -euo pipefail

PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Create or update app group
if ! getent group app > /dev/null 2>&1; then
    groupadd -g "$PGID" app
else
    groupmod -o -g "$PGID" app
fi

# Create or update app user
if ! id -u app > /dev/null 2>&1; then
    useradd -u "$PUID" -g app -d "/data" -s /bin/bash app
else
    usermod -o -u "$PUID" -g "$PGID" app
fi

echo "Running with PUID: $PUID, PGID: $PGID"

chown app:app "/data"

# Execute the command as the app user
exec setpriv --reuid=app --regid=app --init-groups "${@}"
