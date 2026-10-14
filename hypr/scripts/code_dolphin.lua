#!/usr/bin/env lua

-- Fetch active window info directly from Hyprland
local handle = io.popen("hyprctl activewindow")
local result = handle:read("*a")
handle:close()

-- Exit silently if the active window is not Dolphin
if not result:match("class: org%.kde%.dolphin") then
    os.exit(0)
end

-- Extract the window title string
local title = result:match("title: ([^\n]+)")
if not title then
    os.exit(1)
end

-- Strip the trailing suffix. KDE typically uses an em-dash ('—') or hyphen ('-')
local path = title:match("^(.*) — Dolphin") or title:match("^(.*) %- Dolphin")

if path then
    -- Escape any single quotes in the directory name for the shell
    local safe_path = path:gsub("'", "'\\''")
    -- Launch VS Code detached
    os.execute("code '" .. safe_path .. "' &")
end