local plugin_label = 'NAME_OF_PLUGIN' -- change to your plugin name

local settings = require 'core.settings'
-- need settings.use_alfred to enable

local status_enum = {
    IDLE = 'idle',
    WAITING = 'waiting for alfred to complete',
}
local task = {
    name = 'alfred_running', -- change to your choice of task name
    status = status_enum['IDLE']
}

local function reset()
    task.status = status_enum['IDLE']
    PLUGIN_alfred_the_butler.pause(plugin_label)
end

function task.shouldExecute()
    if settings.use_alfred and PLUGIN_alfred_the_butler then
        local status = PLUGIN_alfred_the_butler.get_status()
        -- add additional conditions to trigger if required
        if status.inventory_full and (status.sell_count > 0 or status.salvage_count > 0) then
            return true
        elseif task.status == status_enum['WAITING'] then
            return true
        end
    end
    return false
end

function task.Execute()
    if task.status == status_enum['IDLE'] then
        PLUGIN_alfred_the_butler.trigger_tasks(plugin_label,reset)
        -- PLUGIN_alfred_the_butler.trigger_tasks_with_teleport(plugin_label,reset)
        PLUGIN_alfred_the_butler.resume()
        task.status = status_enum['WAITING']
    end
end

if settings.use_alfred and PLUGIN_alfred_the_butler then
    -- do an initial reset
    reset()
end

return task