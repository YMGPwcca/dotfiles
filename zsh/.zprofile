# Auto-start Hyprland session on tty1 login.
# This runs only for local interactive login shells on the first VT.
if [[ -o login && -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && "${XDG_VTNR:-0}" -eq 1 ]]; then
  if command -v uwsm >/dev/null 2>&1; then
    exec uwsm start hyprland-uwsm.desktop
  fi
fi
