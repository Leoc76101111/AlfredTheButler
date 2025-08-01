local plugin_label = 'alfred_the_butler'
local plugin_version = '1.5.0'

local utils = require 'core.utils'
local gui = {}

local affix_types = utils.get_item_affixes()
local unique_items = utils.get_unique_items()
local mythic_items = utils.get_mythic_items()
local restock_items = utils.get_restock_items()

local function create_checkbox(value, key)
    return checkbox:new(value, get_hash(plugin_label .. '_' .. key))
end

local function add_tree(name,is_affix)
    local tree_name = tostring(name)
    if is_affix then
        tree_name = tree_name .. '_affix'
    end
    tree_name = tree_name .. '_tree'
    gui.elements[tree_name] = tree_node:new(2)
end

local function add_checkbox(name, data, is_affix, default)
    for _,item in pairs(data) do
        local checkbox_name = tostring(name)
        if is_affix then
            checkbox_name = checkbox_name .. '_affix'
        end
        checkbox_name = checkbox_name .. '_' .. tostring(item.sno_id)
        gui.elements[checkbox_name] = create_checkbox(default, checkbox_name)
    end
end

local function add_search(name, is_affix)
    local search_name = tostring(name)
    if is_affix then
        search_name = search_name .. '_affix'
    end
    search_name = search_name .. '_search'
    gui.elements[search_name] = input_text:new(get_hash(plugin_label .. tostring(name) .. '_search_input'))
end

local function render_checkbox(name,data, is_affix)
    local search_name = tostring(name)
    if is_affix then
        search_name = search_name .. '_affix'
    end
    search_name = search_name .. '_search'
    for _,item in pairs(data) do
        for _,class in pairs(item.class) do
            if class == 'all' or class == utils.get_character_class() then
                local checkbox_name = tostring(name)
                if is_affix then
                    checkbox_name = checkbox_name .. '_affix'
                end
                checkbox_name = checkbox_name .. '_' .. tostring(item.sno_id)
                local search_string = string.lower(gui.elements[search_name]:get())
                if search_string ~= '' and
                    (string.lower(item.name):match(search_string) or
                    string.lower(item.description):match(search_string) or
                    string.lower(item.sno_id):match(search_string))
                then
                    gui.elements[checkbox_name]:render(item.name, item.description)
                elseif gui.elements[checkbox_name]:get() then
                    gui.elements[checkbox_name]:render(item.name, item.description)
                end
            end
        end
    end
end

gui.plugin_label = plugin_label
gui.plugin_version = plugin_version

gui.stash_options = {
    'Inventory',
    'Stash'
}

gui.item_options = {
    'Keep',
    'Salvage',
    'Sell'
}

gui.stash_extra_options= {
    'Never',
    'When full',
    'Always',
}

gui.failed_options= {
    'Log',
    'Forced Retry',
}

