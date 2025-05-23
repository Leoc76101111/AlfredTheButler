local gui          = require 'gui'
local settings     = require 'core.settings'
local task_manager = require 'core.task_manager'
local tracker      = require 'core.tracker'

local function get_affix_screen_position(item) -- (credits QQT)
    local row, col = item:get_inventory_row(), item:get_inventory_column()
    local screen_width, screen_height = get_screen_width(), get_screen_height()

    local inventory_start_x = screen_width * 0.661 + gui.elements.draw_start_offset_x:get()
    local inventory_start_y = screen_height * 0.667 + gui.elements.draw_start_offset_y:get()
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
    elseif not (settings.get_keybind_state() or tracker.external_trigger or tracker.manual_trigger) then
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

    local messages = {}
    if RobinTheSidekickPlugin then
        local robin_status = RobinTheSidekickPlugin.get_status()
        if robin_status.enabled then
            messages[#messages+1] = 'Robin Mode       : ' .. tostring(robin_status.mode)
        end
    end

    local keybind_status = 'Off'
    if settings.get_export_keybind_state() then keybind_status = 'On' end
    messages[#messages+1] = 'Alfred Task      : ' .. status
    messages[#messages+1] = 'Export Inventory : ' .. keybind_status
    messages[#messages+1] = 'Inventory        : ' .. tracker.inventory_count
    messages[#messages+1] = 'Keep             : ' .. tracker.stash_count
    messages[#messages+1] = 'Salvage          : ' .. tracker.salvage_count
    messages[#messages+1] = 'Sell             : ' .. tracker.sell_count
    messages[#messages+1] = '----------------------'

    for _,item in pairs(tracker.restock_items) do
        if item.max >= item.min then
            messages[#messages+1] = item.name .. ' : ' .. item.count .. '/' .. item.max
        end
    end

    local x_pos = 8 + gui.elements.draw_status_offset_x:get()
    local y_pos = 50 + gui.elements.draw_status_offset_y:get()
    for _,msg in pairs(messages) do
        graphics.text_2d(msg, vec2:new(x_pos, y_pos), 20, color_white(255))
        y_pos = y_pos + 20
    end
end


function drawing.draw_inventory_boxes()
    local items = tracker.cached_inventory
    for _,cache in pairs(items) do
        local x, y, box_width, box_height = get_affix_screen_position(cache.item)
        local draw_affix = false
        if gui.elements.draw_stash:get() and cache.is_stash then
            graphics.rect(vec2:new(x, y), vec2:new(x + box_width, y + box_height), color_blue(255), 1, 4)
            draw_affix = true
        elseif gui.elements.draw_sell:get() and cache.is_sell then
            graphics.rect(vec2:new(x, y), vec2:new(x + box_width, y + box_height), color_pink(255), 1, 3)
            draw_affix = true
        elseif gui.elements.draw_salvage:get() and cache.is_salvage then
            graphics.rect(vec2:new(x, y), vec2:new(x + box_width, y + box_height), color_orange_red(255), 1, 3)
            draw_affix = true
        end
        if draw_affix then
            if cache.is_max_aspect and cache.affix_count > 0 then
                graphics.text_2d(tostring(cache.affix_count) .. "*", vec2:new(x + box_width - 24, y + box_height - 25), 20, color_white(255))
            elseif cache.is_max_aspect then
                graphics.text_2d("*", vec2:new(x + box_width - 15, y + box_height - 25), 20, color_white(255))
            elseif cache.affix_count > 0 then
                graphics.text_2d(tostring(cache.affix_count), vec2:new(x + box_width - 15, y + box_height - 25), 20, color_white(255))
            end
        end
        
    end

end


return drawing