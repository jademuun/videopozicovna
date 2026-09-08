#!/usr/bin/env bash
# Creates the host folder structure for DATA_ROOT/CONFIG_ROOT and fixes ownership.
# Safe to re-run (idempotent).
set -euo pipefail

cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "Error: .env not found. Copy .env.example to .env and fill it in first." >&2
  exit 1
fi

# shellcheck disable=SC1091
set -a
source .env
set +a

for var in PUID PGID DATA_ROOT CONFIG_ROOT; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: $var is not set in .env" >&2
    exit 1
  fi
done

echo "Creating data folders under ${DATA_ROOT}..."
mkdir -p \
  "${DATA_ROOT}/media/movies" \
  "${DATA_ROOT}/media/tv" \
  "${DATA_ROOT}/torrents/complete" \
  "${DATA_ROOT}/torrents/incomplete" \
  "${DATA_ROOT}/torrents/radarr" \
  "${DATA_ROOT}/torrents/sonarr" \
  "${DATA_ROOT}/watch"

echo "Creating config folders under ${CONFIG_ROOT}..."
mkdir -p \
  "${CONFIG_ROOT}/jellyfin" \
  "${CONFIG_ROOT}/prowlarr" \
  "${CONFIG_ROOT}/radarr" \
  "${CONFIG_ROOT}/sonarr" \
  "${CONFIG_ROOT}/bazarr" \
  "${CONFIG_ROOT}/gluetun" \
  "${CONFIG_ROOT}/transmission" \
  "${CONFIG_ROOT}/clamav/logs"

echo "Setting ownership to ${PUID}:${PGID}..."
chown -R "${PUID}:${PGID}" "${DATA_ROOT}" "${CONFIG_ROOT}"

echo "Done. Review the tree below, then run: docker compose up -d"
find "${DATA_ROOT}" "${CONFIG_ROOT}" -maxdepth 2
