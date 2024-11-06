local plugin_label = 'alfred_the_butler'

local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'

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

local function all_task_done()
    local status = {
        complete = false,
        failed = false
    }
    -- add stash action when stash is available
    if (tracker.sell_done or tracker.sell_failed) and
        (tracker.salvage_done or tracker.salvage_failed)
    then
        task.complete = true
    end

    if tracker.sell_failed or tracker.salvage_failed then
        task.failed = true
    end
    return status
end

function task.shouldExecute()
    local should_execute = false
    local status = all_task_done()
    if not utils.player_in_zone('Scos_Cerrigar') then
        should_execute = true
    elseif settings.allow_external and tracker.external_pause then
        should_execute = true
    elseif tracker.trigger_tasks and status.failed then
        tracker.last_reset = get_time_since_inject()
        should_execute = true
    elseif tracker.trigger_tasks and status.complete then
        should_execute = true
    end

    if status.complete then
        tracker.trigger_tasks = false
        tracker.all_task_done = true
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
        task.status = status_enum['PAUSED'] .. tostring(tracker.external_caller)
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
    elseif (settings.allow_external and tracker.external_trigger) or
        (item_count >= tracker.inventory_limit and tracker.last_reset + settings.timeout < current_time)
    then
        task.status = status_enum['WAITING']
        tracker.reset_all_task()
    elseif tracker.last_reset + settings.timeout >= current_time then
        task.status = status_enum['TIMEOUT']
    else
        task.status = status_enum['IDLE']
    end
end

return task