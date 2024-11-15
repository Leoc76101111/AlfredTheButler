local plugin_label = 'alfred_the_butler'
local plugin_version = 'v1.1.5'

local utils = require 'core.utils'
local gui = {}

local affix_types = utils.get_item_affixes()
local unique_items = utils.get_unique_items()
local restock_items = utils.get_restock_items()

local function create_checkbox(value, key)
    return checkbox:new(value, get_hash(plugin_label .. '_' .. key))
end

local function add_affix_tree(name)
    local tree_name = tostring(name) .. '_affix_tree'
    gui.elements[tree_name] = tree_node:new(2)
end

local function add_affix_checkbox(name,data)
    for _,affix in pairs(data) do
        local checkbox_name = tostring(name) .. '_affix_' .. tostring(affix.sno_id)
        gui.elements[checkbox_name] = create_checkbox(false, checkbox_name)
    end
end

local function add_affix_search(name)
    local search_name = tostring(name) .. '_affix_search'
    gui.elements[search_name] = input_text:new(get_hash(plugin_label .. tostring(name) .. '_search_input'))
end

local function render_affix_checkbox(name,data)
    local search_name = tostring(name) .. '_affix_search'
    for _,affix in pairs(data) do
        for _,class in pairs(affix.class) do
            if class == 'all' or class == utils.get_character_class() then
                local checkbox_name = tostring(name) .. '_affix_' .. tostring(affix.sno_id)
                local search_string = string.lower(gui.elements[search_name]:get())
                if search_string ~= '' and
                    (string.lower(affix.name):match(search_string) or
                    string.lower(affix.description):match(search_string) or
                    string.lower(affix.sno_id):match(search_string))
                then
                    gui.elements[checkbox_name]:render(affix.name, affix.description)
                elseif gui.elements[checkbox_name]:get() then
                    gui.elements[checkbox_name]:render(affix.name, affix.description)
                end
            end
        end
    end
end

gui.stash_options = {
    'Inventory',
    'Stash'
}

gui.item_options = {
    'Keep',
    'Salvage',
    'Sell'
}

gui.restock_options = {
    'Active',
    'Passive',
}

gui.elements = {
    main_tree = tree_node:new(0),
    main_toggle = create_checkbox(false, 'main_toggle'),

    use_keybind = create_checkbox(false, 'use_keybind'),
    keybind_toggle = keybind:new(0x0A, true, get_hash(plugin_label .. '_keybind_toggle' )),
    dump_keybind = keybind:new(0x0A,false,get_hash(plugin_label .. '_dump_keybind')),
    manual_keybind = keybind:new(0x0A,false,get_hash(plugin_label .. '_manual_keybind')),

    stash_toggle = create_checkbox(false, 'stash_toggle'),

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

    ancestral_filter_tree = tree_node:new(2),
    ancestral_affix_count_slider = slider_int:new(0, 3, 2, get_hash(plugin_label .. '_affix_slider')),
    ancestral_affix_ga_count_slider = slider_int:new(0, 3, 1, get_hash(plugin_label .. '_affix_ga_slider')),
    ancestral_affix_ga = create_checkbox(false, 'affix_ga'),

    affix_export_button = button:new(get_hash(plugin_label .. '_affix_export_button')),
    affix_import_button = button:new(get_hash(plugin_label .. '_affix_import_button')),
    affix_import_name = input_text:new(get_hash(plugin_label .. '_affix_import_button')),

    restock_tree = tree_node:new(1),
    restock_type = combo_box:new(1, get_hash(plugin_label .. '_restock_type')),
    restock_teleport_delay =  slider_int:new(0, 300, 60, get_hash(plugin_label .. '_restock_teleport_delay')),
    stash_all_socketables = create_checkbox(false, 'stash_all_socketables'),
    stash_extra_materials = create_checkbox(false, 'stash_extra_materials'),

    gamble_tree = tree_node:new(1),
    gamble_toggle = create_checkbox(false, 'gamble_toggle'),

    explorer_tree = tree_node:new(1),
    explorer_path_angle_slider = slider_int:new(0, 360, 10, get_hash(plugin_label .. '_explorer_path_angle_slider')),

    seperator = combo_box:new(0, get_hash(plugin_label .. '_seperator')),
}

for _,affix_type in pairs(affix_types) do
    add_affix_tree(affix_type.name)
    add_affix_checkbox(affix_type.name, affix_type.data)
    add_affix_search(affix_type.name)
end
add_affix_tree('unique')
add_affix_checkbox('unique', unique_items)
add_affix_search('unique')
for _,item in pairs(restock_items) do
    local slider_name = plugin_label .. 'restock_' .. tostring(item.sno_id)
    gui.elements[slider_name] = slider_int:new(0, item.max, 0, get_hash(slider_name))
end

