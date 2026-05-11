local plugin_path = "/home/pwcca/.local/share/hyprplugins/hypr-dynamic-cursors/out/dynamic-cursors.so"

local file = io.open(plugin_path, "r")
if file ~= nil then
    file:close()
    pcall(function()
        hl.plugin.load(plugin_path)
    end)
end
