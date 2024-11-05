local plugin_label = 'alfred_the_butler'
local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local gui = require 'gui'
local explorerlite = require 'core.explorerlite'

local status_enum = {
    IDLE = 'Idle',
    SELL = 'Selling',
    MOVING = 'Moving to vendor',
    INTERACTING = 'Interacting with vendor',
    RESETTING = 'Re-trying sell',
    FAILED = 'Failed to sell'
}

local task = {
    name = 'Sell',
    status = status_enum['IDLE'],
    last_interaction = 0,
    retry = 0,
    interaction_timeout = 3,
    max_retries = 2,
    last_location = nil,
    last_stuck_location = nil,
    reset_state = nil
}

function task.move()
    local vendor_location = utils.get_vendor_location(false)
    explorerlite:set_custom_target(vendor_location)
    explorerlite:move_to_target()
end
function task.interact()
    local vendor = utils.get_vendor(false)
    if vendor then interact_vendor(vendor) end
end

function task.sell()
    local local_player = get_local_player()
    if not local_player then return end
    local items = local_player:get_inventory_items()
    for _, item in pairs(items) do
        if item and utils.is_salvage_or_sell(item,utils.item_enum['SELL']) then
            loot_manager.salvage_specific_item(inventory_item)
        end
    end
end
function task.reset()
    local local_player = get_local_player()
    if not local_player then return end
    local player_position = get_player_position()
    local new_position = vec3:new(-1673.71484375 , -586.8203125, 37.6484375)
    if task.reset_state == status_enum['MOVING'] then
        new_position = vec3:new(-1651.9208984375, -598.6142578125, 36.3134765625)
    end
    explorerlite:set_custom_target(new_position)
    explorerlite:move_to_target()
end

function task.shouldExecute()
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

function task.Execute()
    local current_time = get_time_since_inject()
    local vendor = utils.get_vendor(false)
    local vendor_bugged = false
    local player_stuck = false
    local player_position = get_player_position()

    if vendor then
        local vendor_pos = vendor:get_position()
        if vendor_pos:x() == 0 and vendor_pos:y() == 0 and vendor_pos:z() == 0 then
            vendor_bugged = true
        end
    end

    if task.last_location ~= nil and 
        task.status == status_enum['MOVING'] and
        utils.is_same_position(task.last_location,player_position)
    then
        player_stuck = true
    end
    task.last_location = player_position

    if task.status == status_enum['MOVING'] and 
        player_stuck and 
        task.last_stuck_location == nil and 
        task.last_interaction + task.interaction_timeout < current_time
    then
        task.status = status_enum['RESETTING']
        task.last_interaction = current_time
        task.retry = task.retry + 1
        task.reset_state = status_enum['MOVING']
        task.reset()
        task.last_stuck_location = player_position
    elseif task.status == status_enum['RESETTING'] and
        task.last_interaction + task.interaction_timeout > current_time
    then
        task.status = status_enum['RESETTING']
        task.reset()
    elseif (not vendor or 
        (not vendor_bugged and utils.distance_to(vendor) >= 2)) and
        task.last_interaction + task.interaction_timeout < current_time
    then
        task.status = status_enum['MOVING']
        task.last_interaction = current_time
        task.last_stuck_location = nil
        task.move()
    elseif task.status == status_enum['MOVING'] and 
        (not vendor or (not vendor_bugged and utils.distance_to(vendor) >= 2)) and
        task.last_interaction + task.interaction_timeout > current_time
    then
        task.status = status_enum['MOVING']
        task.move()
    elseif (vendor_bugged or (vendor and utils.distance_to(vendor) < 2)) and
        task.status == status_enum['MOVING']
    then
        task.status = status_enum['INTERACTING']
        task.last_interaction = current_time
        task.interact()
    elseif task.status == status_enum['INTERACTING'] and 
        task.last_interaction + task.interaction_timeout > current_time
    then
        task.status = status_enum['INTERACTING']
        task.interact()
    elseif task.status == status_enum['INTERACTING'] and 
        task.last_interaction + task.interaction_timeout < current_time
    then
        task.status = status_enum['SELL']
        task.last_interaction = current_time
        task.sell()
    elseif task.status == status_enum['SELL'] and 
        task.last_interaction + task.interaction_timeout > current_time and
        tracker.sell_count > 0
    then 
        task.status = status_enum['SELL']
        task.sell()
    elseif task.status == status_enum['SELL'] and 
        task.last_interaction + task.interaction_timeout < current_time and
        tracker.sell_count > 0 and 
        task.retry < task.max_retries
    then
        task.status = status_enum['RESETTING']
        task.last_interaction = current_time
        task.retry = task.retry + 1
        task.reset_state = status_enum['SELL']
        task.reset()
    elseif tracker.sell_count == 0 then
        task.status = status_enum['IDLE']
        task.retry = 0
        task.last_interaction = 0
        tracker.sell_done = true
    else
        task.status  = status_enum['FAILED']
        task.retry = 0
        tracker.sell_failed = true
    end 
end

return task
