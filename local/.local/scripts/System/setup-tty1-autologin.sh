#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo $0 [username]" >&2
  exit 1
fi

TARGET_USER="${1:-${SUDO_USER:-}}"
if [[ -z "${TARGET_USER}" ]]; then
  echo "Could not determine target user. Pass it explicitly: sudo $0 <username>" >&2
  exit 1
fi

OVERRIDE_DIR="/etc/systemd/system/getty@tty1.service.d"
OVERRIDE_FILE="${OVERRIDE_DIR}/override.conf"

mkdir -p "${OVERRIDE_DIR}"
cat > "${OVERRIDE_FILE}" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin ${TARGET_USER} --noclear %I \$TERM
Type=idle
EOF

systemctl daemon-reload

echo "Created ${OVERRIDE_FILE}"
echo "Autologin on tty1 is now configured for user: ${TARGET_USER}"
echo "Reboot (or restart getty@tty1 from another TTY) to apply safely."
