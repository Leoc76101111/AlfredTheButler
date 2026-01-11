local plugin_label = 'alfred_the_butler'

local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local explorerlite = require 'core.explorerlite'
local base_task = require 'tasks.base'

local task = base_task.new_task()
local status_enum = {
    IDLE = 'Idle',
    WAITING = 'Waiting ',
    EXECUTE = 'Teleporting',
    MOVING = 'Moving to portal',
    INTERACTING = 'Interacting with portal',
    RESETTING = 'Re-trying teleport',
    FAILED = 'Failed to teleport'
}
local debounce_time = -1
local debounce_timeout = 3
local function teleport_with_debounce()
    local local_player = get_local_player()
    if local_player:get_active_spell_id() == 186139 then
        task.set_status(status_enum['EXECUTE'])
    else
        local status = status_enum['WAITING'] ..
        string.format("%.2f", debounce_time + debounce_timeout - get_time_since_inject()) .. 's'
        task.set_status(status)
    end
    if debounce_time + debounce_timeout > get_time_since_inject() then return end
    debounce_time = get_time_since_inject()
    teleport_to_waypoint(0x76D58)
    task.set_status(status_enum['EXECUTE'])
end
local extension = {}
function extension.get_npc()
    return utils.get_npc(utils.npc_enum['PORTAL'])
end
function extension.move()
    if utils.player_in_zone('[sno none]') then return end
    local npc_location = utils.get_npc_location('PORTAL')
    if BatmobilePlugin then
        BatmobilePlugin.set_target(plugin_label, npc_location)
        BatmobilePlugin.move(plugin_label)
    else
        explorerlite:set_custom_target(npc_location)
        explorerlite:move_to_target()
    end
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
        tracker.last_task == 'restock' or
        tracker.last_task == 'stocktake'
    then
        new_position = vec3:new(-1684.3427734375, -595.40625, 37.6484375)
    elseif tracker.last_task == 'salvage' then
        new_position = vec3:new(-1680.57421875, -597.4794921875, 37.572265625)
    elseif tracker.last_task ==  'sell' or tracker.last_task == 'gamble' then
        new_position = vec3:new(-1670.6953125, -598.2548828125, 36.8857421875)
    end
    if BatmobilePlugin then
        BatmobilePlugin.set_target(plugin_label, new_position)
        BatmobilePlugin.move(plugin_label)
    else
        explorerlite:set_custom_target(new_position)
        explorerlite:move_to_target()
    end
end
function extension.is_done()
    local npc = extension.get_npc()
    local npc_location = utils.get_npc_location('PORTAL')
    return not (utils.player_in_zone('Scos_Cerrigar') or utils.player_in_zone('[sno none]')) or
        (utils.player_in_zone('Scos_Cerrigar') and npc == nil and utils.distance_to(npc_location) < 5)
end
function extension.done()
    if BatmobilePlugin then
        BatmobilePlugin.clear_target(plugin_label)
    end
    tracker.teleport_done = true
end
function extension.failed()
    if BatmobilePlugin then
        BatmobilePlugin.clear_target(plugin_label)
    end
    tracker.teleport_failed = true
end
function extension.is_in_vendor_screen() return false end

task.name = 'teleport'
task.extension = extension
task.status_enum = status_enum
task.max_retries = 5
task.teleport_time = nil

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
        (tracker.gamble_done or tracker.gamble_failed) and
        (tracker.sell_done or tracker.sell_failed) and
        (tracker.salvage_done or tracker.salvage_failed) and
        (tracker.repair_done or tracker.repair_failed) and
        (tracker.stash_done or tracker.stash_failed) and
        (tracker.restock_done or tracker.restock_failed) and
        (tracker.stocktake_done or tracker.stocktake_failed)
    then
        if task.check_status(task.status_enum['FAILED']) then
            task.set_status(task.status_enum['IDLE'])
        end
        return true
    end
    return false
end
task.baseExecute = task.Execute
task.Execute = function ()
    if tracker.teleport and
        not utils.player_in_zone('Scos_Cerrigar') and
        not (tracker.gamble_done or tracker.gamble_failed) and
        not (tracker.sell_done or tracker.sell_failed) and
        not (tracker.salvage_done or tracker.salvage_failed) and
        not (tracker.repair_done or tracker.repair_failed) and
        not (tracker.stash_done or tracker.stash_failed) and
        not (tracker.restock_done or tracker.restock_failed) and
        not (tracker.stocktake_done or tracker.stocktake_failed)
    then
        task.retry = 0
        if LooteerPlugin then
            local looting = LooteerPlugin.getSettings('looting')
            if looting then
                task.set_status(status_enum['WAITING'] .. 'for looter')
                return
            end
        end
        teleport_with_debounce()
    else
        task.baseExecute()
    end
end

return task