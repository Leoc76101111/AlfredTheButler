local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'
local explorerlite = require 'core.explorerlite'
local base_task = require 'tasks.base'

local task = base_task.new_task()
local status_enum = {
    IDLE = 'Idle',
    EXECUTE = 'Gambling',
    MOVING = 'Moving to vendor',
    INTERACTING = 'Interacting with vendor',
    RESETTING = 'Re-trying gamble',
    FAILED = 'Failed to gamble'
}

local function reset_other_tasks()
    tracker.sell_done = false
    tracker.sell_failed = false
    tracker.salvage_done = false
    tracker.salvage_failed = false
    tracker.stash_done = false
    tracker.stash_failed = false
end

local extension = {}
function extension.get_npc()
    return utils.get_npc(utils.npc_enum['GAMBLER'])
    -- return utils.get_npc(utils.npc_enum['WEAPON'])
end
function extension.move()
    local npc_location = utils.get_npc_location('GAMBLER')
    -- local npc_location = utils.get_npc_location('WEAPON')
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
    tracker.last_task = task.name
    local vendor_items = loot_manager.get_vendor_items()
    if type(vendor_items) == "userdata" and vendor_items.size then
        local size = vendor_items:size()
        local player_obols = local_player:get_obols()
        local gamble_item = nil
        local gamble_price = nil
        for i = 1, size do
            local item = vendor_items:get(i)
            if item then
                local display_name = item:get_display_name():lower()
                if display_name == settings.gamble_category then
                    gamble_item = item
                    gamble_price = item:get_price()
                end
            end
        end
        -- temp fix for get_price giving 0, most expensive item is 100, so stop gambling at 100
        if gamble_price == 0 then
            gamble_price = 100
        end
        if gamble_item ~= nil and player_obols >= gamble_price then
            loot_manager.buy_item(gamble_item)
            -- set count to 1 if count == 0 due to 0.5 seconds debounce on tracker update
            if tracker.sell_count == 0 then
                tracker.sell_count = 1
            end
            if tracker.salvage_count == 0 then
                tracker.salvage_count = 1
            end
            if tracker.stash_count == 0 then
                tracker.stash_count = 1
            end
        else
            tracker.gambling = false
        end
    end
end
function extension.reset()
    local local_player = get_local_player()
    if not local_player then return end
    local new_position = vec3:new(-1670.6953125, -598.2548828125, 36.8857421875)
    if task.reset_state == status_enum['MOVING'] then
        new_position = vec3:new(-1651.9208984375, -598.6142578125, 36.3134765625)
    end
    explorerlite:set_custom_target(new_position)
    explorerlite:move_to_target()
end
function extension.is_done()
    return not tracker.gambling
end
function extension.done()
    reset_other_tasks()
    tracker.gamble_done = true
    tracker.gambling = false
end
function extension.failed()
    reset_other_tasks()
    tracker.gamble_failed = true
    tracker.gambling = false
end
function extension.is_in_vendor_screen()
    return loot_manager:is_in_vendor_screen()
end

task.name = 'gamble'
task.extension = extension
task.status_enum = status_enum

task.shouldExecute = function ()
    if tracker.trigger_tasks == false then
        task.retry = 0
    end

    if utils.player_in_zone('Scos_Cerrigar') and
        tracker.trigger_tasks and
        not tracker.gamble_failed and
        not tracker.gamble_done and
        not tracker.gamble_paused
    then
        if task.check_status(task.status_enum['FAILED']) then
            task.set_status(task.status_enum['IDLE'])
        end
        local local_player = get_local_player()
        if local_player and  #local_player:get_inventory_items() == 33 then
            reset_other_tasks()
            tracker.gamble_paused = true
        end
        return true
    end

    return false
end

return task