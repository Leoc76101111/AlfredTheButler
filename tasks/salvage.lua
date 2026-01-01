local plugin_label = 'alfred_the_butler'

local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local explorerlite = require 'core.explorerlite'
local base_task = require 'tasks.base'

local task = base_task.new_task()
local status_enum = {
    IDLE = 'Idle',
    EXECUTE = 'Salvaging',
    MOVING = 'Moving to blacksmith',
    INTERACTING = 'Interacting with blacksmith',
    RESETTING = 'Re-trying salvage',
    FAILED = 'Failed to salvage'
}

local extension = {}
function extension.get_npc()
    return utils.get_npc(utils.npc_enum['BLACKSMITH'])
end
function extension.move()
    local npc_location = utils.get_npc_location('BLACKSMITH')
    if BatmobilePlugin then
        BatmobilePlugin.set_target(plugin_label, npc_location)
        BatmobilePlugin.move(plugin_label)
    else
        explorerlite:set_custom_target(npc_location)
        explorerlite:move_to_target()
    end
end
function extension.interact()
    local npc = extension.get_npc()
    if npc then interact_vendor(npc) end
end
function extension.execute()
    local local_player = get_local_player()
    if not local_player then return end
    tracker.last_task = task.name
    local items = local_player:get_inventory_items()
    for _, item in pairs(items) do
        if item and utils.is_salvage_or_sell(item,utils.item_enum['SALVAGE']) then
            loot_manager.salvage_specific_item(item)
        end
    end
    if tracker.salvage_sigils then
        local items = local_player:get_dungeon_key_items()
        for _, item in pairs(items) do
            local name = item:get_display_name()
            if not item:is_locked() and string.lower(name):match('sigil') then
            -- if item:is_junk() then
                loot_manager.salvage_specific_item(item)
            end
        end
    end
end
function extension.reset()
    local local_player = get_local_player()
    if not local_player then return end
    local new_position = vec3:new(-1680.57421875, -597.4794921875, 37.572265625)
    if task.reset_state == status_enum['MOVING'] then
        new_position = vec3:new(-1651.9208984375, -598.6142578125, 36.3134765625)
    end
    explorerlite:set_custom_target(new_position)
    explorerlite:move_to_target()
end
function extension.is_done()
    local local_player = get_local_player()
    if not local_player then return end
    local items = local_player:get_dungeon_key_items()
    if tracker.salvage_sigils then
        for _, item in pairs(items) do
            local name = item:get_display_name()
            if not item:is_locked() and string.lower(name):match('sigil') then
                return false
            end
        end
    end
    return tracker.salvage_count == 0
end
function extension.done()
    if BatmobilePlugin then
        BatmobilePlugin.clear_target(plugin_label)
    end
    tracker.salvage_done = true
end
function extension.failed()
    if BatmobilePlugin then
        BatmobilePlugin.clear_target(plugin_label)
    end
    tracker.salvage_failed = true
end
function extension.is_in_vendor_screen()
    return loot_manager:is_in_vendor_screen()
end

task.name = 'salvage'
task.extension = extension
task.status_enum = status_enum

task.shouldExecute = function ()
    if tracker.trigger_tasks == false then
        task.retry = 0
    end
    if utils.player_in_zone('Scos_Cerrigar') and
        tracker.trigger_tasks and
        not tracker.salvage_failed and
        not tracker.salvage_done and
        (tracker.sell_done or tracker.sell_failed) and
        (tracker.gamble_done or tracker.gamble_failed or tracker.gamble_paused)
    then
        if task.check_status(task.status_enum['FAILED']) then
            task.set_status(task.status_enum['IDLE'])
        end
        return true
    end
    return false
end

return task