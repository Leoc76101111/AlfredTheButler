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

local debounce_time = get_time_since_inject()
local debounce_timeout = 1
local execute_restock = false
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
    if debounce_time ~= nil and debounce_time + debounce_timeout > get_time_since_inject() then return end
    debounce_time = get_time_since_inject()
    tracker.last_task = task.name
    local items = local_player:get_stash_items()
    for key,item_data in pairs(tracker.restock_items) do
        local need_counter = item_data.max - item_data.count
        local stash_counter = 0
        for _,item in pairs(items) do
            if item:get_sno_id() == item_data.sno_id then
                local item_count = item:get_stack_count()
                if item_count == 0 then
                    item_count = 1
                end
                stash_counter = stash_counter + item_count
                if need_counter > 0 and not is_inventory_max(item_data.item_type) then
                    loot_manager.move_item_from_stash(item)
                    update_last_interaction_time()
                    need_counter = need_counter - item_count
                end
            end
            debounce_time = get_time_since_inject()
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
    local restock_done = true
    if execute_restock then
        for _,item_data in pairs(tracker.restock_items) do
            if item_data.max > item_data.count and
                item_data.stash > 0 and
                not is_inventory_max(item_data.item_type)
            then
                restock_done = false
            end
        end
        if restock_done and #get_local_player():get_stash_items() > 0 then
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
    end
    return (tracker.restock_count == 0 and not execute_restock) or
        (execute_restock and restock_done)
end
function extension.done()
    if BatmobilePlugin then
        BatmobilePlugin.clear_target(plugin_label)
    end
    tracker.restock_done = true
    execute_restock = false
    stash_item_count = -1
    failed_interaction_count = -1
    last_interaction_item_count = -1
end
function extension.failed()
    if BatmobilePlugin then
        BatmobilePlugin.clear_target(plugin_label)
    end
    tracker.restock_failed = true
    execute_restock = false
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
        (tracker.gamble_done or tracker.gamble_failed or tracker.gamble_paused) and
        (tracker.salvage_done or tracker.salvage_failed) and
        (tracker.stash_done or tracker.stash_failed)
    then
        if tracker.restock_count > 0 then
            execute_restock = true
        end
        if task.check_status(task.status_enum['FAILED']) then
            task.set_status(task.status_enum['IDLE'])
        end
        return true
    end
    return false
end

return task