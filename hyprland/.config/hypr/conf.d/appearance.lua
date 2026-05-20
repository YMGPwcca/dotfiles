hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 1,
        col = {
            active_border = "rgba(7aa2f7ff)",
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "master",
    },

    render = {
        direct_scanout = 0,
    },

    decoration = {
        rounding = 7,
        rounding_power = 20,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            brightness = 1.0,
            noise = 0.00,
            contrast = 1.0,
            xray = false,
            popups = true,
            popups_ignorealpha = 0.5,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },
})

hl.layer_rule({
    name = "modules",
    match = { namespace = "qs_modules" },
    blur = true,
    ignore_alpha = 0.5,
    no_anim = true,
})

hl.layer_rule({
    name = "power",
    match = { namespace = "qs_powerOverlay" },
    blur = true,
    no_anim = true,
    ignore_alpha = 0,
})

hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })

hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "emphasizedAccel", style = "slide" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 4, bezier = "standard" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "standard" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "standard" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "specialWorkSwitch", style = "slidefadevert 15%" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "standard" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "standard" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "standard" })
