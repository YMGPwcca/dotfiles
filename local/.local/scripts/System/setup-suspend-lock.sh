#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

SLEEP_HOOK="/etc/systemd/system-sleep/90-quickshell-lock"
LOGIND_DIR="/etc/systemd/logind.conf.d"
LOGIND_FILE="${LOGIND_DIR}/10-suspend-on-lid-power.conf"

mkdir -p /etc/systemd/system-sleep
cat > "${SLEEP_HOOK}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# systemd calls: <script> pre|post suspend|hibernate|...
if [[ "${1:-}" != "pre" ]]; then
  exit 0
fi

lock_hypr_session_for_uid() {
  local uid="$1"
  local user
  user="$(id -nu "$uid" 2>/dev/null || true)"
  [[ -n "$user" ]] || return 0

  local runtime="/run/user/$uid"
  [[ -d "$runtime" ]] || return 0

  local sigdir sig
  for sigdir in "$runtime"/hypr/*; do
    [[ -d "$sigdir" ]] || continue
    sig="$(basename "$sigdir")"

    runuser -u "$user" -- env \
      XDG_RUNTIME_DIR="$runtime" \
      HYPRLAND_INSTANCE_SIGNATURE="$sig" \
      PATH=/usr/bin:/bin \
      hyprctl dispatch global quickshell:lock_screen >/dev/null 2>&1 || true
  done
}

# Try all logged-in user sessions; this covers lid-close and power-button suspend paths.
while read -r sid _; do
  [[ -n "$sid" ]] || continue
  uid="$(loginctl show-session "$sid" -p User --value 2>/dev/null || true)"
  [[ -n "$uid" ]] || continue
  lock_hypr_session_for_uid "$uid"
done < <(loginctl list-sessions --no-legend 2>/dev/null)

# Fallback: ask logind to lock sessions too (for non-Hypr sessions).
loginctl lock-sessions >/dev/null 2>&1 || true

# Give lock surfaces a brief moment to map before sleep.
sleep 0.7
EOF
chmod 0755 "${SLEEP_HOOK}"

mkdir -p "${LOGIND_DIR}"
cat > "${LOGIND_FILE}" <<'EOF'
[Login]
HandlePowerKey=suspend
HandleSuspendKey=suspend
HandleLidSwitch=suspend
HandleLidSwitchDocked=suspend
HandleLidSwitchExternalPower=suspend
EOF

echo "Created sleep hook: ${SLEEP_HOOK}"
echo "Created logind policy: ${LOGIND_FILE}"
echo "Reboot (recommended) or restart systemd-logind for lid/power-button policy changes."
