local home = os.getenv("HOME") or error("HOME is not set")

hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell")
    hl.exec_cmd("kbuildsycoca6")
    hl.exec_cmd("hyprsunset -t 7000")
    hl.exec_cmd("xingyao-osd-notify")

    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && " .. home .. "/.local/scripts/Wallpaper/wallpaper-boot.sh")

    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    hl.exec_cmd(home .. "/.local/scripts/Workspace-Manager/workspace-manager.sh --auto-update")
    hl.exec_cmd("sleep 2 && " .. home .. "/.local/scripts/Hyprland/desktop-like-controls.sh")
end)
