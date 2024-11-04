local plugin_label = "alfred_the_butler"
local utils = require "core.utils"
local settings = require "core.settings"
local tracker = require "core.tracker"
local gui = require "gui"


local status_task = {
    name = "Status",
    status = "Idle"
}

function status_task.shouldExecute()
    if tracker.trigger_tasks and salvage_count == 0 and sell_count == o then
        -- add stash action when stash is available
        tracker.trigger_tasks = false
    end
    if not utils.player_in_zone("Scos_Cerrigar") or not tracker.trigger_tasks then
        return true
    end
    return false
end

function status_task.Execute()
    local local_player = get_local_player()
    if not local_player then
        return
    end
    local item_count = tracker.salvage_count + tracker.sell_count
    if item_count >= tracker.inventory_limit then
        status_task.status = "Waiting to be in Cerrigar"
        status_task.trigger_tasks = true
    else
        status_task.status = "Idle"
    end
end

return status_task
