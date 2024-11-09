local plugin_label = 'alfred_the_butler'

local gui          = require 'gui'
local utils        = require 'core.utils'
local settings     = require 'core.settings'
local task_manager = require 'core.task_manager'
local tracker      = require 'core.tracker'
local external     = require 'core.external'

local local_player

local function update_locals()
    local_player = get_local_player()
end

local function main_pulse()
    settings:update_settings()
    utils.update_tracker_count()
    tracker.timeout = tracker.last_reset + settings.timeout >= get_time_since_inject()

    if not local_player or not settings.enabled then return end

    if gui.elements.manual_keybind:get_state() == 1 then
        gui.elements.manual_keybind:set(false)
        external.resume()
        utils.reset_all_task()
        tracker.manual_trigger = true
        tracker.teleport = settings.use_teleport
    end
    if gui.elements.dump_keybind:get_state() == 1 then
        gui.elements.dump_keybind:set(false)
        -- utils.export_inventory_info()
        utils.export_actors()
    end

    if not (settings.get_keybind_state() or tracker.external_trigger or tracker.manual_trigger) then
        return
    end

    if orbwalker.get_orb_mode() ~= 3 then
        orbwalker.set_clear_toggle(true);
    end

    task_manager.execute_tasks()
end

local function render_pulse()
    if not local_player or not settings.enabled then return end
    local current_task = task_manager.get_current_task()
    local status = ''
    if tracker.external_caller and tracker.external_pause then
        status = 'Paused by ' .. tracker.external_caller
    elseif not settings.get_keybind_state() and not tracker.external_caller and not tracker.trigger_tasks then
        status = 'Paused'
    elseif current_task and tracker.external_caller then
        status = '(' .. tracker.external_caller .. ' - '
        status = status .. current_task.name .. ') '
        status = status .. current_task.status:gsub('%('..tracker.external_caller..'%)','')
    elseif current_task then
        status = '(' .. current_task.name .. ') ' .. current_task.status
    else
        status = 'Unknown'
    end
    local keybind_status = 'Off'
    if settings.get_keybind_state() then keybind_status = 'On' end

    local messages = {
        'Alfred Task   : ' .. status,
        'Keybind       : ' .. keybind_status,
        'Limit         : ' .. tracker.inventory_limit,
        'Inventory     : ' .. tracker.inventory_count,
        'Keep          : ' .. tracker.stash_count,
        'Salvage       : ' .. tracker.salvage_count,
        'Sell          : ' .. tracker.sell_count
    }

    if #tracker.restock_items ~= 0 then
        messages[#messages+1] = '-------------------'
        for _,item in pairs(tracker.restock_items) do
            messages[#messages+1] = item.name .. ' : ' .. item.count .. '/' .. item.max
        end
    end

    local y_pos = 50
    for _,msg in pairs(messages) do
        graphics.text_2d(msg, vec2:new(8, y_pos), 20, color_white(255))
        y_pos = y_pos + 20
    end
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

-- incase for some reason settings is not set for utils
if not utils.settings then
    utils.settings = settings
end
PLUGIN_alfred_the_butler = external