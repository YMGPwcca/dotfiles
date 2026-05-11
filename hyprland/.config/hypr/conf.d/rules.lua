hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "pip-window",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin = true,
    no_shadow = true,
    size = { 600, 340 },
    move = { "monitor_w-window_w-20", "monitor_h-window_h-20" },
    no_initial_focus = true,
})

hl.window_rule({
    name = "satty-float",
    match = { class = "^(com\\.gabm\\.satty)$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "kcalc-float",
    match = { class = "^(org\\.kde\\.kcalc)$" },
    float = true,
    size = { 360, 540 },
    center = true,
    pin = true,
})
