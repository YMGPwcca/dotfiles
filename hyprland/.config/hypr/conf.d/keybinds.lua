local vars = require("variables")

local mod = vars.main_mod
local script_path = vars.script_path
local zoom = script_path .. "/Zoom/run.sh"

local function bind(keys, dispatcher, opts)
    hl.bind(keys, dispatcher, opts)
end

local function exec(command)
    return hl.dsp.exec_cmd(command)
end

local function monitor_index()
    local active = hl.get_active_monitor()
    if active == nil then
        return 0
    end

    local monitors = hl.get_monitors()
    table.sort(monitors, function(left, right)
        if left.x == right.x then
            return left.name < right.name
        end
        return left.x < right.x
    end)

    for index, monitor in ipairs(monitors) do
        if monitor.name == active.name then
            return index - 1
        end
    end

    return 0
end

local function workspace_number(slot)
    return monitor_index() * 100 + slot
end

local function switch_workspace(slot)
    return function()
        hl.dispatch(hl.dsp.focus({ workspace = workspace_number(slot) }))
    end
end

local function move_to_workspace(slot)
    return function()
        hl.dispatch(hl.dsp.window.move({ workspace = workspace_number(slot) }))
    end
end

bind(mod .. " + Return", exec(vars.terminal))
bind(mod .. " + SHIFT + F", exec(vars.file_manager))
bind(mod .. " + SHIFT + Z", exec(vars.browser))

bind(mod .. " + W", hl.dsp.window.kill())
bind(mod .. " + SHIFT + Space", hl.dsp.window.float())
bind(mod .. " + P", hl.dsp.window.pseudo())
bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(mod .. " + F", hl.dsp.window.fullscreen())
bind(mod .. " + Tab", hl.dsp.layout("togglesplit"))

bind(mod .. " + equal", exec(zoom .. " in"))
bind(mod .. " + minus", exec(zoom .. " out"))

bind(mod .. " + V", hl.dsp.global("quickshell:clipboard_history"))

bind(mod .. " + H", hl.dsp.focus({ direction = "l" }))
bind(mod .. " + L", hl.dsp.focus({ direction = "r" }))
bind(mod .. " + K", hl.dsp.focus({ direction = "u" }))
bind(mod .. " + J", hl.dsp.focus({ direction = "d" }))

bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

bind(mod .. " + ALT + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true, locked = true })
bind(mod .. " + ALT + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true, locked = true })
bind(mod .. " + ALT + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true, locked = true })
bind(mod .. " + ALT + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true, locked = true })

bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

for i = 1, 9 do
    bind(mod .. " + " .. i, switch_workspace(i))
    bind(mod .. " + SHIFT + " .. i, move_to_workspace(i))
end
bind(mod .. " + 0", switch_workspace(10))
bind(mod .. " + SHIFT + 0", move_to_workspace(10))

bind("XF86AudioRaiseVolume", hl.dsp.global("quickshell:volume_up"), { repeating = true, locked = true })
bind("XF86AudioLowerVolume", hl.dsp.global("quickshell:volume_down"), { repeating = true, locked = true })
bind("XF86AudioMute", hl.dsp.global("quickshell:volume_mute"))

bind("XF86MonBrightnessUp", hl.dsp.global("quickshell:brightness_up"), { repeating = true, locked = true })
bind("XF86MonBrightnessDown", hl.dsp.global("quickshell:brightness_down"), { repeating = true, locked = true })

bind("XF86AudioNext", exec("playerctl next"), { locked = true })
bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioPlay", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioPrev", exec("playerctl previous"), { locked = true })

bind(mod .. " + SHIFT + R", exec("lyne reload"))
bind("Print", hl.dsp.global("quickshell:take_screenshot"))
bind(mod .. " + Escape", hl.dsp.global("quickshell:power_menu"))
bind(mod .. " + Space", hl.dsp.global("quickshell:app_launcher"))
bind(mod .. " + B", hl.dsp.global("quickshell:wallpaper_picker"))
bind(mod .. " + slash", hl.dsp.global("quickshell:keybinds_help"))
