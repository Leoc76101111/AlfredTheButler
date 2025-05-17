local utils = require 'core.utils'
local settings = require 'core.settings'
local tracker = require 'core.tracker'

local external = {
    get_status = function ()
        return {
            name            = settings.plugin_label,
            version         = settings.plugin_version,
            enabled         = settings.enabled,
            teleport        = tracker.teleport,
            teleport_done   = tracker.teleport_done,
            teleport_failed = tracker.teleport_failed,
            inventory_full  = tracker.inventory_full,
            inventory_count = tracker.inventory_count,
            salvage_count   = tracker.salvage_count,
            sell_count      = tracker.sell_count,
            stash_count     = tracker.stash_count,
            restock_count   = tracker.restock_count,
            trigger_tasks   = tracker.trigger_tasks,
            last_reset      = tracker.last_reset,
            salvage_failed  = tracker.salvage_failed,
            salvage_done    = tracker.salvage_done,
            sell_failed     = tracker.sell_failed,
            sell_done       = tracker.sell_done,
            all_task_done   = tracker.all_task_done,
            need_repair     = tracker.need_repair,
            need_trigger    = tracker.need_trigger,
        }
    end,
    check_version = function(input)
        input = input:gsub("^v", "")
        local current = {}
        local check = {}
        for part in settings.plugin_version:gmatch("%d+") do
            local num = tonumber(part)
            if not num then return false end
            table.insert(current, num)
        end
        for part in input:gmatch("%d+") do
            local num = tonumber(part)
            if not num then return false end
            table.insert(check, num)
        end
        if #check ~= 3 then
            return false
        end
        for i = 1, 3 do
            if current[i] > check[i] then
                return true
            elseif current[i] < check[i] then
                return false
            end
        end
        return true
    end,
    pause = function (caller)
        tracker.external_caller = caller
        tracker.external_pause = true
    end,
    resume = function ()
        tracker.external_caller = nil
        tracker.external_pause = false
    end,
    trigger_tasks = function (caller, callback)
        tracker.external_caller = caller
        tracker.external_trigger = true
        if callback then
            tracker.external_trigger_callback = callback
        end
        utils.log('task triggered by ' .. tostring(caller))
    end,
    trigger_tasks_with_teleport = function (caller,callback)
        tracker.external_caller = caller
        tracker.external_trigger = true
        tracker.teleport = true
        if callback then
            tracker.external_trigger_callback = callback
        end
        utils.log('task triggered by ' .. tostring(caller))
    end,
    stock_take = function (caller, callback)
        tracker.stocktake = true
        tracker.external_caller = caller
        tracker.external_trigger = true
        if callback then
            tracker.external_trigger_callback = callback
        end
        utils.log('task triggered by ' .. tostring(caller))
    end,
    get_restock_items = function ()
        return tracker.restock_items
    end,
    override_restock_item = function (caller, id, value)
        if caller ~= nil and type(value) == "number" then
            for key,item in pairs(tracker.restock_items) do
                if item.sno_id == id then
                    tracker.restock_items[key].override = {
                        caller = caller,
                        max = value
                    }
                    utils.log('override '.. tostring(id) .. ' set by ' .. tostring(caller))
                    return true
                end
            end
        end
        utils.log('override failed by ' .. tostring(caller))
        return false
    end,
    clear_override = function (caller, id)
        if caller ~= nil then
            for key,item in pairs(tracker.restock_items) do
                if item.sno_id == id then
                    tracker.restock_items[key].override = {
                        caller = nil,
                        max = -1
                    }
                    utils.log('override '.. tostring(id) .. ' unset by ' .. tostring(caller))
                    return true
                end
            end
        end
        utils.log('clear override failed by ' .. tostring(caller))
        return false
    end,
    update_stash_count = function (caller, id, value)
        if caller ~= nil and type(value) == "number" then
            for key,item in pairs(tracker.restock_items) do
                if item.sno_id == id then
                    tracker.restock_items[key].stash = value
                    utils.log('stash count '.. tostring(id) .. ' updated by ' .. tostring(caller))
                    return true
                end
            end
        end
        utils.log('stash count update failed by ' .. tostring(caller))
        return false
    end
    -- add_restock_item = function (caller, id, type, min, max)
    --     utils.log(caller)
    --     utils.log(id)
    --     utils.log(type)
    --     utils.log(min)
    --     utils.log(max)
    --     return false
    -- end,
}
return external