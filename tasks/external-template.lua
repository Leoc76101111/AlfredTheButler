local plugin_label = 'NAME_OF_PLUGIN' -- change to your plugin name

local settings = require 'core.settings'
-- need use_alfred to enable
-- settings.use_alfred = true

local status_enum = {
    IDLE = 'idle',
    WAITING = 'waiting for alfred to complete',
}
local task = {
    name = 'alfred_running', -- change to your choice of task name
    status = status_enum['IDLE']
}

local function reset()
    PLUGIN_alfred_the_butler.pause(plugin_label)
    -- add more stuff here if you need to do something after alfred is done
    task.status = status_enum['IDLE']
end

function task.shouldExecute()
    if settings.use_alfred and PLUGIN_alfred_the_butler then
        local status = PLUGIN_alfred_the_butler.get_status()
        -- add additional conditions to trigger if required
        -- remove status.timeout if you must finish salvage/sell before continuing
        -- alfred will retry once timeout is over
        if status.enabled and
            status.inventory_full and
            (status.sell_count > 0 or status.salvage_count > 0)
        then
            return true
        elseif task.status == status_enum['WAITING'] then
            return true
        end
    end
    return false
end

function task.Execute()
    if task.status == status_enum['IDLE'] then
        PLUGIN_alfred_the_butler.resume()
        PLUGIN_alfred_the_butler.trigger_tasks(plugin_label,reset)
        -- PLUGIN_alfred_the_butler.trigger_tasks_with_teleport(plugin_label,reset)
        task.status = status_enum['WAITING']
    end
end

if settings.enabled and use_alfred and PLUGIN_alfred_the_butler then
    -- do an initial reset
    reset()
end

return task