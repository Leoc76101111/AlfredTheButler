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
    sell_done = false
}

return tracker