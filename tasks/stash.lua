local plugin_label = 'alfred_the_butler'

local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local explorerlite = require 'core.explorerlite'
local base_task = require 'tasks.base'

local task = base_task.new_task()
local status_enum = {
    IDLE = 'Idle',
    EXECUTE = 'Keeping item in stash',
    MOVING = 'Moving to stash',
    INTERACTING = 'Interacting with stash',
    RESETTING = 'Re-trying stash',
    FAILED = 'Failed to stash'
}

local extension = {}
function extension.get_npc()
    return utils.get_npc(utils.npc_enum['STASH'])
end
function extension.move()
    local npc_location = utils.get_npc_location('STASH')
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
        if item and not utils.is_salvage_or_sell(item,utils.item_enum['SELL']) and
            not utils.is_salvage_or_sell(item,utils.item_enum['SALVAGE'])
        then
            -- move 3 times because sometimes it get stuck
            loot_manager.move_item_to_stash(item)
            loot_manager.move_item_to_stash(item)
            loot_manager.move_item_to_stash(item)
            task.last_interaction = get_time_since_inject()
        end
    end
end
function extension.reset()
    local local_player = get_local_player()
    if not local_player then return end
    local new_position = vec3:new(-1680.7470703125, -592.1953125, 37.6484375)
    if task.reset_state == status_enum['MOVING'] then
        new_position = vec3:new(-1651.9208984375, -598.6142578125, 36.3134765625)
    end
    explorerlite:set_custom_target(new_position)
    explorerlite:move_to_target()
end
function extension.is_done()
    return not settings.item_use_stash or tracker.stash_count == 0
end
function extension.done()
    tracker.stash_done = true
end
function extension.failed()
    tracker.stash_failed = true
end

task.name = 'stash'
task.extension = extension
task.status_enum = status_enum

task.shouldExecute = function ()
    if tracker.trigger_tasks == false then
        task.retry = 0
    end
    if utils.player_in_zone('Scos_Cerrigar') and
        tracker.trigger_tasks and
        not tracker.stash_failed and
        not tracker.stash_done and
        (tracker.sell_done or tracker.sell_failed)
    then
        return true
    end
    return false
end

return task