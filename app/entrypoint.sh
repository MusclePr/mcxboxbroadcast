#!/usr/bin/env bash
set -euo pipefail

# Create app user if it doesn't exist
if ! id -u app > /dev/null 2>&1; then
    groupadd -g "${GID:-1000}" app
    useradd -u "${UID:-1000}" -g app -d "/data" app
fi
chown app:app "/data"

# Execute the command as the app user
exec setpriv --reuid=app --regid=app --init-groups "${@}"
