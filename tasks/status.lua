local plugin_label = 'alfred_the_butler'
local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local gui = require 'gui'

local status_enum = {
    IDLE = 'Idle',
    WAITING = 'Waiting to be in Cerrigar',
    TIMEOUT = 'Alfred is in timeout',
    PAUSED = 'Paused by '
}

local task = {
    name = 'Status',
    status = status_enum['IDLE']
}

function task.shouldExecute()
    local should_execute = false
    local task_done = false
    if not utils.player_in_zone('Scos_Cerrigar') then
        should_execute = true
    elseif settings.allow_external and tracker.external_pause then
        should_execute = true
    elseif tracker.trigger_tasks and tracker.salvage_done and tracker.sell_done then
        -- add stash action when stash is available
        task_done = true
        should_execute = true
    elseif tracker.salvage_failed and tracker.sell_failed then
        tracker.last_reset = get_time_since_inject()
        task_done = true
        should_execute = true
    end
    
    if task_done then
        tracker.trigger_tasks = false
        if settings.allow_external and tracker.external_trigger then
            tracker.external_trigger = false
            tracker.external_caller = nil
            if tracker.external_trigger_callback then
                pcall(tracker.external_trigger_callback)
                tracker.external_trigger_callback = nil
            end
            -- if not utils.player_in_zone('Scos_Cerrigar') then
            --     tracker.external_trigger_teleport = false
            --     if tracker.external_trigger_teleport_callback then
            --         pcall(tracker.external_trigger_teleport_callback)
            --         tracker.external_trigger_teleport_callback = nil
            --     end
            -- end
        end
    end
    return should_execute
end

function task.Execute()
    local local_player = get_local_player()
    if not local_player then
        return
    end
    local item_count = tracker.salvage_count + tracker.sell_count
    local current_time = get_time_since_inject()
    if settings.allow_external and tracker.external_pause then
        task.status = status_enum['PAUSED'] .. tracker.external_caller
    -- elseif settings.allow_external and 
    --     tracker.external_trigger_teleport and 
    --     not utils.player_in_zone('Scos_Cerrigar') and
    --     (not tracker.salvage_done or not tracker.sell_done) 
    -- then
    --     -- teleport
    -- elseif settings.allow_external and
    --     tracker.external_trigger_teleport and
    --     not utils.player_in_zone('Scos_Cerrigar') and
    --     tracker.salvage_done and
    --     tracker.sell_done 
    -- then
    --     -- teleport back
    else if settings.allow_external and tracker.external_trigger then
        tracker.trigger_tasks = true
        tracker.salvage_done = false
        tracker.salvage_failed = false
        tracker.sell_done = false
        tracker.sell_failed = false
    elseif item_count >= tracker.inventory_limit and tracker.last_reset + settings.timeout < current_time then
        -- wait {timeout} seconds since last reset to set to retrigger task
        task.status = status_enum['WAITING']
        tracker.trigger_tasks = true
        tracker.salvage_done = false
        tracker.salvage_failed = false
        tracker.sell_done = false
        tracker.sell_failed = false
    elseif tracker.last_reset + settings.timeout >= current_time then
        task.status = status_enum['TIMEOUT']
    else
        task.status = status_enum['IDLE']
    end
end

return task
