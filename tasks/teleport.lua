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
    MOVING = 'Moving to portal',
    INTERACTING = 'Interacting with portal',
    RESETTING = 'Re-trying teleport',
    FAILED = 'Failed to teleport'
}
local debounce_time = nil
local debounce_timeout = 3
local function teleport_with_debounce()
    if debounce_time ~= nil and debounce_time + debounce_timeout > get_time_since_inject() then return end
    debounce_time = get_time_since_inject()
    teleport_to_waypoint(0x76D58)
end
local extension = {}
function extension.get_npc()
    return utils.get_npc(utils.npc_enum['PORTAL'])
end
function extension.move()
    local npc_location = utils.get_npc_location('PORTAL')
    explorerlite:set_custom_target(npc_location)
    explorerlite:move_to_target()
end
function extension.interact()
    local npc = extension.get_npc()
    if npc then interact_object(npc) end
end
function extension.execute()
    local npc = extension.get_npc()
    if npc then interact_object(npc) end
end

function extension.reset()
    local local_player = get_local_player()
    if not local_player then return end
    local new_position = vec3:new(-1661.931640625, -596.4111328125, 36.90625)
    if tracker.last_task == 'stash' or
        tracker.last_task == 'restock'
    then
        new_position = vec3:new(-1684.3427734375, -595.40625, 37.6484375)
    elseif tracker.last_task == 'salvage' then
        new_position = vec3:new(-1680.57421875, -597.4794921875, 37.572265625)
    elseif tracker.last_task ==  'sell' then
        new_position = vec3:new(-1673.71484375 , -586.8203125, 37.6484375)
    end
    explorerlite:set_custom_target(new_position)
    explorerlite:move_to_target()
end
function extension.is_done()
    return not utils.player_in_zone('Scos_Cerrigar')
end
function extension.done()
    tracker.teleport_done = true
end
function extension.failed()
    tracker.teleport_failed = true
end

task.name = 'teleport'
task.extension = extension
task.status_enum = status_enum
task.has_vendor_screen = true
task.max_retries = 5

task.shouldExecute = function ()
    if tracker.trigger_tasks == false then
        task.retry = 0
    end
    if tracker.teleport and
        not utils.player_in_zone('Scos_Cerrigar')
    then
        return true
    elseif utils.player_in_zone('Scos_Cerrigar') and
        tracker.trigger_tasks and
        not tracker.teleport_failed and
        not tracker.teleport_done and
        (tracker.sell_done or tracker.sell_failed) and
        (tracker.stash_done or tracker.stash_failed) and
        (tracker.restock_done or tracker.restock_failed) and
        (tracker.salvage_done or tracker.salvage_failed) and
        (tracker.repair_done or tracker.repair_failed)
    then
        return true
    end
    return false
end
task.baseExecute = task.Execute
task.Execute = function ()
    if tracker.teleport and
        not utils.player_in_zone('Scos_Cerrigar') and
        not (tracker.sell_done or tracker.sell_failed) and
        not (tracker.stash_done or tracker.stash_failed) and
        not (tracker.restock_done or tracker.restock_failed) and
        not (tracker.salvage_done or tracker.salvage_failed) and
        not (tracker.repair_done or tracker.repair_failed)
    then
        task.status = status_enum['EXECUTE']
        teleport_with_debounce()
    else
        task.baseExecute()
    end
end

return task