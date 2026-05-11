local home = os.getenv("HOME") or "/home/pwcca"

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("AQ_FORCE_LINEAR_BLIT", "0")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_MENU_PREFIX", "arch-")

hl.env("GTK_THEME", "adw-gtk3-dark")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

hl.env("XCURSOR_SIZE", "32")
hl.env("XCURSOR_THEME", "AgnesTachyonCursor")

hl.env("PATH", home .. "/.local/bin:" .. (os.getenv("PATH") or ""))
hl.env("HYPRSHOT_DIR", home .. "/Pictures/Screenshots")
