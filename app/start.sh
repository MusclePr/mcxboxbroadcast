#!/usr/bin/env bash
set -euo pipefail

#
# Download the latest JAR from GitHub Releases
#
REPO="${REPO:-MCXboxBroadcast/Broadcaster}"
JAR="${JAR:-./bin/MCXboxBroadcastStandalone.jar}"

function get_download_url() {
    local -r url="https://api.github.com/repos/${REPO}/releases/${1:-latest}"
    local -r type="Standalone"
    curl -sL "${url}" | grep browser_download_url | cut -d '"' -f 4 | grep "${type}" | head -n 1
}

function download_jar() {
    local -a opts=("--retry" "3" "--retry-delay" "5")
    local -r bin_dir="$(dirname "${JAR}")"
    local status
    [ ! -d "${bin_dir}" ] && mkdir -p "${bin_dir}"
    [ -f "${JAR}" ] && opts+=("-z" "${JAR}")
    echo "Downloading JAR from \"${1}\""
    status=$(curl -sfSL -o "${JAR}" "${opts[@]}" -w '%{http_code}' "${1}")
    if [ "${status}" -ne 200 ]; then
        if [ "${status}" -eq 304 ]; then
            echo "Skipped: Already up to date."
            return 0
        else
            echo "Failed to download JAR (HTTP status: ${status})" >&2
            exit 1
        fi
    fi
    echo "JAR downloaded successfully."
}

download_jar "${DOWNLOAD_URL:-$(get_download_url "${VERSION:-latest}")}"

#
# Execute JAR
#
exec java -jar "${JAR}"
