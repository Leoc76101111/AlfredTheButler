local plugin_label = 'alfred_the_butler'

local tracker = {
    name                      = plugin_label,
    timeout                   = false,
    inventory_full            = false,
    inventory_limit           = 0,
    inventory_hard_limit      = 33,
    inventory_count           = 0,
    salvage_count             = 0,
    sell_count                = 0,
    stash_count               = 0,
    trigger_tasks             = false,
    last_reset                = 0,
    salvage_failed            = false,
    salvage_done              = false,
    sell_failed               = false,
    sell_done                 = false,
    repair_failed             = false,
    repair_done               = false,
    stash_failed              = false,
    stash_done                = false,
    all_task_done             = false,
    external_caller           = nil,
    external_trigger          = false,
    external_trigger_callback = nil,
    external_pause            = false,
    teleport                  = false,
    teleport_done             = false,
    teleport_failed           = false,
    manual_trigger            = false
}

return tracker