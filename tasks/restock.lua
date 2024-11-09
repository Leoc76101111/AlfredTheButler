local plugin_label = 'alfred_the_butler'

local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local explorerlite = require 'core.explorerlite'
local base_task = require 'tasks.base'

local task = base_task.new_task()
local status_enum = {
    IDLE = 'Idle',
    EXECUTE = 'Taking item from stash',
    MOVING = 'Moving to stash',
    INTERACTING = 'Interacting with stash',
    RESETTING = 'Re-trying restock',
    FAILED = 'Failed to restock'
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
    local items = local_player:get_stash_items()

    for key,item_data in pairs(tracker.restock_items) do
        tracker.restock_items[key]['stash'] = 0
        for _, item in pairs(items) do
            if item:get_sno_id() == item_data.sno_id then
                if item_data.count < item_data.max then
                    loot_manager.move_item_from_stash(item)
                else
                    tracker.item_datas[key]['stash'] = tracker.item_datas[key]['stash'] + 1
                end
            end
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
    for _,item_data in pairs(tracker.restock_items) do
        if item_data.stash > 0 and item_data.count < item_data.max then
            return false
        end
    end
    return true
end
function extension.done()
    tracker.restock_done = true
end
function extension.failed()
    tracker.restock_failed = true
end

task.name = 'restock'
task.extension = extension
task.status_enum = status_enum
task.max_retries = 0

task.shouldExecute = function ()
    if tracker.trigger_tasks == false then
        task.retry = 0
    end
    if utils.player_in_zone('Scos_Cerrigar') and
        tracker.trigger_tasks and
        not tracker.restock_failed and
        not tracker.restock_done and
        (tracker.sell_done or tracker.sell_failed) and
        (tracker.stash_done or tracker.stash_failed)
    then
        return true
    end
    return false
end

return task