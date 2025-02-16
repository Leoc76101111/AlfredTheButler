local plugin_label = 'alfred_the_butler'

local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local gui = require 'gui'
local explorerlite = require 'core.explorerlite'

-- actions need to be overwritten
local extension = {
    get_npc = function () end,
    move = function () end,
    interact = function () end,
    execute = function () end,
    reset = function () end,
    is_done = function () return false end,
    done = function () end,
    failed = function () end,
    is_in_vendor_screen = function () return false end
}

-- status_enum needs to be overwritten
local status_enum = {
    IDLE = 'Idle',
    EXECUTE = 'Action',
    MOVING = 'Moving to npc',
    INTERACTING = 'Interacting with npc',
    RESETTING = 'Re-trying action',
    FAILED = 'Action failed'
}

-- shouldExecute needs to be overwritten
local function shouldExecute()
    return false
end

local base = {}
function base.new_task()
    local task = {
        name = 'base',
        status = status_enum['IDLE'],
        last_interaction = 0,
        retry = 0,
        interaction_timeout = 2,
        max_retries = 2,
        last_location = nil,
        last_stuck_location = nil,
        reset_state = nil,
    }

    task.extension = extension
    task.status_enum = status_enum
    task.shouldExecute = shouldExecute

    function task.set_status(status)
        local status_prefix = ''
        if tracker.external_caller then
            status_prefix = '(' .. tostring(tracker.external_caller) .. ') '
        end
        task.status = status_prefix .. status
    end

    function task.check_status(status)
        local status_prefix = ''
        if tracker.external_caller then
            status_prefix = '(' .. tostring(tracker.external_caller) .. ') '
        end
        return task.status == status_prefix .. status
    end

    function task.Execute()
        local current_time = get_time_since_inject()
        local npc = task.extension.get_npc()
        local npc_bugged = false
        local player_stuck = false
        local player_position = get_player_position()

        if npc then
            local npc_pos = npc:get_position()
            if npc_pos:x() == 0 and npc_pos:y() == 0 and npc_pos:z() == 0 then
                npc_bugged = true
            end
        end

        if task.last_location ~= nil and
            task.check_status(task.status_enum['MOVING']) and
            utils.is_same_position(task.last_location,player_position)
        then
            player_stuck = true
        end
        task.last_location = player_position

        if task.extension.is_done() then
            task.set_status(task.status_enum['IDLE'])
            task.retry = 0
            task.last_interaction = 0
            task.extension.done()
        elseif task.check_status(task.status_enum['MOVING']) and
            player_stuck and
            task.last_stuck_location == nil and
            task.last_interaction + task.interaction_timeout < current_time
        then
            task.set_status(task.status_enum['RESETTING'])
            task.last_interaction = current_time
            task.retry = task.retry + 1
            task.reset_state = task.status_enum['MOVING']
            task.extension.reset()
            task.last_stuck_location = player_position
        elseif task.check_status(task.status_enum['RESETTING']) and
            task.last_interaction + task.interaction_timeout >= current_time
        then
            task.set_status(task.status_enum['RESETTING'])
            task.extension.reset()
        elseif (not npc or (not npc_bugged and utils.distance_to(npc) >= 2)) and
            task.last_interaction + task.interaction_timeout < current_time
        then
            task.set_status(task.status_enum['MOVING'])
            task.last_interaction = current_time
            task.last_stuck_location = nil
            task.extension.move()
        elseif task.check_status(task.status_enum['MOVING']) and
            (not npc or (not npc_bugged and utils.distance_to(npc) >= 2)) and
            task.last_interaction + task.interaction_timeout >= current_time
        then
            task.set_status(task.status_enum['MOVING'])
            task.extension.move()
        elseif (npc_bugged or (npc and utils.distance_to(npc) < 2)) and
            (task.check_status(task.status_enum['MOVING']) or
            task.check_status(task.status_enum['IDLE']))
        then
            task.set_status(task.status_enum['INTERACTING'])
            task.last_interaction = current_time
            task.extension.interact()
        elseif task.check_status(task.status_enum['INTERACTING']) and
            task.last_interaction + task.interaction_timeout >= current_time and
            not (task.extension.is_in_vendor_screen())
        then
            task.set_status(task.status_enum['INTERACTING'])
            task.extension.interact()
        elseif task.check_status(task.status_enum['INTERACTING']) and
            (task.extension.is_in_vendor_screen() or
            task.last_interaction + task.interaction_timeout < current_time)
        then
            task.set_status(task.status_enum['EXECUTE'])
            task.last_interaction = current_time
            task.extension.execute()
        elseif task.check_status(task.status_enum['EXECUTE']) and
            task.last_interaction + task.interaction_timeout >= current_time and
            not task.extension.is_done()
        then
            task.set_status(task.status_enum['EXECUTE'])
            task.extension.execute()
        elseif task.check_status(task.status_enum['EXECUTE']) and
            task.last_interaction + task.interaction_timeout < current_time and
            not task.extension.is_done() and
            task.retry < task.max_retries
        then
            task.set_status(task.status_enum['RESETTING'])
            task.last_interaction = current_time
            task.retry = task.retry + 1
            task.reset_state = task.status_enum['EXECUTE']
            task.extension.reset()
        else
            task.extension.failed()
            task.status  = status_prefix .. task.status_enum['FAILED']
            task.retry = 0
        end
    end

    return task
end

return base