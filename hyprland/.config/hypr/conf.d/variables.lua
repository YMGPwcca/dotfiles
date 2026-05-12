local home = os.getenv("HOME") or error("HOME is not set")

local vars = {
    terminal = "kitty",
    file_manager = "dolphin",
    browser = "zen-browser",
    main_mod = "SUPER",
}

_G.Dotfiles = vars

return vars
