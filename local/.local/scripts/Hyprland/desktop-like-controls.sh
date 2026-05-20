#!/usr/bin/env bash

set -u

if ! command -v hyprctl >/dev/null 2>&1; then
    exit 0
fi

plugin_path=""
for candidate in \
    "/usr/lib/hyprland/plugins/hyprbars.so" \
    "/usr/lib/libhyprbars.so" \
    "/usr/lib/hyprbars.so"
do
    if [[ -f "$candidate" ]]; then
        plugin_path="$candidate"
        break
    fi
done

if [[ -z "$plugin_path" ]]; then
    exit 0
fi

hyprctl plugin unload "$plugin_path" >/dev/null 2>&1 || true
hyprctl plugin load "$plugin_path" >/dev/null 2>&1 || exit 0

set_keyword() {
    local key="$1"
    local value="$2"
    hyprctl keyword "$key" "$value" >/dev/null 2>&1 || true
}

set_keyword "plugin:hyprbars:bar_height" "30"
set_keyword "plugin:hyprbars:bar_padding" "8"
set_keyword "plugin:hyprbars:bar_button_padding" "8"
set_keyword "plugin:hyprbars:bar_precedence_over_border" "true"
set_keyword "plugin:hyprbars:bar_part_of_window" "true"
set_keyword "plugin:hyprbars:bar_title_enabled" "true"
set_keyword "plugin:hyprbars:hyprbars-button" "rgb(f7768e), 12, X, hyprctl dispatch killactive"
set_keyword "plugin:hyprbars:hyprbars-button" "rgb(e0af68), 12, [], hyprctl dispatch fullscreen 1"
set_keyword "plugin:hyprbars:hyprbars-button" "rgb(9ece6a), 12, _, hyprctl dispatch movetoworkspacesilent special:minimized"
