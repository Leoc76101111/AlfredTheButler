local plugin_label = 'alfred_the_butler'

local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local explorerlite = require 'core.explorerlite'
local base_task = require 'tasks.base'

local task = base_task.new_task()
local status_enum = {
    IDLE = 'Idle',
    EXECUTE = 'Selling',
    MOVING = 'Moving to vendor',
    INTERACTING = 'Interacting with vendor',
    RESETTING = 'Re-trying sell',
    FAILED = 'Failed to sell'
}

local extend = {}
function extend.get_npc()
    return utils.get_vendor(false)
end
function extend.move()
    local npc_location = utils.get_vendor_location(false)
    explorerlite:set_custom_target(npc_location)
    explorerlite:move_to_target()
end
function extend.interact()
    local npc = extend.get_npc()
    if npc then interact_vendor(npc) end
end
function extend.execute()
    local local_player = get_local_player()
    if not local_player then return end
    local items = local_player:get_inventory_items()
    for _, item in pairs(items) do
        if item and utils.is_salvage_or_sell(item,utils.item_enum['SELL']) then
            loot_manager.sell_specific_item(item)
        end
    end
end
function extend.reset()
    local local_player = get_local_player()
    if not local_player then return end
    local new_position = vec3:new(-1673.71484375 , -586.8203125, 37.6484375)
    if task.reset_state == status_enum['MOVING'] then
        new_position = vec3:new(-1651.9208984375, -598.6142578125, 36.3134765625)
    end
    explorerlite:set_custom_target(new_position)
    explorerlite:move_to_target()
end
function extend.is_done()
    return tracker.sell_count == 0
end
function extend.done()
    tracker.sell_done = true
end
function extend.failed()
    tracker.sell_failed = true
end

task.name = 'sell'
task.extend = extend
task.status_enum = status_enum

task.shouldExecute = function ()
    if tracker.trigger_tasks == false then
        task.retry = 0
    end
    if utils.player_in_zone('Scos_Cerrigar') and
        tracker.trigger_tasks and
        tracker.sell_count > 0 and
        not tracker.sell_failed and
        not tracker.sell_done
    then
        return true
    end

    return false
end

return task