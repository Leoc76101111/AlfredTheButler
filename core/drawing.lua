local plugin_label = 'alfred_the_butler'

local gui          = require 'gui'
local utils        = require 'core.utils'
local settings     = require 'core.settings'
local task_manager = require 'core.task_manager'
local tracker      = require 'core.tracker'

local function get_affix_screen_position(item) -- (credits QQT)
    local row, col = item:get_inventory_row(), item:get_inventory_column()
    local screen_width, screen_height = get_screen_width(), get_screen_height()

    local inventory_start_x = screen_width * 0.661
    local inventory_start_y = screen_height * 0.667
    local slot_width = gui.elements.draw_offset_x:get()
    local slot_height = gui.elements.draw_offset_y:get()
    local space_between_items_x = gui.elements.draw_box_space:get()
    local space_between_items_y = 6.2

    local adjusted_slot_width = slot_width + space_between_items_x
    local adjusted_slot_height = slot_height + space_between_items_y
    local margin_x = space_between_items_x / 2
    local margin_y = space_between_items_y / 2
    local box_width = gui.elements.draw_box_width:get()
    local box_height = gui.elements.draw_box_height:get()

    local x = inventory_start_x + col * adjusted_slot_width + margin_x
    local y = inventory_start_y + row * adjusted_slot_height + margin_y

    return x, y, box_width, box_height
end

local drawing = {}

function drawing.draw_status()
    local current_task = task_manager.get_current_task()
    local status = ''
    if tracker.external_caller and tracker.external_pause then
        status = 'Paused by ' .. tracker.external_caller
    elseif not settings.get_keybind_state() and not tracker.external_caller and not tracker.trigger_tasks then
        status = 'Paused'
    elseif current_task and settings.allow_external and tracker.external_caller then
        status = '(' .. tracker.external_caller .. ' - '
        status = status .. current_task.name .. ') '
        status = status .. current_task.status:gsub('%('..tracker.external_caller..'%)','')
    elseif current_task then
        status = '(' .. current_task.name .. ') ' .. current_task.status
    else
        status = 'Unknown'
    end
    local messages = {
        'Alfred Task   : ' .. status,
        'Inventory     : ' .. tracker.inventory_count,
        'Keep          : ' .. tracker.stash_count,
        'Salvage       : ' .. tracker.salvage_count,
        'Sell          : ' .. tracker.sell_count,
        '-------------------',
    }

    for _,item in pairs(tracker.restock_items) do
        if item.max >= item.min then
            messages[#messages+1] = item.name .. ' : ' .. item.count .. '/' .. item.max
        end
    end

    local y_pos = 50
    if PLUGIN_barbara_the_oracle then
        local barbara_status = PLUGIN_barbara_the_oracle.get_status()
        if barbara_status.enabled then
            y_pos = 70
        end
    end
    for _,msg in pairs(messages) do
        graphics.text_2d(msg, vec2:new(8, y_pos), 20, color_white(255))
        y_pos = y_pos + 20
    end
end


function drawing.draw_inventory_boxes()
    local items = tracker.cached_inventory
    for _,cache in pairs(items) do
        local x, y, box_width, box_height = get_affix_screen_position(cache.item)
        if gui.elements.draw_stash:get() and cache.is_stash then
            graphics.rect(vec2:new(x, y), vec2:new(x + box_width, y + box_height), color_green(255), 1, 3)
        elseif gui.elements.draw_sell:get() and cache.is_sell then
            graphics.rect(vec2:new(x, y), vec2:new(x + box_width, y + box_height), color_blue(255), 1, 3)
        elseif gui.elements.draw_salvage:get() and cache.is_salvage then
            graphics.rect(vec2:new(x, y), vec2:new(x + box_width, y + box_height), color_red(255), 1, 3)
        end
    end

end


return drawing