gui.elements = {
    main_tree = tree_node:new(0),
    main_toggle = create_checkbox(false, 'main_toggle'),

    use_keybind = create_checkbox(false, 'use_keybind'),
    keybind_toggle = keybind:new(0x0A, true, get_hash(plugin_label .. '_keybind_toggle' )),
    export_keybind_toggle = keybind:new(0x0A, true, get_hash(plugin_label .. '_export_keybind_toggle' )),
    dump_keybind = keybind:new(0x0A, true, get_hash(plugin_label .. '_dump_keybind')),
    manual_keybind = keybind:new(0x0A, true, get_hash(plugin_label .. '_manual_keybind')),

    item_tree = tree_node:new(1),
    item_legendary_or_lower = combo_box:new(1, get_hash(plugin_label .. '_item_legendary_or_lower')),
    item_unique = combo_box:new(2, get_hash(plugin_label .. '_item_unique')),
    item_junk = combo_box:new(1, get_hash(plugin_label .. '_item_junk')),

    ancestral_item_tree = tree_node:new(1),
    ancestral_item_legendary = combo_box:new(1, get_hash(plugin_label .. '_ancestral_item_legendary')),
    ancestral_item_unique = combo_box:new(1, get_hash(plugin_label .. '_ancestral_item_unique')),
    ancestral_item_junk = combo_box:new(1, get_hash(plugin_label .. '_ancestral_item_junk')),
    ancestral_item_mythic = combo_box:new(0, get_hash(plugin_label .. '_ancestral_item_mythic')),
    ancestral_keep_max_aspect = create_checkbox(true, 'max_aspect'),
    ancestral_ga_count_slider = slider_int:new(0, 3, 1, get_hash(plugin_label .. '_ga_slider')),
    ancestral_unique_ga_count_slider = slider_int:new(0, 4, 1, get_hash(plugin_label .. '_unique_ga_slider')),
    ancestral_mythic_ga_count_slider = slider_int:new(0, 4, 1, get_hash(plugin_label .. '_mythic_ga_slider')),
    ancestral_filter_toggle = create_checkbox(false, 'use_filter'),
    ancestral_unique_filter_toggle = create_checkbox(false, 'use_unique_filter'),

    ancestral_affix_count_slider = slider_int:new(0, 3, 2, get_hash(plugin_label .. '_affix_slider')),
    ancestral_affix_ga_count_slider = slider_int:new(0, 3, 1, get_hash(plugin_label .. '_affix_ga_slider')),
    ancestral_affix_ga = create_checkbox(false, 'affix_ga'),

    affix_export_button = button:new(get_hash(plugin_label .. '_affix_export_button')),
    affix_import_button = button:new(get_hash(plugin_label .. '_affix_import_button')),
    affix_import_name = input_text:new(get_hash(plugin_label .. '_affix_import_button')),

    socketable_tree = tree_node:new(1),
    stash_socketables = combo_box:new(0, get_hash(plugin_label .. '_stash_socketables')),

    consumeable_tree = tree_node:new(1),
    stash_consumables = combo_box:new(0, get_hash(plugin_label .. '_stash_consumables')),

    key_tree = tree_node:new(1),
    stash_keys = combo_box:new(0, get_hash(plugin_label .. '_stash_keys')),

    stash_extra_materials = create_checkbox(false, 'stash_extra_materials'),

    gamble_tree = tree_node:new(1),
    gamble_toggle = create_checkbox(false, 'gamble_toggle'),

    general_tree = tree_node:new(1),
    explorer_path_angle_slider = slider_int:new(0, 360, 10, get_hash(plugin_label .. '_explorer_path_angle_slider')),
    max_inventory = slider_int:new(20,33, 25, get_hash(plugin_label .. '_max_inventory')),
    failed_action = combo_box:new(0, get_hash(plugin_label .. '_failed_action')),
    use_evade = create_checkbox(false, 'use_evade'),
    skip_cache = create_checkbox(false, 'skip_cache'),

    drawing_tree = tree_node:new(1),
    draw_status = create_checkbox(true, 'draw_status'),
    draw_status_offset_x = slider_int:new(0, 1200, 0, get_hash(plugin_label .. "draw_status_offset_x")),
    draw_status_offset_y = slider_int:new(0, 600, 0, get_hash(plugin_label .. "draw_status_offset_y")),
    draw_stash = create_checkbox(false, 'draw_stash'),
    draw_sell = create_checkbox(false, 'draw_sell'),
    draw_salvage = create_checkbox(false, 'draw_salvage'),
    draw_box_space = slider_float:new(0, 1.0, 1.0, get_hash(plugin_label .. "draw_box_space")),
    draw_start_offset_x = slider_int:new(-50, 50, 0, get_hash(plugin_label .. "draw_start_offset_x")),
    draw_start_offset_y = slider_int:new(-50, 50, 0, get_hash(plugin_label .. "draw_start_offset_y")),
    draw_offset_x = slider_int:new(0, 150, 54, get_hash(plugin_label .. "draw_offset_x")),
    draw_offset_y = slider_int:new(0, 150, 75, get_hash(plugin_label .. "draw_offset_y")),
    draw_box_height = slider_int:new(0, 100, 79, get_hash(plugin_label .. "draw_box_height")),
    draw_box_width = slider_int:new(0, 100, 52, get_hash(plugin_label .. "draw_box_width")),

    seperator = combo_box:new(0, get_hash(plugin_label .. '_seperator')),
}

