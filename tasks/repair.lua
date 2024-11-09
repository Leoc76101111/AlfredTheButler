local plugin_label = 'alfred_the_butler'

local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local explorerlite = require 'core.explorerlite'
local base_task = require 'tasks.base'

local task = base_task.new_task()
local status_enum = {
    IDLE = 'Idle',
    EXECUTE = 'Repairing',
    MOVING = 'Moving to blacksmith',
    INTERACTING = 'Interacting with blacksmith',
    RESETTING = 'Re-trying salvage',
    FAILED = 'Failed to salvage'
}

local extension = {}
function extension.get_npc()
    return utils.get_blacksmith()
end
function extension.move()
    local npc_location = utils.get_blacksmith_location()
    explorerlite:set_custom_target(npc_location)
    explorerlite:move_to_target()
end
function extension.interact()
    local npc = extension.get_npc()
    if npc then interact_vendor(npc) end
end
function extension.execute()
    local local_player = get_local_player()
    if not local_player then return end
    local npc = extension.get_npc()
    loot_manager.interact_with_vendor_and_repair_all(npc)
end
function extension.reset()
    local local_player = get_local_player()
    if not local_player then return end
    local new_position = vec3:new(-1680.57421875, -597.4794921875, 37.572265625)
    if task.reset_state == status_enum['MOVING'] then
        new_position = vec3:new(-1651.9208984375, -598.6142578125, 36.3134765625)
    end
    explorerlite:set_custom_target(new_position)
    explorerlite:move_to_target()
end
function extension.is_done()
    return auto_play.get_objective() ~= objective.repair
end
function extension.done()
    tracker.repair_done = true
end
function extension.failed()
    tracker.repair_failed = true
end

task.name = 'repair'
task.extension = extension
task.status_enum = status_enum
task.shouldExecute = function ()
    if tracker.trigger_tasks == false then
        task.retry = 0
    end
    if utils.player_in_zone('Scos_Cerrigar') and
        tracker.trigger_tasks and
        not tracker.repair_failed and
        not tracker.repair_done and
        (tracker.sell_done or tracker.sell_failed) and
        (tracker.salvage_done or tracker.salvage_failed)
    then
        return true
    end
    return false
end

return task