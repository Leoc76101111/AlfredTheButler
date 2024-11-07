local plugin_label = 'alfred_the_butler'

local tracker = {
    name                               = plugin_label,
    inventory_full                     = false,
    inventory_limit                    = 0,
    inventory_hard_limit               = 33,
    inventory_count                    = 0,
    salvage_count                      = 0,
    sell_count                         = 0,
    stash_count                        = 0,
    trigger_tasks                      = false,
    last_reset                         = 0,
    salvage_failed                     = false,
    salvage_done                       = false,
    sell_failed                        = false,
    sell_done                          = false,
    all_task_done                      = false,
    external_caller                    = nil,
    external_trigger                   = false,
    external_trigger_callback          = nil,
    external_pause                     = false,
    external_trigger_teleport          = false,
    external_trigger_teleport_callback = nil,
    manual_trigger                     = false
}

return tracker