for _,affix_type in pairs(affix_types) do
    add_tree(affix_type.name,true)
    add_checkbox(affix_type.name, affix_type.data, true, false)
    add_search(affix_type.name,true)
end
add_tree('unique',false)
add_checkbox('unique', unique_items, false, false)
add_search('unique',false)
add_tree('mythic',false)
add_checkbox('mythic', mythic_items, false, true)
for _,item in pairs(restock_items) do
    local slider_name = plugin_label .. 'restock_' .. tostring(item.sno_id)
    gui.elements[slider_name] = slider_int:new(0, item.max, 0, get_hash(slider_name))
end

function gui.render()
    if not gui.elements.main_tree:push('Alfred the Butler | Leoric | v' .. gui.plugin_version) then return end
    gui.elements.main_toggle:render('Enable', 'Enable alfred')
    gui.elements.use_keybind:render('Use keybind', 'Keybind to quick toggle the bot')
    if gui.elements.use_keybind:get() then
        gui.elements.keybind_toggle:render('Toggle Keybind', 'Toggle the bot for quick enable')
        gui.elements.export_keybind_toggle:render('Toggle Export Keybind', 'Toggle to export inventory data before sell/salvage/stash')
        gui.elements.dump_keybind:render('Dump tracker info', 'Dump all tracker info to log')
        gui.elements.manual_keybind:render('Manual trigger', 'Make alfred run tasks now')
    end
    if gui.elements.drawing_tree:push('Display settings') then
        gui.elements.draw_status:render('Draw status', 'Draw status info on screen')
        gui.elements.draw_stash:render('Draw Keep items', 'Draw blue box around items that alfred will keep/stash')
        if gui.elements.draw_stash:get() then
            render_menu_header('Items to keep/stash are drawn with blue box')
        end
        gui.elements.draw_salvage:render('Draw Salvage items', 'Draw orange box around items that alfred will salvage')
        if gui.elements.draw_salvage:get() then
            render_menu_header('Items to salvage are drawn with orange box')
        end
        gui.elements.draw_sell:render('Draw Sell items', 'Draw pink box around items that alfred will sell')
        if gui.elements.draw_sell:get() then
            render_menu_header('Items to sell are drawn with pink box')
        end
        gui.elements.draw_status_offset_x:render("Status Offset X", "Adjust status message offset X")
        gui.elements.draw_status_offset_y:render("Status Offset Y", "Adjust status message offset Y")
        gui.elements.draw_box_space:render("Box Spacing", "", 1)
        gui.elements.draw_start_offset_x:render("Start Offset X", "Adjust starting offset X")
        gui.elements.draw_start_offset_y:render("Start Offset Y", "Adjust start offset Y")
        gui.elements.draw_offset_x:render("Slot Offset X", "Adjust slot offset X")
        gui.elements.draw_offset_y:render("Slot Offset Y", "Adjust slot offset Y")
        gui.elements.draw_box_height:render("Box Height Slider", "Adjust box height")
        gui.elements.draw_box_width:render("Box Width Slider", "Adjust box width")
        gui.elements.drawing_tree:pop()
    end
    if gui.elements.general_tree:push('General settings') then
        gui.elements.use_evade:render('Use Evade', 'Use evade when doing task in town')
        gui.elements.explorer_path_angle_slider:render("Explorer Path angle", "adjust the angle for path filtering (0 - 360 degrees)")
        render_menu_header('IMPORTANT TO SET MAX INVENTORY ITEM TO 25 OR LOWER IF YOU ARE RUNNING BOSSER AND NOT PICKING EVERYTHING UP. SETTING HIGHER THAN 25 MIGHT CAUSE A MYTHIC TO BE LOST')
        gui.elements.max_inventory:render("Max inventory items", "No. of items in inventory to trigger alfred tasks")
        gui.elements.failed_action:render('Failed action', gui.failed_options, 'Select what to do when alfred is in complete failure')
        if gui.elements.failed_action:get() == utils.failed_action_enum['LOG'] then
            render_menu_header('Log action will leave your character standing there and you might get disconnected for inactivity, but logs should still be copyable')
        else
            render_menu_header('Forced retry action will keep looping tasks, this will cause your character to move away and back and not trigger inactivity timer. if problem persist, it will stuck in a loop')
        end
        gui.elements.skip_cache:render('Skip stashing cache', 'Keep caches in inventory (mainly for season 8)')
        if gui.elements.skip_cache:get() then
            render_menu_header('If you choose to skip stashing cache and your inventory is full of caches, alfred will just stand there')
        end
        gui.elements.general_tree:pop()
    end
    if gui.elements.item_tree:push('Non-Ancestral') then
        render_menu_header('Select the default action for the following item types for non-ancestral items')
        gui.elements.item_unique:render('unique items', gui.item_options, 'Select what to do with non-ancestral unique items')
        gui.elements.item_legendary_or_lower:render('non-unique items', gui.item_options, 'Select what to do with non-ancestral non-unique legendary items')
        gui.elements.item_junk:render('junk items', gui.item_options, 'Select what to do with junk items')
        gui.elements.item_tree:pop()
    end
    if gui.elements.ancestral_item_tree:push('Ancestral') then
        render_menu_header('Select the default action for the following item types for ancestral items')
        gui.elements.ancestral_item_mythic:render('mythic items', gui.item_options, 'Select what to do with mythic items')
        gui.elements.ancestral_item_unique:render('unique items', gui.item_options, 'Select what to do with unique items')
        gui.elements.ancestral_item_legendary:render('legendary items', gui.item_options, 'Select what to do with non-unique legendary items')
        gui.elements.ancestral_item_junk:render('junk items', gui.item_options, 'Select what to do with junk items')
        gui.elements.ancestral_keep_max_aspect:render('Keep max aspect','Keep max aspect')
        gui.elements.ancestral_unique_filter_toggle:render('Use unique/mythic filter', 'use affix filter')
        gui.elements.ancestral_filter_toggle:render('Use legendary affix filter', 'use affix filter')
        if gui.elements.ancestral_filter_toggle:get() then
            render_menu_header('Select the number of greater affixes and matching affixes on items you want to keep (override the default actions above to keep)')
            render_menu_header('(Example, if you select 2GA and 2 matching affix, ALFRED WILL ONLY KEEP 2GA+ AND HAVE 2 MATCHING AFFIX. alfred will not keep 3GA and 1 matching affix. BOTH CONDITIONS MUST BE MET)')
        else 
            render_menu_header('Select the number of greater affixes on items you want to keep (override the default actions above to keep)')
        end
        gui.elements.ancestral_mythic_ga_count_slider:render('Mythic Greater Affix', 'Minimum greater affix to keep for mythic')
        gui.elements.ancestral_unique_ga_count_slider:render('Unique Greater Affix', 'Minimum greater affix to keep for unique')
        gui.elements.ancestral_ga_count_slider:render('Legendary Greater Affix', 'Minimum greater affix to keep for legendaries')
        if gui.elements.ancestral_filter_toggle:get() then
            gui.elements.ancestral_affix_count_slider:render('Min matching Affix', 'Minimum matching affix to keep')
            -- gui.elements.ancestral_affix_ga_count_slider:render('Min matching GA', 'Minimum matching greater affix')
        end
        if gui.elements.ancestral_unique_filter_toggle:get() then
            render_menu_header('REMEMBER TO SET THE UNIQUE/MYTHIC YOU WANT SO THAT IT DOESNT GET ACCIDENTALLY SALVAGED/SOLD')
            if gui.elements['unique_tree']:push('Unique item') then
                gui.elements['unique_search']:render('Search', 'Find unique items', false, '', '')
                render_checkbox('unique', unique_items, false)
                gui.elements['unique_tree']:pop()
            end
            if gui.elements['mythic_tree']:push('Mythic item') then
                for _,item in pairs(mythic_items) do
                    local checkbox_name = 'mythic_' .. tostring(item.sno_id)
                    gui.elements[checkbox_name]:render(item.name, item.description)
                end
                gui.elements['mythic_tree']:pop()
            end
        end
        if gui.elements.ancestral_filter_toggle:get() then
            render_menu_header('REMEMBER TO SET THE AFFIX YOU WANT SO THAT IT DOESNT GET ACCIDENTALLY SALVAGED/SOLD')
            for _,affix_type in pairs(affix_types) do
                local tree_name = tostring(affix_type.name) .. '_affix_tree'
                local search_name = tostring(affix_type.name) .. '_affix_search'
                if gui.elements[tree_name]:push('Legendary ' .. affix_type.name .. ' affix') then
                    gui.elements[search_name]:render('Search', 'Find affixes', false, '', '')
                    render_checkbox(affix_type.name, affix_type.data, true)
                    gui.elements[tree_name]:pop()
                end
            end
        end
        if gui.elements.ancestral_unique_filter_toggle:get() or gui.elements.ancestral_filter_toggle:get() then
            render_menu_header('Export or import affix data, unique data and mythic data')
            gui.elements.seperator:render('',{'Export'},'')
            gui.elements.affix_export_button:render('', 'export all selected affixes to export folder', 0)
            gui.elements.seperator:render('',{'Import'},'')
            gui.elements.affix_import_name:render('file name', 'file name to import', false, 'import', '')
            gui.elements.affix_import_button:render('', 'import selected affixes from file', 0)
        end
        gui.elements.ancestral_item_tree:pop()
    end
    if gui.elements.socketable_tree:push('Socketables') then
        gui.elements.stash_socketables:render('Stash socketables', gui.stash_extra_options, 'Select when to stash socketables')
        if gui.elements.stash_socketables:get() == utils.stash_extra_enum['NEVER'] then
            render_menu_header('Never stash socketables')
        elseif gui.elements.stash_socketables:get() == utils.stash_extra_enum['FULL'] then
            render_menu_header('Stash all socketables when alfred is stashing equipment if socketables inventory is full')
        elseif gui.elements.stash_socketables:get() == utils.stash_extra_enum['ALWAYS'] then
            render_menu_header('Stash all socketables when alfred is stashing')
        end
        gui.elements.socketable_tree:pop()
    end
    if gui.elements.socketable_tree:push('Consumables (boss materials)') then
        gui.elements.stash_consumables:render('Stash consumables', gui.stash_extra_options, 'Select when to stash consumables')
        if gui.elements.stash_consumables:get() == utils.stash_extra_enum['NEVER'] then
            render_menu_header('Never stash consumables')
        elseif gui.elements.stash_consumables:get() == utils.stash_extra_enum['FULL'] then
            render_menu_header('Stash extra boss materials when alfred is stashing equipment if consumables inventory is full')
        elseif gui.elements.stash_consumables:get() == utils.stash_extra_enum['ALWAYS'] then
            render_menu_header('Stash extra boss materials when alfred is stashing')
        end
        render_menu_header('Restock')
        for _,item in pairs(restock_items) do
            if item.item_type == 'consumables' then 
                local slider_name = plugin_label .. 'restock_' .. tostring(item.sno_id)
                gui.elements[slider_name]:render(item.name, 'Maximum to have in inventory')
            end
        end
        gui.elements.socketable_tree:pop()
    end
    if gui.elements.key_tree:push('Dungeon Keys') then
        gui.elements.stash_keys:render('Stash dungeon keys', gui.stash_extra_options, 'Select when to stash dungeon keys')
        if gui.elements.stash_keys:get() == utils.stash_extra_enum['NEVER'] then
            render_menu_header('Never stash dungeon keys')
        elseif gui.elements.stash_keys:get() == utils.stash_extra_enum['FULL'] then
            render_menu_header('Stash extra compasses and tributes when alfred is stashing equipment if dungeon keys inventory is full')
        elseif gui.elements.stash_keys:get() == utils.stash_extra_enum['ALWAYS'] then
            render_menu_header('Stash extra compasses and tributes when alfred is stashing')
        end
        render_menu_header('Restock')
        for _,item in pairs(restock_items) do
            if item.item_type == 'key' then 
                local slider_name = plugin_label .. 'restock_' .. tostring(item.sno_id)
                gui.elements[slider_name]:render(item.name, 'Maximum to have in inventory')
            end
        end
        gui.elements.key_tree:pop()
    end

    -- if gui.elements.gamble_tree:push('Gamble') then
    --     gui.elements.gamble_toggle:render('Gambling', 'Enable gambling items')
    --     gui.elements.gamble_tree:pop()
    -- end
    gui.elements.main_tree:pop()
end

return gui