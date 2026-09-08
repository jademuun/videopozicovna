#!/usr/bin/env bash
# Installs the ClamAV desktop-notification check as a systemd --user timer
# that fires shortly after login (covers reboot). Safe to re-run.
#
# The resume-from-sleep half needs a root-owned hook (systemd-sleep scripts
# only run at the system level — a user session has no visibility into
# suspend/resume at all) and is NOT installed by this script. Do that one
# step yourself, once:
#
#   sudo install -m 755 systemd-sleep/90-clamav-resume-check \
#     /etc/systemd/system-sleep/90-clamav-resume-check
#
# Edit that file's TARGET_USER first if your desktop login isn't "arthas".
set -euo pipefail
cd "$(dirname "$0")"

BIN_DIR="$HOME/.local/bin"
UNIT_DIR="$HOME/.config/systemd/user"
SCRIPT_DEST="$BIN_DIR/check-clamav-harrison.sh"

mkdir -p "$BIN_DIR" "$UNIT_DIR"

install -m 755 check-clamav-harrison.sh "$SCRIPT_DEST"

sed "s|__SCRIPT_PATH__|$SCRIPT_DEST|" systemd/clamav-check.service.template \
  > "$UNIT_DIR/clamav-check.service"
install -m 644 systemd/clamav-check.timer "$UNIT_DIR/clamav-check.timer"

systemctl --user daemon-reload
systemctl --user enable --now clamav-check.timer

echo "Installed and enabled clamav-check.timer (fires ~30s after login/reboot)."
echo
echo "To also notify on resume from sleep, run once as root:"
echo "  sudo install -m 755 $(pwd)/systemd-sleep/90-clamav-resume-check /etc/systemd/system-sleep/90-clamav-resume-check"
