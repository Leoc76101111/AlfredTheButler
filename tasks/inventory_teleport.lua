local plugin_label = 'alfred_the_butler'

local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local explorerlite = require 'core.explorerlite'
local base_task = require 'tasks.base'

local task = base_task.new_task()
local status_enum = {
    IDLE = 'Idle',
    EXECUTE = 'Teleporting',
    WAITING = 'Waiting for teleport cooldown',
    FAILED = 'Failed to teleport'
}

-- Time to wait between teleport attempts
local TELEPORT_COOLDOWN = 2
local last_teleport_time = 0

local extension = {}

function extension.get_npc()
    return nil  -- No NPC needed for this task
end

function extension.move()
    -- No movement needed
end

function extension.interact()
    -- No interaction needed
end

function extension.execute()
    local current_time = get_time_since_inject()
    
    -- Check if we can teleport again
    if current_time - last_teleport_time < TELEPORT_COOLDOWN then
        return
    end
    
    -- Press 'T' key to teleport
    send_key('T')
    last_teleport_time = current_time
    
    -- Trigger other tasks
    tracker.trigger_tasks = true
    tracker.teleport = true
end

function extension.reset()
    -- No reset needed
end

function extension.is_done()
    return tracker.trigger_tasks
end

function extension.done()
    -- Reset flags when done
    tracker.inventory_full = false
end

function extension.failed()
    -- Handle failure
    tracker.teleport_failed = true
end

function extension.is_in_vendor_screen()
    return false
end

-- Check if inventory is full
local function is_inventory_full()
    local local_player = get_local_player()
    if not local_player then return false end
    
    local inventory = local_player:get_inventory_items()
    -- Assuming 33 is max inventory size
    return #inventory >= 33
end

task.name = 'inventory_teleport'
task.extension = extension
task.status_enum = status_enum
task.max_retries = 3

task.shouldExecute = function()
    if tracker.trigger_tasks == false then
        task.retry = 0
    end
    
    -- Execute if inventory is full and we're not already handling it
    if is_inventory_full() and not tracker.trigger_tasks then
        tracker.inventory_full = true
        return true
    end
    
    return false
end

-- Override the base Execute function
task.baseExecute = task.Execute
task.Execute = function()
    if not tracker.trigger_tasks then
        task.status = status_enum['EXECUTE']
        task.extension.execute()
    else
        task.baseExecute()
    end
end

return task 