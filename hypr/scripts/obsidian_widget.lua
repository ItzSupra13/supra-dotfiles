#!/usr/bin/env lua
-- For running first install: sudo pacman -S gtk3 gtk-layer-shell lua51 lua51-lgi
-- Needs permission: chmod +x ~/.config/hypr/scripts/obsidian_widget.lua
-- Testing: pkill -f obsidian_widget.lua && lua5.1 ~/.config/hypr/scripts/obsidian_widget.lua & disown

local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "3.0")
local GLib = lgi.GLib
local GtkLayerShell = lgi.require("GtkLayerShell", "0.1")
local os = require("os")
local io = require("io")

-- --- CONFIGURATION ---
local DAILY_NOTES_DIR = "/home/supra13/Documents/Something/Daily Shit"
-- ---------------------

local function escape_markup(text)
    text = text:gsub("&", "&amp;")
    text = text:gsub("<", "&lt;")
    text = text:gsub(">", "&gt;")
    return text
end

local function get_daily_file_path()
    local today = os.date("%Y-%m-%d")
    return DAILY_NOTES_DIR .. "/" .. today .. ".md"
end

-- Reads tasks and sorts them (Pending first, Done last)
local function get_tasks_data()
    local file_path = get_daily_file_path()
    local f = io.open(file_path, "r")
    
    local pending = {}
    local done = {}
    
    if not f then return {} end
    
    for line in f:lines() do
        if line:match("^%- %[ %]") then
            local task = line:sub(6):match("^%s*(.-)%s*$")
            table.insert(pending, {text = task, done = false})
        elseif line:match("^%- %[x%]") or line:match("^%- %[X%]") then
            local task = line:sub(6):match("^%s*(.-)%s*$")
            table.insert(done, {text = task, done = true})
        end
    end
    f:close()
    
    local tasks = {}
    for _, t in ipairs(pending) do table.insert(tasks, t) end
    for _, t in ipairs(done) do table.insert(tasks, t) end
    return tasks
end

local function add_task_to_file(text)
    local file_path = get_daily_file_path()
    os.execute('mkdir -p "' .. DAILY_NOTES_DIR .. '"')

    local f = io.open(file_path, "r")
    local needs_newline = false
    local exists = f ~= nil
    if f then
        local content = f:read("*a")
        f:close()
        needs_newline = content ~= "" and content:sub(-1) ~= "\n"
    end

    f = io.open(file_path, "a")
    if not f then return end
    if not exists then
        f:write("\n")
    elseif needs_newline then
        f:write("\n")
    end
    f:write("- [ ] " .. text .. "\n")
    f:close()
end

local function toggle_task_in_file(text, is_currently_done)
    local file_path = get_daily_file_path()
    local f = io.open(file_path, "r")
    if not f then return end
    
    local lines = {}
    local toggled = false
    local target_prefix = is_currently_done and "^%- %[[xX]%]" or "^%- %[ %]"
    
    for line in f:lines() do
        if not toggled and line:match(target_prefix) and line:find(text, 1, true) then
            if is_currently_done then
                line = line:gsub("^%- %[[xX]%]", "- [ ]", 1)
            else
                line = line:gsub("^%- %[ %]", "- [x]", 1)
            end
            toggled = true
        end
        table.insert(lines, line)
    end
    f:close()
    
    f = io.open(file_path, "w")
    for _, line in ipairs(lines) do
        f:write(line .. "\n")
    end
    f:close()
end

local function get_active_workspace_windows()
    local handle = io.popen("hyprctl activeworkspace -j 2>/dev/null")
    if not handle then return 0 end
    local result = handle:read("*a")
    handle:close()
    
    local windows = result:match('"windows"%s*:%s*(%d+)')
    return tonumber(windows) or 0
end

local window = Gtk.Window { type = Gtk.WindowType.TOPLEVEL }
GtkLayerShell.init_for_window(window)
GtkLayerShell.set_layer(window, GtkLayerShell.Layer.BACKGROUND)
GtkLayerShell.set_anchor(window, GtkLayerShell.Edge.TOP, true)
GtkLayerShell.set_anchor(window, GtkLayerShell.Edge.LEFT, true)
GtkLayerShell.set_margin(window, GtkLayerShell.Edge.TOP, 0)
GtkLayerShell.set_margin(window, GtkLayerShell.Edge.LEFT, 20)

