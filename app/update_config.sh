#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-/data/config.yml}"

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Config file not found: ${CONFIG_FILE}. Skipping updates."
    exit 0
fi

CHANGED=false

update_val() {
    local key="$1"
    local env_val="$2"
    local is_num="${3:-false}"

    if [ -n "${env_val}" ]; then
        current_val=$(yq "${key}" "${CONFIG_FILE}")
        if [ "${current_val}" != "${env_val}" ]; then
            echo "Updating ${key} to ${env_val}"
            if [ "${is_num}" = "true" ]; then
                yq -i "${key} = ${env_val}" "${CONFIG_FILE}"
            else
                yq -i "${key} = \"${env_val}\"" "${CONFIG_FILE}"
            fi
            CHANGED=true
        fi
    fi
}

update_val ".session.session-info.host-name" "${SERVER_NAME:-${HOST_NAME:-}}"
update_val ".session.session-info.world-name" "${WORLD_NAME:-}"
update_val ".session.session-info.max-players" "${MAX_PLAYERS:-}" true

if [ -n "${PUBLIC_HOST:-}" ]; then
    if [[ "${PUBLIC_HOST}" == *":"* ]]; then
        extracted_ip="${PUBLIC_HOST%:*}"
        extracted_port="${PUBLIC_HOST##*:}"
        update_val ".session.session-info.ip" "${extracted_ip}"
        update_val ".session.session-info.port" "${extracted_port}" true
    else
        update_val ".session.session-info.ip" "${PUBLIC_HOST}"
        update_val ".session.session-info.port" "19132" true
    fi
fi

if [ "${CHANGED}" = "true" ]; then
    echo "Configuration updated."
    # Kill java process if it's running to trigger restart in start.sh
    JAR="${JAR:-./bin/MCXboxBroadcastStandalone.jar}"
    pkill -f "java.*-jar ${JAR}" || true
fi
