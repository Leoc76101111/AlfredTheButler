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
    status = status_enum['IDLE'],
    teleport_trigger_time = nil,
}

local function all_task_done()
    local status = {
        complete = false,
        failed = false
    }
    -- add stash action when stash is available
    if (tracker.sell_done or tracker.sell_failed) and
        (tracker.stash_done or tracker.stash_failed) and
        (tracker.restock_done or tracker.restock_failed) and
        (tracker.salvage_done or tracker.salvage_failed) and
        (tracker.repair_done or tracker.repair_failed) and
        (not tracker.teleport or tracker.teleport_done or tracker.teleport_failed)
    then
        status.complete = true
    end

    -- dont check restock or repair
    if tracker.sell_failed or
        tracker.stash_failed or
        tracker.salvage_failed or
        tracker.teleport_failed
    then
        status.failed = true
    end
    return status
end

function task.shouldExecute()
    local should_execute = false
    local status = all_task_done()
    if not utils.player_in_zone('Scos_Cerrigar') and (not tracker.teleport or tracker.teleport_done) then
        should_execute = true
    elseif settings.allow_external and tracker.external_pause then
        should_execute = true
    elseif tracker.manual_trigger and not tracker.trigger_tasks then
        should_execute = true
    elseif settings.allow_external and tracker.external_trigger and not tracker.trigger_tasks then
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

    local restock_trigger = false
    local status = all_task_done()
    if status.complete then
        utils.reset_all_task()
        task.teleport_trigger_time = nil
        tracker.manual_trigger = false
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

    if tracker.restock_count > 0 then
        restock_trigger = true
    end


    if tracker.timeout then
        task.status = status_enum['TIMEOUT']
    elseif ((settings.allow_external and tracker.external_trigger) or
        tracker.inventory_full or tracker.manual_trigger) or restock_trigger
    then
        -- -- uncomment if you want to collect item data before salvage/sell
        -- if task.status ~= status_enum['WAITING'] then
        --     utils.export_inventory_info()
        -- end
        if #get_local_player():get_socketable_items() == 33 then
            tracker.stash_socketables = true
        end
        if #get_local_player():get_consumable_items() == 33 then
            tracker.stash_boss_materials = true
        end
        if #get_local_player():get_dungeon_key_items() == 33 then
            tracker.stash_compasses = true
        end
        if restock_trigger and
            settings.restock_type == utils.restock_enum['ACTIVE'] and
            task.teleport_trigger_time == nil
        then
            task.teleport_trigger_time = get_time_since_inject()
        elseif restock_trigger and
            settings.restock_type == utils.restock_enum['ACTIVE'] and
            task.teleport_trigger_time + settings.restock_teleport_delay < get_time_since_inject()
        then
            tracker.teleport = true
        end
        tracker.trigger_tasks = true
        task.status = status_enum['WAITING']
    else
        task.status = status_enum['IDLE']
        tracker.last_task = task.name
    end
end

return task