-- CRITICAL: Allows the entry box to receive keyboard focus
GtkLayerShell.set_keyboard_mode(window, GtkLayerShell.KeyboardMode.ON_DEMAND)

window:set_app_paintable(true)
local screen = window:get_screen()
local visual = screen:get_rgba_visual()
if visual then window:set_visual(visual) end

local provider = Gtk.CssProvider()
provider:load_from_data([=[
    #main-box {
        background-color: #0d0d0d;
        border-radius: 0 0 6px 6px;
        padding: 20px 24px;
    }
    #title-label {
        color: #F1AA76;
        font-family: "Playfair Display", serif;
        font-size: 18px;
        font-weight: bold;
    }
    #add-btn {
        color: rgba(241, 170, 118, 0.7);
        font-size: 22px;
        font-weight: bold;
    }
    #add-btn:hover {
        color: #ffffff;
    }
    #task-icon {
        color: #F1AA76;
        font-family: "Symbols Nerd Font", "JetBrainsMono Nerd Font", sans-serif;
        font-size: 15px;
    }
    #task-icon-done {
        color: rgba(241, 170, 118, 0.45);
        font-family: "Symbols Nerd Font", "JetBrainsMono Nerd Font", sans-serif;
        font-size: 15px;
    }
    #task-text {
        color: #ffffff;
        font-family: sans-serif;
        font-size: 15px;
    }
    #task-text-done {
        color: rgba(241, 170, 118, 0.45);
        font-family: sans-serif;
        font-size: 15px;
    }
    #new-task-entry {
        background-color: transparent;
        color: #F1AA76;
        border: none;
        border-bottom: 1px solid rgba(241, 170, 118, 0.5);
        border-radius: 0;
        font-family: sans-serif;
        font-size: 15px;
        min-height: 24px;
    }
    #new-task-entry:focus {
        border-bottom: 2px solid #F1AA76;
        box-shadow: none;
    }
    #progress-text {
        color: rgba(241, 170, 118, 0.8);
        font-family: sans-serif;
        font-size: 11px;
        font-weight: bold;
    }
    progressbar trough {
        background-color: rgba(241, 170, 118, 0.15);
        border-radius: 4px;
        min-height: 4px;
    }
    progressbar progress {
        background-color: #F1AA76;
        border-radius: 4px;
    }
]=])
Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

local main_box = Gtk.Box { orientation = Gtk.Orientation.VERTICAL, spacing = 20, name = "main-box" }

local title_label = Gtk.Label { label = "Today's Tasks", name = "title-label" }

local add_btn_event = Gtk.EventBox { visible_window = false } 
local add_btn_label = Gtk.Label { label = "+", name = "add-btn" }
add_btn_event:add(add_btn_label)

local title_center_box = Gtk.Box { orientation = Gtk.Orientation.HORIZONTAL }
title_center_box:pack_start(title_label, false, false, 0)
title_center_box:pack_end(add_btn_event, false, false, 0)

local new_task_box = Gtk.Box { orientation = Gtk.Orientation.HORIZONTAL, spacing = 12 }
local new_task_icon = Gtk.Label { label = "◯", name = "task-icon", halign = Gtk.Align.START }
local new_task_entry = Gtk.Entry { name = "new-task-entry", hexpand = true }
new_task_box:pack_start(new_task_icon, false, false, 0)
new_task_box:pack_start(new_task_entry, true, true, 0)

-- Hide wrapper by default
new_task_box:set_no_show_all(true)

local tasks_box = Gtk.Box { orientation = Gtk.Orientation.VERTICAL, spacing = 14 }

local progress_box = Gtk.Box { orientation = Gtk.Orientation.HORIZONTAL, spacing = 16 }
local progress_label_left = Gtk.Label { name = "progress-text" }
local progress_bar = Gtk.ProgressBar { valign = Gtk.Align.CENTER, hexpand = true }
local progress_label_right = Gtk.Label { name = "progress-text" }

progress_box:pack_start(progress_label_left, false, false, 0)
progress_box:pack_start(progress_bar, true, true, 0)
progress_box:pack_start(progress_label_right, false, false, 0)

