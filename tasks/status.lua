local plugin_label = 'alfred_the_butler'
local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local gui = require 'gui'

local status_enum = {
    IDLE = 'Idle',
    WAITING = 'Waiting to be in Cerrigar',
    TIMEOUT = 'Alfred is in timeout'
}

local task = {
    name = 'Status',
    status = status_enum['IDLE']
}

function task.shouldExecute()
    if not utils.player_in_zone('Scos_Cerrigar') then
        return true
    elseif tracker.trigger_tasks and salvage_count == 0 and sell_count == o then
        -- add stash action when stash is available
        tracker.trigger_tasks = false
        return true
    elseif tracker.salvage_failed and tracker.sell_failed then
        tracker.trigger_tasks = false
        tracker.last_reset = get_time_since_inject()
        return true
    end
    
    return false
end

function task.Execute()
    local local_player = get_local_player()
    if not local_player then
        return
    end
    local item_count = tracker.salvage_count + tracker.sell_count
    local current_time = get_time_since_inject()
    -- wait {timeout} seconds since last reset to set to retrigger task
    if item_count >= tracker.inventory_limit and tracker.last_reset + settings.timeout < current_time then
        task.status = status_enum['WAITING']
        tracker.trigger_tasks = true
        tracker.salvage_failed = false
        tracker.sell_failed = false
    elseif tracker.last_reset + settings.timeout >= current_time then
        task.status = status_enum['TIMEOUT']
    else
        task.status = status_enum['IDLE']
    end
end

return task
