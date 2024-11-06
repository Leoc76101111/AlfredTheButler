local plugin_label = 'alfred_the_butler'

local gui          = require 'gui'
local utils        = require 'core.utils'
local settings     = require 'core.settings'
local task_manager = require 'core.task_manager'
local tracker      = require 'core.tracker'

local local_player

local function update_locals()
    local_player = get_local_player()
end

local function main_pulse()
    settings:update_settings()
    if not local_player or not (settings.enabled and settings.get_keybind_state()) then return end
    if orbwalker.get_orb_mode() ~= 3 then
        orbwalker.set_clear_toggle(true);
    end
    utils.update_tracker_count()
    task_manager.execute_tasks()
end

local function render_pulse()
    if not local_player or not settings.enabled then return end
    utils.update_tracker_count()

    if gui.elements.manual_keybind:get_state() == 1 then
        gui.elements.manual_keybind:set(false)
        tracker.last_reset = 0
        tracker.trigger_tasks = true
        tracker.salvage_failed = false
        tracker.sell_failed = false
        tracker.salvage_done = false
        tracker.sell_done = false
    end
    if gui.elements.dump_keybind:get_state() == 1 then
        utils.export_inventory_info()
    end

    local current_task = task_manager.get_current_task()
    if not settings.get_keybind_state() then
        graphics.text_2d('Alfred Task: Paused', vec2:new(8, 50), 20, color_white(255))
    elseif current_task then
        graphics.text_2d('Alfred Task: ' .. current_task.status, vec2:new(8, 50), 20, color_white(255))
    else
        graphics.text_2d('Alfred Task: Unknown', vec2:new(8, 50), 20, color_white(255))
    end
    graphics.text_2d('Limit      : ' .. tracker.inventory_limit , vec2:new(8, 70), 20, color_white(255))
    graphics.text_2d('Inventory  : ' .. tracker.inventory_count , vec2:new(8, 90), 20, color_white(255))
    graphics.text_2d('Keep       : ' .. tracker.stash_count, vec2:new(8, 110), 20, color_white(255))
    graphics.text_2d('Salvage    : ' .. tracker.salvage_count, vec2:new(8, 130), 20, color_white(255))
    graphics.text_2d('Sell       : ' .. tracker.sell_count, vec2:new(8, 150), 20, color_white(255))

end

on_update(function()
    update_locals()
    main_pulse()
end)
on_render_menu(function ()
    gui.render()
    if gui.elements.affix_export_button:get() then
        utils.export_filters(gui.elements,false)
    elseif gui.elements.affix_import_button:get() then
        if gui.elements.affix_import_name:get() ~= '' then
            utils.import_filters(gui.elements)
        else
            utils.log('no import file name')
        end
    end
end)
on_render(render_pulse)

-- incase for somet reason settings is not set for utils
if not utils.settings then
    utils.settings = settings
end
PLUGIN_alfred_the_butler = tracker.external_tracker