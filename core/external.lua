local plugin_label = 'alfred_the_butler'

local settings = require 'core.settings'
local tracker = require 'core.tracker'

local external = {
    get_status = function ()
        return {
            name            = plugin_label,
            enabled         = settings.enabled,
            inventory_full  = tracker.inventory_full,
            inventory_limit = tracker.inventory_limit,
            inventor_count  = tracker.inventor_count,
            salvage_count   = tracker.salvage_count,
            sell_count      = tracker.sell_count,
            stash_count     = tracker.stash_count,
            trigger_tasks   = tracker.trigger_tasks,
            last_reset      = tracker.last_reset,
            salvage_failed  = tracker.salvage_failed,
            salvage_done    = tracker.salvage_done,
            sell_failed     = tracker.sell_failed,
            sell_done       = tracker.sell_done,
            all_task_done   = tracker.all_task_done,
        }
    end,
    pause = function (caller)
        tracker.external_caller = caller
        tracker.external_pause = true
    end,
    resume = function ()
        tracker.external_caller = nil
        tracker.external_pause = false
    end,
    trigger_tasks = function (caller, callback)
        tracker.external_caller = caller
        tracker.external_trigger = true
        if callback then
            tracker.external_trigger_callback = callback
        end
    end,
    trigger_tasks_with_teleport = function (caller,callback)
        tracker.external_caller = caller
        tracker.external_trigger = true
        tracker.teleport = true
        if callback then
            tracker.external_trigger_callback = callback
        end
    end,
}
return external