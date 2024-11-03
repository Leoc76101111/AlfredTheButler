local gui = {}
local plugin_label = "alfred_the_butler"

local helm_affix = require "data.helm"
local chest_affix = require "data.chest"
local gloves_affix = require "data.gloves"
local pants_affix = require "data.pants"
local boots_affix = require "data.boots"
local amulet_affix = require "data.amulet"
local ring_affix = require "data.ring"
local weapon_affix = require "data.weapon"
local offhand_affix = require "data.offhand"
local unique_affix = require "data.unique"

local affix_types = {
    {name = "helm", data = helm_affix},
    {name = "chest", data = chest_affix},
    {name = "gloves", data = gloves_affix},
    {name = "pants", data = pants_affix},
    {name = "boots", data = boots_affix},
    {name = "amulet", data = amulet_affix},
    {name = "ring", data = ring_affix},
    {name = "weapon", data = weapon_affix},
    {name = "offhand", data = offhand_affix},
    {name = "unique", data = unique_affix},
}

local function create_checkbox(value, key)
    return checkbox:new(value, get_hash(plugin_label .. "_" .. key))
end
local function add_affix_checkbox(name,data)
    for _,affix in pairs(data) do
        if affix.is_aspect == false then
            local name = tostring(name) .. '_affix_' .. tostring(affix.sno_id)
            local search_name = 'search_' .. name
            gui.elements[name] = create_checkbox(false, name)
            gui.elements[search_name] = create_checkbox(false, name)
        end
    end
    return
end
local function render_affix_checkbox(name,data,is_search)
    for _,affix in pairs(data) do
        if affix.is_aspect == false then
            local name = tostring(name) .. '_affix_' .. tostring(affix.sno_id)
            local search_name = 'search_' .. name
            if is_search then
                local search_string = gui.elements.search_affix_input:get()
                if search_string ~= '' and (string.lower(affix.affix_name):match(search_string) or string.lower(affix.affix_description):match(search_string)) then
                    gui.elements[search_name]:render(affix.affix_name, affix.affix_description)
                end
            else 
                if gui.elements[search_name]:get() or gui.elements[name]:get() then
                    gui.elements[name]:render(affix.affix_name, affix.affix_description)
                end
            end
        end
    end
    return
end

gui.stash_options = {
    "Inventory",
    "Stash"
}

gui.item_options = {
    "Keep",
    "Salvage",
    "Sell"
}

gui.elements = {
    main_tree = tree_node:new(0),
    main_toggle = create_checkbox(false, "main_toggle"),
    use_keybind = create_checkbox(false, "use_keybind"),
    keybind_toggle = keybind:new(0x0A, true, get_hash(plugin_label .. "_keybind_toggle" )),
    stash_toggle = create_checkbox(false, "stash_toggle"),

    item_tree = tree_node:new(1),
    item_legendary_or_lower = combo_box:new(1, get_hash(plugin_label .. "_item_legendary_or_lower")),
    item_unique = combo_box:new(2, get_hash(plugin_label .. "_item_unique")),
    item_junk = combo_box:new(1, get_hash(plugin_label .. "_item_junk")),

    ancestral_item_tree = tree_node:new(1),
    ancestral_item_legendary = combo_box:new(1, get_hash(plugin_label .. "_ancestral_item_legendary")),
    ancestral_item_unique = combo_box:new(1, get_hash(plugin_label .. "_ancestral_item_unique")),
    ancestral_item_junk = combo_box:new(1, get_hash(plugin_label .. "_ancestral_item_junk")),
    ancestral_keep_max_aspect = create_checkbox(true, "max_aspect"),
    ancestral_keep_ga_slider = slider_int:new(0, 3, 1, get_hash(plugin_label .. "_ga_slider")),
    ancestral_filter_toggle = create_checkbox(false, "use_filter"),

    ancestral_filter_tree = tree_node:new(2),
    ancestral_affix_slider = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_affix_slider")),
    ancestral_affix_ga_slider = slider_int:new(0, 3, 1, get_hash(plugin_label .. "_affix_ga_slider")),
    ancestral_affix_ga = create_checkbox(false, "affix_ga"),

    selected_affix_tree = tree_node:new(2),
    search_affix_tree = tree_node:new(2),
    search_affix_input = input_text:new(get_hash(plugin_label .. "_search_input")),

    restock_tree = tree_node:new(1),
    restock_toggle = create_checkbox(false, "restock_toggle"),

    gamble_tree = tree_node:new(1),
    gamble_toggle = create_checkbox(false, "gamble_toggle"),

    repair_tree = tree_node:new(1),
    repair_toggle = create_checkbox(false, "repair_toggle"),
}

