#!/usr/bin/env bash
set -euo pipefail

#
# Download the latest JAR from GitHub Releases
#
REPO="${REPO:-MCXboxBroadcast/Broadcaster}"
JAR="${JAR:-./bin/MCXboxBroadcastStandalone.jar}"
VERSION="${VERSION:-latest}"
DOWNLOAD_URL="${DOWNLOAD_URL:-}"

function get_download_url() {
    local -r url="https://api.github.com/repos/${REPO}/releases/${1:-latest}"
    local -r type="Standalone"
    curl -sL "${url}" | grep browser_download_url | cut -d '"' -f 4 | grep "${type}" | head -n 1
}

function download_jar_tmp() {
    local -r url="${1}"
    local -r jar="${2:-${JAR}}"
    local -a opts=("--retry" "3" "--retry-delay" "5")
    local -r bin_dir="$(dirname "${jar}")"
    local status
    [ ! -d "${bin_dir}" ] && mkdir -p "${bin_dir}"
    [ -f "${jar}" ] && opts+=("-z" "${jar}")
    echo "Downloading JAR from \"${1}\""
    status=$(curl -sfSL -o "${jar}.tmp" "${opts[@]}" -w '%{http_code}' "${1}")
    if [ "${status}" -ne 200 ]; then
        if [ "${status}" -eq 304 ]; then
            echo "Skipped: Already up to date."
        else
            echo "Failed to download JAR (HTTP status: ${status})" >&2
        fi
        return 1
    fi
    echo "JAR downloaded successfully."
    return 0
}

url="${DOWNLOAD_URL}"
if [ -z "${url}" ]; then
    url=$(get_download_url "${VERSION}")
fi

if download_jar_tmp "${url}" "${JAR}"; then
    if [ -f "${JAR}" ]; then
        cp -av "${JAR}" "${JAR}.bak"
    fi
    mv "${JAR}.tmp" "${JAR}"
    echo "Update applied. Restarting java process..."
    pkill -f "java.*-jar ${JAR}" || true
else
    rm -f "${JAR}.tmp"
fi
