#!/usr/bin/env bash
# Checks harrison's ClamAV scan log for the videopozicovna stack and pops a
# desktop notification if the most recent run found something infected.
# Safe to run repeatedly (only notifies once per distinct scan run).
set -euo pipefail

HOST="harrison"
REMOTE_LOG="/srv/docker/clamav/logs/scan.log"
STATE_FILE="$HOME/.cache/clamav-harrison-last-notified"

# Grab the most recent SCAN SUMMARY block (Start Date + Infected files count).
summary=$(ssh -o ConnectTimeout=10 "$HOST" "tac '$REMOTE_LOG' 2>/dev/null | awk '/^Start Date:/{print;c++} /^Infected files:/{print;c++} c==2{exit}'" 2>/dev/null || true)

if [[ -z "$summary" ]]; then
  # Host unreachable or no scan has run yet — stay quiet, nothing to report.
  exit 0
fi

start_date=$(grep '^Start Date:' <<<"$summary" | head -1 | cut -d: -f2- | xargs)
infected=$(grep '^Infected files:' <<<"$summary" | head -1 | awk '{print $NF}')
[[ "$infected" =~ ^[0-9]+$ ]] || exit 0

last_notified=""
[[ -f "$STATE_FILE" ]] && last_notified=$(cat "$STATE_FILE")

if [[ "$infected" -gt 0 && "$start_date" != "$last_notified" ]]; then
  notify-send -u critical "ClamAV: infected file(s) found on harrison" \
    "$infected infected file(s) in the last scan (run started $start_date). Check: ssh harrison 'grep -A6 FOUND $REMOTE_LOG'"
  echo "$start_date" > "$STATE_FILE"
fi