for _,affix_type in pairs(affix_types) do
    add_affix_checkbox(affix_type.name, affix_type.data)
end

function gui.render()
    if not gui.elements.main_tree:push("Alfred the Butler | Leoric | v0.1.0") then return end
    gui.elements.main_toggle:render("Enable", "Enable the bot")
    gui.elements.use_keybind:render("Use keybind", "Keybind to quick toggle the bot");
    if gui.elements.use_keybind:get() then
        gui.elements.keybind_toggle:render("Toggle Keybind", "Toggle the bot for quick enable");
    end
    gui.elements.stash_toggle:render("Keep item in stash","Keep item in stash")
    if gui.elements.item_tree:push("Non-Ancestral") then
        gui.elements.item_legendary_or_lower:render("non-unique items", gui.item_options, "Select what to do with non-ancestral non-unique legendary items")
        gui.elements.item_unique:render("unique items", gui.item_options, "Select what to do with non-ancestral unique items")
        gui.elements.item_junk:render("junk items", gui.item_options, "Select what to do with junk items")
        gui.elements.item_tree:pop()
    end
    if gui.elements.ancestral_item_tree:push("Ancestral") then
        if not gui.elements.ancestral_filter_toggle:get() then
            gui.elements.ancestral_keep_ga_slider:render("Min Greater Affix", "Minimun greater affix to keep")
        end
        gui.elements.ancestral_item_legendary:render("non-unique items", gui.item_options, "Select what to do with non-unique legendary items")
        gui.elements.ancestral_item_unique:render("unique items", gui.item_options, "Select what to do with unique items")
        gui.elements.ancestral_item_junk:render("junk items", gui.item_options, "Select what to do with junk items")
        gui.elements.ancestral_keep_max_aspect:render("Keep max aspect","Keep max aspect")
        gui.elements.ancestral_filter_toggle:render("Use filter", "use filter")
        if gui.elements.ancestral_filter_toggle:get() then
            if gui.elements.ancestral_filter_tree:push("affix filters") then
                gui.elements.ancestral_keep_ga_slider:render("Min Greater Affix", "Minimun greater affix to keep")
                gui.elements.ancestral_affix_slider:render("Min matching Affix", "Minimum matching affix to keep")
                gui.elements.ancestral_affix_ga_slider:render("Min matching GA", "Minimum matching greater affix")
                gui.elements.ancestral_filter_tree:pop()
            end
            if gui.elements.selected_affix_tree:push("selected affixes") then
                for _,affix_type in pairs(affix_types) do
                    render_affix_checkbox(affix_type.name, affix_type.data, false)
                end
                gui.elements.selected_affix_tree:pop()
            end
            if gui.elements.selected_affix_tree:push("Search affixes") then
                gui.elements.search_affix_input:render("Search", "Find affixes", false, '', '')
                for _,affix_type in pairs(affix_types) do
                    render_affix_checkbox(affix_type.name, affix_type.data, true)
                end
                gui.elements.selected_affix_tree:pop()
            end
        end

        gui.elements.ancestral_item_tree:pop()
    end
    -- if gui.elements.restock_tree:push("Restock") then
    --     gui.elements.restock_toggle:render("Restocking", "Enable restocking items")
    --     gui.elements.restock_tree:pop()
    -- end
    -- if gui.elements.gamble_tree:push("Gamble") then
    --     gui.elements.gamble_toggle:render("Gambling", "Enable gambling items")
    --     gui.elements.gamble_tree:pop()
    -- end
    -- if gui.elements.repair_tree:push("Repair") then
    --     gui.elements.repair_toggle:render("Repairing", "Enable repairing items")
    --     gui.elements.repair_tree:pop()
    -- end
    gui.elements.main_tree:pop()
end

return gui