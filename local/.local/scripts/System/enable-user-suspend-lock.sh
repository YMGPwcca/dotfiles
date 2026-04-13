#!/usr/bin/env bash
set -euo pipefail

systemctl --user daemon-reload
systemctl --user enable quickshell-lock-before-sleep.service

echo "Enabled: quickshell-lock-before-sleep.service (WantedBy=sleep.target)"
echo "If this was just installed, log out/in once before testing lid/power-button suspend."
