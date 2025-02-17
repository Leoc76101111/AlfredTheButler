local plugin_label = 'alfred_the_butler'

local gui          = require 'gui'
local utils        = require 'core.utils'
local settings     = require 'core.settings'
local task_manager = require 'core.task_manager'
local tracker      = require 'core.tracker'
local external     = require 'core.external'
local drawing      = require 'core.drawing'
local json = require 'core.json'

local local_player
local debounce_time = nil
local debounce_timeout = 1
local keybind_data = checkbox:new(false, get_hash(plugin_label .. '_keybind_data'))
if PERSISTENT_MODE ~= nil and PERSISTENT_MODE ~= false then
    gui.elements.keybind_toggle:set(keybind_data:get())
end

local function update_locals()
    local_player = get_local_player()
end

local function main_pulse()
    settings:update_settings()
    tracker.timeout = tracker.last_reset + settings.timeout >= get_time_since_inject()
    if PERSISTENT_MODE ~= nil and PERSISTENT_MODE ~= false  then
        if keybind_data:get() ~= (gui.elements.keybind_toggle:get_state() == 1) then
            keybind_data:set(gui.elements.keybind_toggle:get_state() == 1)
        end
    end

    if not local_player or not settings.enabled then return end
    utils.update_tracker_count(local_player)

    if gui.elements.manual_keybind:get_state() == 1 then
        if debounce_time ~= nil and debounce_time + debounce_timeout > get_time_since_inject() then return end
        gui.elements.manual_keybind:set(false)
        debounce_time = get_time_since_inject()
        external.resume()
        utils.reset_restock_stash_count()
        utils.reset_all_task()
        tracker.manual_trigger = true
        if not utils.player_in_zone('Scos_Cerrigar') then
            tracker.teleport = true
        end
    end

    if gui.elements.dump_keybind:get_state() == 1 then
        if debounce_time ~= nil and debounce_time + debounce_timeout > get_time_since_inject() then return end
        gui.elements.dump_keybind:set(false)
        debounce_time = get_time_since_inject()
        external.trigger_tasks_with_teleport('test')
        -- utils.dump_tracker_info(tracker)
        -- utils.log(local_player:get_attribute(attributes.PLAYER_IS_PARTY_INVITABLE))
        -- utils.export_inventory_info()
        -- local vendor_items = loot_manager.get_vendor_items()
        -- if type(vendor_items) == "userdata" and vendor_items.size then
        --     local size = vendor_items:size()
        --     console.print(size)
        --     for i = 1, size do
        --         local item = vendor_items:get(i)
        --         if item then
        --             console.print(item:get_display_name())
        --             console.print(item:get_price())
        --         end
        --     end
        -- end
        -- local glp = get_glyphs()
        -- utils.log('hi')
        -- utils.log(glp:size() > 0)
        -- utils.log(glp:get(1).glyph_instance)
        -- utils.log(glp:get(1).glyph_id)
        -- utils.log(glp:get(1).glyph_name_hash)
        -- utils.log(glp:get(1):get_name())
        -- utils.log(glp:get(1):get_max_level())
        -- utils.log(glp:get(1):get_level())
        -- utils.log(glp:get(1):can_upgrade())
        -- utils.log(glp:get(1):get_upgrade_chance())

        -- utils.log('aa')
        -- local gizmo = utils.get_npc("Gizmo_Paragon_Glyph_Upgrade")
        -- interact_vendor(gizmo)
        -- upgrade_glyph(glp:get(1))
        -- for key,val in pairs(getmetatable(glp:get(1))) do
        --     utils.log(key)
        --     utils.log(val)
        -- end
        -- utils.log(glp)
    end

    if not (settings.get_keybind_state() or tracker.external_trigger or tracker.manual_trigger) then
        return
    end

    task_manager.execute_tasks()
end

local function render_pulse()
    if not local_player or not settings.enabled then return end

    if gui.elements.draw_status:get() then
        drawing.draw_status()
    end
    if is_inventory_open() and get_open_inventory_bag() == 0 and
        (gui.elements.draw_stash:get() or
        gui.elements.draw_sell:get() or
        gui.elements.draw_salvage:get())
    then
        drawing.draw_inventory_boxes()
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