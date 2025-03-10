local plugin_label = 'alfred_the_butler'

local tracker = {
    name                      = plugin_label,
    timeout                   = false,
    inventory_full            = false,
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
    manual_trigger            = false,
    restock_items             = {},
    restock_failed            = false,
    restock_done              = false,
    restock_count             = 0,
    last_task                 = 'status',
    previous                  = {},
    stash_socketables         = false,
    stash_compasses           = false,
    stash_boss_materials      = false,
    cached_inventory          = {},
    stocktake                 = false,
    stocktake_done            = false,
    stocktake_failed          = false,
}

return tracker