-- Hyprland 0.55 Lua entrypoint.

local config_dir = (os.getenv("HOME") or "") .. "/.config/hypr"

package.path = table.concat({
    config_dir .. "/?.lua",
    config_dir .. "/?/init.lua",
    config_dir .. "/conf.d/?.lua",
    config_dir .. "/local/?.lua",
    package.path,
}, ";")

local function source(module)
    require(module)
end

local function source_file_if_exists(path)
    local file = io.open(path, "r")
    if file == nil then
        return
    end
    file:close()

    local chunk, err = loadfile(path)
    if not chunk then
        error(err)
    end
    chunk()
end

source("variables")
source("environment")
source("autostart")
source("appearance")
source("input")
source("dynamic-cursors")
source("rules")
source("solo-fullscreen")
source("keybinds")

source_file_if_exists(config_dir .. "/monitors.lua")
source_file_if_exists(config_dir .. "/workspaces.lua")
source_file_if_exists(config_dir .. "/local/extra_environment.lua")
source_file_if_exists(config_dir .. "/local/autostart.lua")
source_file_if_exists(config_dir .. "/local/extra_keybinds.lua")
