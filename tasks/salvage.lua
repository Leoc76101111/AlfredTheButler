local plugin_label = 'alfred_the_butler'
local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local gui = require 'gui'

local status_enum = {
    IDLE = 'Idle',
    SALVAGE = 'Salvaging',
    MOVING = 'Moving to blacksmith',
    INTERACTING = 'Interacting with blacksmith',
    RESETING = 'Re-trying salvage',
    FAILED = 'Failed to salvage'
}

local task = {
    name = 'Salvage',
    status = status_enum['IDLE'],
    last_interaction = 0
}

function task.move()

end
function task.interact()

end
function task.salvage()
    local local_player = get_local_player()
    if not local_player then return end
    local items = local_player:get_inventory_items()
    for _, item in pairs(items) do
        if item and utils.is_salvage_or_sell(item,utils.item_enum['SALVAGE']) then
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
        tracker.salvage_count > 0 and
        not tracker.salvage_failed and
        (tracker.sell_count == 0 or tracker.sell_failed)
    then
        return true
    end
    return false
end

function task.Execute()
    local current_time = get_time_since_inject()
    local blacksmith = utils.get_blacksmith()
    local blacksmith_bugged = false

    if blacksmith then
        local blacksmith_pos = blacksmith:get_position()
        if blacksmith_pos:x() == 0 and blacksmith_pos:y() == 0 and blacksmith_pos:z() == 0 then
            blacksmith_bugged = true
        end
    end

    if not blacksmith or (not blacksmith_bugged and utils.distance_to(blacksmith) >= 2) then
        task.status = status_enum['MOVING']
        task.move()
    elseif blacksmith_bugged or (blacksmith and utils.distance_to(blacksmith) < 2) then
        task.status = status_enum['INTERACTING']
        task.last_interaction = current_time
        task.interact()
    elseif task.status == status_enum['INTERACTING'] and 
        task.last_interaction + 5 > current_time
    then
        task.last_interaction = current_time
        task.status = status_enum['SALVAGE']
        task.salvage()
    elseif task.status == status_enum['SALVAGE'] and 
        task.last_interaction + 5 > current_time and
        tracker.salvage_count > 0 and
        task.retry < 5
    then
        task.status = status_enum['RESETING']
        task.retry = task.retry + 1
        task.reset()
    else
        task.status  = status_enum['FAILED']
        tracker.salvage_failed = true
    end 
end

return task
