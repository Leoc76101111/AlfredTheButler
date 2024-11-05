local plugin_label = 'alfred_the_butler'
local tracker = {
    name = plugin_label,
    inventory_full = false,
    inventory_limit = 0,
    inventory_hard_limit = 30,
    inventory_count = 0,
    salvage_count = 0,
    sell_count = 0,
    stash_count = 0,
    trigger_tasks = false,
    last_reset = 0,
    salvage_failed = false,
    salvage_done = false,
    sell_failed = false,
    sell_done = false,
    external_caller = nil,
    external_trigger = true,
    external_trigger_callback = nil,
    external_pause = false,
    external_trigger_teleport = false,
    external_trigger_teleport_callback = nil
}

local external_tracker = {
    get_status = function ()
        return {
            inventory_full = tracker.inventory_full,
            inventory_limit = tracker.inventory_limit,
            inventor_count = tracker.inventor_count,
            salvage_count = tracker.salvage_count,
            sell_count = tracker.sell_count,
            stash_count = tracker.stash_count,
            trigger_tasks = tracker.trigger_tasks,
            last_reset = tracker.last_reset,
            salvage_failed = tracker.salvage_failed,
            salvage_done = tracker.salvage_done,
            sell_failed = tracker.sell_failed,
            sell_done = tracker.sell_done,
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
        tracker.external_trigger = true
        if callback then
            tracker.external_trigger_callback = callback
        end
    end,
    trigger_tasks_with_teleport = function (caller,callback) 
        -- not implemented
        tracker.external_caller = caller
        tracker.external_trigger = true
        tracker.external_trigger_teleport = true
        if callback then
            tracker.external_trigger_teleport_callback = callback
        end
    end,
}
tracker.external_tracker = external_tracker

return tracker