main_box:pack_start(title_center_box, false, false, 0)
main_box:pack_start(new_task_box, false, false, 0)
main_box:pack_start(tasks_box, false, false, 0)
main_box:pack_start(progress_box, false, false, 0)
window:add(main_box)

local last_tasks_state = nil
local refresh_tasks

-- INTERACTIONS ----------------------------------------------------

local function show_entry()
    new_task_box:show()
    new_task_icon:show()
    new_task_entry:show()
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, function()
        new_task_entry:grab_focus()
        return false
    end)
end

local function hide_entry()
    new_task_entry:set_text("")
    new_task_box:hide()
end

add_btn_event.on_button_press_event = function()
    if new_task_box:get_visible() then
        hide_entry()
    else
        show_entry()
    end
    return true
end

new_task_entry.on_activate = function(self)
    local text = self:get_text()
    if text and text ~= "" then
        add_task_to_file(text)
        hide_entry()
        last_tasks_state = nil
        refresh_tasks()
    end
end

new_task_entry.on_key_press_event = function(_, event)
    if event.keyval == 0xff1b then  -- Escape
        hide_entry()
        return true
    end
    return false
end

--------------------------------------------------------------------

-- Pick one style
local ICON_STYLES = {
    nerd        = { todo = "\239\130\150", done = "\239\129\134" },  -- square → checked square
    nerd_circle = { todo = "\239\132\140", done = "\239\129\152" },  -- circle → checked circle
    unicode     = { todo = "☐", done = "☑" },
    small       = { todo = "○", done = "●" },
}

local ICONS = ICON_STYLES.nerd

refresh_tasks = function()
    local tasks = get_tasks_data()
    
    local current_state = ""
    for _, t in ipairs(tasks) do 
        current_state = current_state .. tostring(t.done) .. t.text 
    end
    
    if current_state == last_tasks_state then return end
    last_tasks_state = current_state

    for _, child in ipairs(tasks_box:get_children()) do
        tasks_box:remove(child)
    end
    
    local total = #tasks
    local completed = 0
    for _, t in ipairs(tasks) do 
        if t.done then completed = completed + 1 end 
    end
    
    if total == 0 then
        local empty = Gtk.Label { label = "No tasks found for today.", name = "task-text-done", halign = Gtk.Align.START }
        tasks_box:pack_start(empty, false, false, 0)
        progress_label_left:set_text("0 of 0")
        progress_bar:set_fraction(0)
        progress_label_right:set_text("0%")
    else
        local fraction = completed / total
        for _, task in ipairs(tasks) do
            local task_event_box = Gtk.EventBox { visible_window = false }
            local row = Gtk.Box { orientation = Gtk.Orientation.HORIZONTAL, spacing = 12 }
            
            local icon = Gtk.Label { label = ICONS.todo, name = "task-icon", halign = Gtk.Align.START }
            local text = Gtk.Label { halign = Gtk.Align.START }
            
            if task.done then
                icon:set_text(ICONS.done)
                icon.name = "task-icon-done"
                text:set_markup("<span strikethrough='true'>" .. escape_markup(task.text) .. "</span>")
                text.name = "task-text-done"
            else
                icon:set_text(ICONS.todo)
                icon.name = "task-icon"
                text:set_text(task.text)
                text.name = "task-text"
            end
            
            row:pack_start(icon, false, false, 0)
            row:pack_start(text, false, false, 0)
            task_event_box:add(row)
            
            task_event_box.on_button_press_event = function()
                toggle_task_in_file(task.text, task.done)
                last_tasks_state = nil
                refresh_tasks()
                return true
            end
            
            tasks_box:pack_start(task_event_box, false, false, 0)
        end
        
        progress_label_left:set_text(completed .. " of " .. total)
        progress_bar:set_fraction(fraction)
        progress_label_right:set_text(math.floor(fraction * 100) .. "%")
    end
    
    tasks_box:show_all()
end

local function update_ui()
    if get_active_workspace_windows() > 0 then
        window:hide()
    else
        refresh_tasks()
        window:show_all()
    end
    return true
end

update_ui()
GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, update_ui)
Gtk.main()