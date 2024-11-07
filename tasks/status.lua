local plugin_label = 'alfred_the_butler'

local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'

local status_enum = {
    IDLE = 'Idle',
    WAITING = 'Waiting to be in Cerrigar',
    TIMEOUT = 'Alfred is in timeout'
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
        status.complete = true
    end

    if tracker.sell_failed or tracker.salvage_failed then
        status.failed = true
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
    elseif tracker.manual_trigger then
        should_execute = true
    elseif not tracker.trigger_tasks then
        should_execute = true
    elseif tracker.trigger_tasks and status.failed then
        tracker.last_reset = get_time_since_inject()
        should_execute = true
    elseif tracker.trigger_tasks and status.complete then
        should_execute = true
    end

    return should_execute
end

function task.Execute()
    local local_player = get_local_player()
    if not local_player then
        return
    end
    local current_time = get_time_since_inject()
    local status = all_task_done()
    if status.complete then
        utils.reset_all_task()
        tracker.trigger_tasks = false
        tracker.all_task_done = true
        if settings.allow_external and tracker.external_trigger then
            tracker.external_trigger = false
            tracker.external_caller = nil
            if tracker.external_trigger_callback then
                pcall(tracker.external_trigger_callback)
                tracker.external_trigger_callback = nil
            end
        end
    end

    if tracker.last_reset + settings.timeout < current_time and
        ((settings.allow_external and tracker.external_trigger) or
        tracker.inventory_full or tracker.manual_trigger)
    then
        tracker.manual_trigger = false
        tracker.trigger_tasks = true
        task.status = status_enum['WAITING']
        -- -- uncomment if you want to collect item data before salvage/sell
        -- utils.export_inventory_info()
    elseif tracker.last_reset + settings.timeout >= current_time then
        task.status = status_enum['TIMEOUT']
    else
        task.status = status_enum['IDLE']
    end
end

return task