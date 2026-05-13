local reconcile_timer = nil
local fullscreen_event_timer = nil
local reconciling = false
local scripted_fullscreen_events = 0
local manually_windowed = {}

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

local function solo_fullscreen_enabled()
    local preferences = load_preferences()
    if preferences.solo_fullscreen == nil then
        return true
    end

    return preferences.solo_fullscreen
end

local function is_manageable_window(window)
    return window ~= nil
        and window.mapped
        and not window.hidden
        and not window.pinned
end

local function window_key(window)
    if window == nil then
        return nil
    end

    if window.address ~= nil and window.address ~= "" then
        return window.address
    end

    if window.stable_id ~= nil then
        return tostring(window.stable_id)
    end

    return tostring(window)
end

local function solo_workspace_window(workspace)
    if workspace == nil then
        return nil
    end

    local windows = {}
    for _, window in ipairs(workspace:get_windows()) do
        if is_manageable_window(window) then
            table.insert(windows, window)
        end
    end

    if #windows ~= 1 then
        return nil
    end

    return windows[1]
end

local function has_client_fullscreen(window)
    return window.fullscreen_client ~= nil and window.fullscreen_client ~= 0
end

local function set_fullscreen_state(window, internal, client)
    scripted_fullscreen_events = scripted_fullscreen_events + 1
    hl.dispatch(hl.dsp.window.fullscreen_state({
        internal = internal,
        client = client,
        action = "set",
        window = window,
    }))
end

local function reconcile_workspace(workspace)
    if workspace == nil then
        return
    end

    local windows = {}
    for _, window in ipairs(workspace:get_windows()) do
        if is_manageable_window(window) then
            table.insert(windows, window)
        end
    end

    if not solo_fullscreen_enabled() then
        for _, window in ipairs(windows) do
            if window.fullscreen ~= 0 and not has_client_fullscreen(window) then
                set_fullscreen_state(window, 0, 0)
            end
        end
        return
    end

    if #windows == 1 then
        local window = windows[1]
        local key = window_key(window)
        if key ~= nil and manually_windowed[key] then
            return
        end

        if has_client_fullscreen(window) then
            return
        end

        if not window.floating and window.fullscreen ~= 2 then
            set_fullscreen_state(window, 2, 0)
        elseif window.floating and window.fullscreen ~= 0 then
            set_fullscreen_state(window, 0, 0)
        end
        return
    end

    for _, window in ipairs(windows) do
        if window.fullscreen ~= 0 and not has_client_fullscreen(window) then
            set_fullscreen_state(window, 0, 0)
        end
    end
end

local function reconcile_all()
    if reconciling then
        return
    end

    reconciling = true
    for _, workspace in ipairs(hl.get_workspaces()) do
        reconcile_workspace(workspace)
    end
    reconciling = false
end

local function schedule_reconcile()
    if reconcile_timer ~= nil then
        reconcile_timer:set_enabled(false)
        reconcile_timer = nil
    end

    reconcile_timer = hl.timer(function()
        reconcile_timer = nil
        reconcile_all()
    end, {
        timeout = 120,
        type = "oneshot",
    })
end

local function track_manual_fullscreen_toggle()
    if not solo_fullscreen_enabled() then
        schedule_reconcile()
        return
    end

    local active_window = hl.get_active_window()
    local solo_window = nil

    if active_window ~= nil and active_window.workspace ~= nil then
        solo_window = solo_workspace_window(active_window.workspace)
    end

    if solo_window == nil then
        local active_workspace = hl.get_active_workspace()
        solo_window = solo_workspace_window(active_workspace)
    end

    if solo_window ~= nil then
        local key = window_key(solo_window)
        if key ~= nil then
            if not solo_window.floating and solo_window.fullscreen == 0 then
                manually_windowed[key] = true
            else
                manually_windowed[key] = nil
            end
        end
    end

    schedule_reconcile()
end

local function schedule_fullscreen_event_tracking()
    if scripted_fullscreen_events > 0 then
        scripted_fullscreen_events = scripted_fullscreen_events - 1
        schedule_reconcile()
        return
    end

    if fullscreen_event_timer ~= nil then
        fullscreen_event_timer:set_enabled(false)
        fullscreen_event_timer = nil
    end

    fullscreen_event_timer = hl.timer(function()
        fullscreen_event_timer = nil
        track_manual_fullscreen_toggle()
    end, {
        timeout = 80,
        type = "oneshot",
    })
end

local function reset_manual_windowed()
    manually_windowed = {}
    schedule_reconcile()
end

for _, event in ipairs({
    "hyprland.start",
    "config.reloaded",
    "window.open",
    "window.close",
    "window.destroy",
    "window.move_to_workspace",
    "window.pin",
}) do
    hl.on(event, reset_manual_windowed)
end

for _, event in ipairs({
    "workspace.active",
    "workspace.created",
    "workspace.move_to_monitor",
}) do
    hl.on(event, schedule_reconcile)
end

hl.on("window.fullscreen", schedule_fullscreen_event_tracking)

schedule_reconcile()
