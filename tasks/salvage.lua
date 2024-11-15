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
    explorerlite:set_custom_target(npc_location)
    explorerlite:move_to_target()
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
    return tracker.salvage_count == 0
end
function extension.done()
    tracker.salvage_done = true
end
function extension.failed()
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
        (tracker.stash_done or tracker.stash_failed) and
        (tracker.restock_done or tracker.restock_failed)
    then
        return true
    end
    return false
end

return task