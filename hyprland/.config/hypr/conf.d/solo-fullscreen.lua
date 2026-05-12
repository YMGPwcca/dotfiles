local reconcile_timer = nil
local reconciling = false

local function is_manageable_window(window)
    return window ~= nil
        and window.mapped
        and not window.hidden
        and not window.pinned
end

local function set_fullscreen_state(window, internal, client)
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

    if #windows == 1 then
        local window = windows[1]
        if not window.floating and (window.fullscreen ~= 2 or window.fullscreen_client ~= 0) then
            set_fullscreen_state(window, 2, 0)
        elseif window.floating and window.fullscreen ~= 0 then
            set_fullscreen_state(window, 0, 0)
        end
        return
    end

    for _, window in ipairs(windows) do
        if window.fullscreen ~= 0 then
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

for _, event in ipairs({
    "hyprland.start",
    "config.reloaded",
    "window.open",
    "window.close",
    "window.destroy",
    "window.fullscreen",
    "window.move_to_workspace",
    "window.pin",
    "workspace.active",
    "workspace.created",
    "workspace.move_to_monitor",
}) do
    hl.on(event, schedule_reconcile)
end

schedule_reconcile()
