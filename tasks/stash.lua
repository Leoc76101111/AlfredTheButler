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

local debounce_time = nil
local debounce_timeout = 1

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
    if debounce_time ~= nil and debounce_time + debounce_timeout > get_time_since_inject() then return end
    debounce_time = get_time_since_inject()
    tracker.last_task = task.name
    local items = local_player:get_inventory_items()
    for _,item in pairs(items) do
        if item and not utils.is_salvage_or_sell(item,utils.item_enum['SELL']) and
            not utils.is_salvage_or_sell(item,utils.item_enum['SALVAGE'])
        then
            -- move 3 times because sometimes it get stuck
            loot_manager.move_item_to_stash(item)
            loot_manager.move_item_to_stash(item)
            loot_manager.move_item_to_stash(item)
        end
        task.last_interaction = get_time_since_inject()
        debounce_time = get_time_since_inject()
    end
    if settings.stash_extra_materials then
        local restock_items = utils.get_restock_items_from_tracker()
        if tracker.stash_boss_materials then
            local consumeable_items = local_player:get_consumable_items()
            for _,item in pairs(consumeable_items) do
                if restock_items[tostring(item:get_sno_id())] ~= nil then
                    local current = restock_items[tostring(item:get_sno_id())]
                    if current.count - item:get_stack_count() >= current.max or current.max < current.min then
                        -- move 3 times because sometimes it get stuck
                        loot_manager.move_item_to_stash(item)
                        loot_manager.move_item_to_stash(item)
                        loot_manager.move_item_to_stash(item)
                        restock_items[tostring(item:get_sno_id())].count = current.count - item:get_stack_count()
                    end
                end
                task.last_interaction = get_time_since_inject()
                debounce_time = get_time_since_inject()
            end
        end
        if tracker.stash_compasses then
            local key_items = local_player:get_dungeon_key_items()
            for _,item in pairs(key_items) do
                if restock_items[tostring(item:get_sno_id())] ~= nil then
                    local current = restock_items[tostring(item:get_sno_id())]
                    if current.count - 1 >= current.max or current.max < current.min then
                        -- move 3 times because sometimes it get stuck
                        loot_manager.move_item_to_stash(item)
                        loot_manager.move_item_to_stash(item)
                        loot_manager.move_item_to_stash(item)
                        restock_items[tostring(item:get_sno_id())].count = current.count - 1
                    end
                end
                task.last_interaction = get_time_since_inject()
                debounce_time = get_time_since_inject()
            end
        end
    end
    if settings.stash_all_socketables and tracker.stash_socketables then
        local socket_items = local_player:get_socketable_items()
        for _,item in pairs(socket_items) do
            -- move 3 times because sometimes it get stuck
            loot_manager.move_item_to_stash(item)
            loot_manager.move_item_to_stash(item)
            loot_manager.move_item_to_stash(item)
        end
        task.last_interaction = get_time_since_inject()
        debounce_time = get_time_since_inject()
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
    if task.status == status_enum['EXECUTE'] and
        #get_local_player():get_stash_items() == 300
    then
        return true
    end
    local material_stashed = true
    for _,item_data in pairs(tracker.restock_items) do
        if (item_data.item_type == 'consumables' and
            (item_data.count - 50 >= item_data.max or
            item_data.max < item_data.min and item_data.count > 0) and
            tracker.stash_boss_materials) or
            (item_data.item_type == 'key' and
            item_data.count - 1 >= item_data.max and
            tracker.stash_compasses)
        then
            material_stashed = false
        end
    end
    local socketable_stashed = true
    if tracker.stash_socketables then
        socketable_stashed = #get_local_player():get_socketable_items() == 0
    end
    return (not settings.item_use_stash or tracker.stash_count == 0) and
        (not settings.stash_all_socketables or socketable_stashed) and
        (not settings.stash_extra_materials or material_stashed)
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