function gui.render()
    if not gui.elements.main_tree:push('Alfred the Butler | Leoric | ' .. plugin_version) then return end
    gui.elements.main_toggle:render('Enable', 'Enable alfred')
    gui.elements.use_keybind:render('Use keybind', 'Keybind to quick toggle the bot')
    if gui.elements.use_keybind:get() then
        gui.elements.keybind_toggle:render('Toggle Keybind', 'Toggle the bot for quick enable')
        gui.elements.dump_keybind:render('Dump tracker info', 'Dump all tracker info to log')
        gui.elements.manual_keybind:render('Manual trigger', 'Make alfred run tasks now')
    end
    gui.elements.stash_toggle:render('Keep item in stash','Keep item in stash')
    if gui.elements.explorer_tree:push('Explorer settings') then
        gui.elements.explorer_path_angle_slider:render("Path angle", "adjust the angle for path filtering (0 - 360 degrees)")
        gui.elements.explorer_tree:pop()
    end
    if gui.elements.item_tree:push('Non-Ancestral') then
        gui.elements.item_unique:render('unique items', gui.item_options, 'Select what to do with non-ancestral unique items')
        gui.elements.item_legendary_or_lower:render('non-unique items', gui.item_options, 'Select what to do with non-ancestral non-unique legendary items')
        gui.elements.item_junk:render('junk items', gui.item_options, 'Select what to do with junk items')
        gui.elements.item_tree:pop()
    end
    if gui.elements.ancestral_item_tree:push('Ancestral') then
        gui.elements.ancestral_item_mythic:render('mythic items', gui.item_options, 'Select what to do with mythic items')
        gui.elements.ancestral_item_unique:render('unique items', gui.item_options, 'Select what to do with unique items')
        gui.elements.ancestral_item_legendary:render('legendary items', gui.item_options, 'Select what to do with non-unique legendary items')
        gui.elements.ancestral_item_junk:render('junk items', gui.item_options, 'Select what to do with junk items')
        gui.elements.ancestral_keep_max_aspect:render('Keep max aspect','Keep max aspect')
        if not gui.elements.ancestral_filter_toggle:get() then
            gui.elements.ancestral_mythic_ga_count_slider:render('Mythic Greater Affix', 'Minimum greater affix to keep for mythic')
            gui.elements.ancestral_unique_ga_count_slider:render('Unique Greater Affix', 'Minimum greater affix to keep for unique')
            gui.elements.ancestral_ga_count_slider:render('Legendary Greater Affix', 'Minimum greater affix to keep for legendaries')
        end
        gui.elements.ancestral_filter_toggle:render('Use affix/unique filter', 'use affix filter')
        if gui.elements.ancestral_filter_toggle:get() then
            if gui.elements.ancestral_filter_tree:push('General') then
                gui.elements.ancestral_mythic_ga_count_slider:render('Mythic Greater Affix', 'Minimum greater affix to keep for mythic')
                gui.elements.ancestral_unique_ga_count_slider:render('Unique Greater Affix', 'Minimum greater affix to keep for unique')
                gui.elements.ancestral_ga_count_slider:render('Legendary Greater Affix', 'Minimum greater affix to keep for legendaries')
                gui.elements.ancestral_affix_count_slider:render('Min matching Affix', 'Minimum matching affix to keep')
                -- gui.elements.ancestral_affix_ga_count_slider:render('Min matching GA', 'Minimum matching greater affix')
                gui.elements.seperator:render('',{'Export'},'')
                gui.elements.affix_export_button:render('', 'export all selected affixes to export folder', 0)
                gui.elements.seperator:render('',{'Import'},'')
                gui.elements.affix_import_name:render('file name', 'file name to import', false, 'import', '')
                gui.elements.affix_import_button:render('', 'import selected affixes from file', 0)
                gui.elements.ancestral_filter_tree:pop()
            end
            if gui.elements['unique_affix_tree']:push('Unique') then
                gui.elements['unique_affix_search']:render('Search', 'Find unique items', false, '', '')
                render_affix_checkbox('unique', unique_items)
                gui.elements['unique_affix_tree']:pop()
            end
            for _,affix_type in pairs(affix_types) do
                local tree_name = tostring(affix_type.name) .. '_affix_tree'
                local search_name = tostring(affix_type.name) .. '_affix_search'
                if gui.elements[tree_name]:push(affix_type.name) then
                    gui.elements[search_name]:render('Search', 'Find affixes', false, '', '')
                    render_affix_checkbox(affix_type.name, affix_type.data)
                    gui.elements[tree_name]:pop()
                end
            end
        end
        gui.elements.ancestral_item_tree:pop()
    end
    if gui.elements.restock_tree:push('Restock') then
        gui.elements.restock_type:render('Mode',gui.restock_options,'Active mode will trigger if drop below min, Passive mode will wait for other tasks')
        if gui.elements.restock_type:get() == utils.restock_enum['ACTIVE'] then
            gui.elements.restock_teleport_delay:render('Teleport delay', 'delay so you can kill bosses')
        end
        gui.elements.stash_all_socketables:render('Stash all socketables', 'Stash all socketables when socketables inventory is full')
        gui.elements.stash_extra_materials:render('Stash extras materials', 'Stash any boss materials or compass > max')
        for _,item in pairs(restock_items) do
            local slider_name = plugin_label .. 'restock_' .. tostring(item.sno_id)
            gui.elements[slider_name]:render(item.name, 'Maximum to have in inventory')
        end
        gui.elements.restock_tree:pop()
    end

    -- if gui.elements.gamble_tree:push('Gamble') then
    --     gui.elements.gamble_toggle:render('Gambling', 'Enable gambling items')
    --     gui.elements.gamble_tree:pop()
    -- end
    gui.elements.main_tree:pop()
end

return gui