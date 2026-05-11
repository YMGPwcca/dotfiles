hl.config({
    input = {
        kb_layout = "us",
        repeat_delay = 200,
        kb_model = "",
        kb_options = "altwin:swap_alt_win",
        kb_rules = "",
        accel_profile = "flat",
        follow_mouse = 1,
        sensitivity = -0.6,
        touchpad = {
            natural_scroll = true,
            scroll_factor = 0.5,
            clickfinger_behavior = true,
            tap_to_click = true,
        },
    },

    cursor = {
        no_hardware_cursors = true,
    },
})

hl.device({
    name = "bltp7853:00-347d:7853-touchpad",
    accel_profile = "flat",
    sensitivity = 1,
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
