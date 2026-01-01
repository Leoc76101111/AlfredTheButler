local plugin_label = 'alfred_the_butler'

local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'

local status_enum = {
    IDLE = 'Idle',
    WAITING = 'Waiting to be in Cerrigar',
    FAILED = 'Alfred has failed you (successfully failed XD), please copy logs to discord channel',
    STUCK = 'Alfred is stuck, you told him to not stash caches, and inventory is full of caches!'
}

local task = {
    name = 'Status',
    status = status_enum['IDLE'],
    batmobile_resume = nil
}

local function all_task_done()
    local status = {
        complete = false,
        failed = false
    }

    if (tracker.sell_done or tracker.sell_failed) and
        (tracker.stash_done or tracker.stash_failed) and
        (tracker.restock_done or tracker.restock_failed) and
        (tracker.stocktake_done or tracker.stocktake_failed) and
        (tracker.salvage_done or tracker.salvage_failed) and
        (tracker.repair_done or tracker.repair_failed) and
        (tracker.gamble_done or tracker.gamble_failed) and
        (not tracker.teleport or tracker.teleport_done or tracker.teleport_failed)
    then
        status.complete = true
    end

    -- dont check restock, stocktake or repair
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
    elseif tracker.trigger_tasks and status.complete and status.failed then
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

    local status = all_task_done()
    if status.complete then
        if settings.skip_cache and tracker.inventory_full then
            task.status = status_enum['STUCK']
            return
        end
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
        if task.batmobile_resume ~= nil then
            task.batmobile_resume = nil
            BatmobilePlugin.resume(plugin_label)
        end
    end

    if status.failed then
        if settings.failed_action == utils.failed_action_enum['LOG'] then
            if task.status ~= status_enum['FAILED'] then
                utils.dump_tracker_info(tracker)
            end
            task.status = status_enum['FAILED']
        else
            utils.reset_all_task()
            tracker.trigger_tasks = true
        end
        return
    end

    if (settings.allow_external and tracker.external_trigger) or
        tracker.need_trigger or tracker.manual_trigger
    then
        if settings.get_export_keybind_state() and task.status ~= status_enum['WAITING'] and task.status ~= status_enum['FAILED'] then
            utils.export_inventory_info()
        end
        if settings.stash_socketables == utils.stash_extra_enum['ALWAYS'] or
            tracker.need_stash_socketables
        then
            tracker.stash_socketables = true
        else
            tracker.stash_socketables = false
        end
        if settings.stash_consumables == utils.stash_extra_enum['ALWAYS'] or
            tracker.need_stash_consumables
        then
            tracker.stash_boss_materials = true
        else
            tracker.stash_boss_materials = false
        end
        if settings.stash_keys == utils.stash_extra_enum['ALWAYS'] or
            tracker.need_stash_keys
        then
            tracker.stash_keys = true
            tracker.stash_sigils = settings.stash_sigils
        else
            tracker.stash_keys = false
            tracker.stash_sigils = false
        end
        if tracker.need_gamble then
            tracker.gambling = true
        end
        if settings.salvage_sigils then
            tracker.salvage_sigils = true
        else
            tracker.salvage_sigils = false
        end
        if task.batmobile_resume == nil and BatmobilePlugin then
            task.batmobile_resume = not BatmobilePlugin.is_paused()
            BatmobilePlugin.pause(plugin_label)
        end
        tracker.trigger_tasks = true
        task.status = status_enum['WAITING']
    else
        task.status = status_enum['IDLE']
        tracker.last_task = task.name
    end
end

return task