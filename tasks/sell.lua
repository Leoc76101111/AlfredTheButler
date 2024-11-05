local plugin_label = 'alfred_the_butler'
local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local gui = require 'gui'

local status_enum = {
    IDLE = 'Idle',
    SELL = 'Selling',
    MOVING = 'Moving to vendor',
    INTERACTING = 'Interacting with vendor',
    RESETING = 'Re-trying sell',
    FAILED = 'Failed to sell'
}

local task = {
    name = 'Sell',
    status = status_enum['IDLE'],
    last_interaction = 0,
    retry = 0
}

function task.move()

end
function task.interact()

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

end


function task.shouldExecute()
    if tracker.trigger_tasks == false then
        task.retry = 0
    end
    if utils.player_in_zone('Scos_Cerrigar') and 
        tracker.trigger_tasks and 
        tracker.sell_count > 0 and
        not tracker.sell_failed
    then
        return true
    end
    return false
end

function task.Execute()
    local current_time = get_time_since_inject()
    local vendor = utils.get_vendor()
    local vendor_bugged = false

    if vendor then
        local vendor_pos = vendor:get_position()
        if vendor_pos:x() == 0 and vendor_pos:y() == 0 and vendor_pos:z() == 0 then
            vendor_bugged = true
        end
    end

    if not vendor or (not vendor_bugged and utils.distance_to(vendor) >= 2) then
        task.status = status_enum['MOVING']
        task.move()
    elseif vendor_bugged or (vendor and utils.distance_to(vendor) < 2) then
        task.status = status_enum['INTERACTING']
        task.last_interaction = current_time
        task.interact()
    elseif task.status == status_enum['INTERACTING'] and 
        task.last_interaction + 5 > current_time
    then
        task.last_interaction = current_time
        task.status = status_enum['SELL']
        task.sell()
    elseif task.status == status_enum['SELL'] and 
        task.last_interaction + 5 > current_time and
        tracker.sell_count > 0 and
        task.retry < 5
    then
        task.status = status_enum['RESETING']
        task.retry = task.retry + 1
        task.reset()
    else
        task.status  = status_enum['FAILED']
        tracker.sell_failed = true
    end 
end

return task
