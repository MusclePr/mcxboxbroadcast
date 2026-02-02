#!/usr/bin/env bash
set -euo pipefail

#
# Configuration
#
REPO="${REPO:-MCXboxBroadcast/Broadcaster}"
JAR="${JAR:-./bin/MCXboxBroadcastStandalone.jar}"
AUTO_UPDATE="${AUTO_UPDATE:-false}"
AUTO_UPDATE_CRON="${AUTO_UPDATE_CRON:-0 */4 * * *}"

#
# Initial update check
#
/app/update_config.sh || true
if [ "${AUTO_UPDATE}" = "true" ]; then
    /app/update.sh || true
fi

#
# Start supercronic
#
cron_pid=
if [ "${AUTO_UPDATE}" = "true" ]; then
    echo "Configuring auto update with schedule: ${AUTO_UPDATE_CRON}"
    echo "${AUTO_UPDATE_CRON} /app/update_config.sh" > /tmp/crontab
    echo "${AUTO_UPDATE_CRON} /app/update.sh" >> /tmp/crontab
    echo "Starting supercronic..."
    supercronic --no-reap /tmp/crontab &
    cron_pid=$!
fi

#
# Execute JAR
#
java_pid=
watcher_pid=

function cleanup() {
    echo "Terminating..."
    [ -n "${java_pid}" ] && kill "${java_pid}" 2>/dev/null
    [ -n "${cron_pid}" ] && kill "${cron_pid}" 2>/dev/null
    [ -n "${watcher_pid}" ] && kill "${watcher_pid}" 2>/dev/null
}

trap cleanup EXIT

#
# Config Watcher
#
function start_config_watcher() {
    (
        CONFIG_FILE="${CONFIG_FILE:-/data/config.yml}"
        echo "Watching for ${CONFIG_FILE} creation..."
        while [ ! -f "${CONFIG_FILE}" ]; do
            sleep 2
        done
        echo "${CONFIG_FILE} detected. Applying environment variables..."
        /app/update_config.sh
    ) &
    watcher_pid=$!
}

start_config_watcher

echo "Starting Java application..."
while true; do
    /app/update_config.sh || true
    if [ ! -f "${JAR}" ] && [ -f "${JAR}.bak" ]; then
        echo "Main JAR not found. Restoring from backup..."
        mv "${JAR}.bak" "${JAR}"
    fi

    if [ -f "${JAR}" ]; then
        echo "Attempting to start ${JAR}..."
        start_time=$(date +%s)
        java ${JAVA_OPTS:-} -jar "${JAR}" &
        java_pid=$!

        # Disable exit on error to catch java exit code
        set +e
        wait "${java_pid}"
        exit_code=$?
        set -e

        end_time=$(date +%s)
        duration=$((end_time - start_time))

        # Consider it a failure if it's not a normal exit (0), not a SIGTERM (143),
        # and it exited within 15 seconds.
        if [ "${exit_code}" -ne 0 ] && [ "${exit_code}" -ne 143 ] && [ "${duration}" -lt 15 ]; then
            echo "Java process failed quickly (exit code: ${exit_code}, duration: ${duration}s)."
            if [ -f "${JAR}.bak" ]; then
                echo "Fallback: Restoring ${JAR}.bak and retrying..."
                mv "${JAR}" "${JAR}.corrupted" || true
                mv "${JAR}.bak" "${JAR}"
                continue
            fi
        fi
        echo "Java process stopped (exit code: ${exit_code}). Restarting in 5 seconds..."
    else
        echo "JAR not found. Waiting for update check..."
    fi
    sleep 5
done
