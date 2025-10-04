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
local stash_item_count = -1
local failed_interaction_count = -1
local last_interaction_item_count = -1

local function update_last_interaction_time()
    local local_player = get_local_player()
    local item_count = #local_player:get_inventory_items() +
        #local_player:get_consumable_items() +
        #local_player:get_dungeon_key_items() +
        #local_player:get_socketable_items()

    if item_count == last_interaction_item_count then
        failed_interaction_count = failed_interaction_count + 1
    else
        failed_interaction_count = -1
    end
    if failed_interaction_count < 10 then
        task.last_interaction = get_time_since_inject()
    end
    last_interaction_item_count = item_count
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
    if debounce_time ~= nil and debounce_time + debounce_timeout > get_time_since_inject() then return end
    debounce_time = get_time_since_inject()
    tracker.last_task = task.name
    local items = local_player:get_inventory_items()
    for _,item in pairs(items) do
        if item and not utils.is_salvage_or_sell(item,utils.item_enum['SELL']) and
            not utils.is_salvage_or_sell(item,utils.item_enum['SALVAGE']) and
            not (settings.skip_cache and utils.get_item_type(item) == 'cache')
        then
            loot_manager.move_item_to_stash(item)
            update_last_interaction_time()
        end
        debounce_time = get_time_since_inject()
    end
    local restock_items = utils.get_restock_items_from_tracker()
    if tracker.stash_boss_materials then
        local consumeable_items = local_player:get_consumable_items()
        for _,item in pairs(consumeable_items) do
            if restock_items[item:get_sno_id()] ~= nil then
                local current = restock_items[item:get_sno_id()]
                if current.count - item:get_stack_count() >= current.max or current.max < current.min then
                    loot_manager.move_item_to_stash(item)
                    update_last_interaction_time()
                end
            end
            debounce_time = get_time_since_inject()
        end
    end
    if tracker.stash_keys then
        local key_items = local_player:get_dungeon_key_items()
        for _,item in pairs(key_items) do
            if restock_items[item:get_sno_id()] ~= nil then
                local current = restock_items[item:get_sno_id()]
                if current.count - item:get_stack_count() >= current.max or current.max < current.min then
                    loot_manager.move_item_to_stash(item)
                    update_last_interaction_time()
                end
            end
            debounce_time = get_time_since_inject()
        end
    end
    if tracker.stash_socketables then
        local socket_items = local_player:get_socketable_items()
        for _,item in pairs(socket_items) do
            loot_manager.move_item_to_stash(item)
            update_last_interaction_time()
        end
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
    if task.check_status(status_enum['EXECUTE']) and
        #get_local_player():get_stash_items() == 300
    then
        return true
    end
    local material_stashed = true
    for _,item_data in pairs(tracker.restock_items) do
        if (item_data.item_type == 'consumables' and
            (item_data.count - 99 >= item_data.max or
            item_data.max < item_data.min and item_data.count > 0) and
            tracker.stash_boss_materials) or
            (item_data.item_type == 'key' and
            item_data.count - 99 >= item_data.max and
            tracker.stash_keys)
        then
            material_stashed = false
        end
    end
    if material_stashed and #get_local_player():get_stash_items() > 0 then
        local restock_items = utils.get_restock_items_from_tracker()
        local stash_items = get_local_player():get_stash_items()
        for key,_ in pairs(restock_items) do
            restock_items[key].stash = 0
        end
        for _,item in pairs(stash_items) do
            if restock_items[item:get_sno_id()] ~= nil then
                local item_count = item:get_stack_count()
                if item_count == 0 then
                    item_count = 1
                end
                restock_items[item:get_sno_id()].stash = restock_items[item:get_sno_id()].stash + item_count
            end
        end
    end
    local socketable_stashed = true
    if tracker.stash_socketables then
        socketable_stashed = #get_local_player():get_socketable_items() == 0
    end
    return (tracker.stash_count == 0) and
        (not tracker.stash_socketables or socketable_stashed) and
        (not tracker.stash_boss_materials or material_stashed) and
        (not tracker.stash_keys or material_stashed)
end
function extension.done()
    tracker.stash_done = true
    tracker.gamble_paused = false
    stash_item_count = -1
    failed_interaction_count = -1
    last_interaction_item_count = -1
end
function extension.failed()
    tracker.stash_failed = true
    tracker.gamble_paused = false
    stash_item_count = -1
    failed_interaction_count = -1
    last_interaction_item_count = -1
end
function extension.is_in_vendor_screen()
    local is_in_vendor_screen = false
    local stash_count = #get_local_player():get_stash_items()
    if stash_count > 0 and stash_item_count == stash_count then
        is_in_vendor_screen = true
    end
    stash_item_count = stash_count
    return is_in_vendor_screen
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
        (tracker.sell_done or tracker.sell_failed) and
        (tracker.gamble_done or tracker.gamble_failed or tracker.gamble_paused) and
        (tracker.salvage_done or tracker.salvage_failed)
    then
        if task.check_status(task.status_enum['FAILED']) then
            task.set_status(task.status_enum['IDLE'])
        end
        return true
    end
    return false
end

return task