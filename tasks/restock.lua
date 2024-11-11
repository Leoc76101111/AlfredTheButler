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

local function is_inventory_max(type)
    if type == 'key' then
        return #get_local_player():get_dungeon_key_items() == 33
    elseif type == 'consumables' then
        return get_local_player():get_consumable_count() == 33
    end
end

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
    local items = local_player:get_stash_items()

    for key,item_data in pairs(tracker.restock_items) do
        local need_counter = item_data.max - item_data.count
        local stash_counter = 0
        for _, item in pairs(items) do
            if item:get_sno_id() == item_data.sno_id then
                local item_count = item:get_stack_count()
                if item_count == 0 then
                    item_count = 1
                end
                if need_counter > 0 and not is_inventory_max(item_data.item_type) then
                    -- move 3 times because sometimes it get stuck
                    loot_manager.move_item_from_stash(item)
                    loot_manager.move_item_from_stash(item)
                    loot_manager.move_item_from_stash(item)
                    need_counter = need_counter - item_count
                    task.last_interaction = get_time_since_inject()
                else
                    stash_counter = stash_counter + item_count
                end
            end
        end
        tracker.restock_items[key]['stash'] = stash_counter
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
    local is_done = true
    for _,item_data in pairs(tracker.restock_items) do
        if not is_inventory_max(item_data.item_type) and
            item_data.stash > 0 and item_data.count < item_data.max
        then
            is_done = false
        end
    end
    return is_done
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