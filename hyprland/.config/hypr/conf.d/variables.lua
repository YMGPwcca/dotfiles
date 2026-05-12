local home = os.getenv("HOME") or "/home/pwcca"

local vars = {
    terminal = "kitty",
    file_manager = "dolphin",
    browser = "zen-browser",
    script_path = home .. "/.local/scripts",
    main_mod = "SUPER",
}

_G.Dotfiles = vars

return vars
