local function load_preferences()
    local path = (os.getenv("HOME") or "") .. "/.config/hypr/local/preferences.lua"
    local file = io.open(path, "r")
    if file == nil then
        return {}
    end
    file:close()

    local chunk, err = loadfile(path)
    if not chunk then
        error(err)
    end

    local preferences = chunk()
    if type(preferences) ~= "table" then
        return {}
    end

    return preferences
end

local preferences = load_preferences()
local swap_alt_win = preferences.swap_alt_win
if swap_alt_win == nil then
    swap_alt_win = true
end

hl.config({
    input = {
        kb_layout = preferences.kb_layout or "us",
        repeat_delay = 200,
        kb_model = "",
        kb_options = swap_alt_win and "altwin:swap_alt_win" or "",
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
