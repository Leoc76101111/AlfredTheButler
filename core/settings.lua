local plugin_label = 'alfred_the_butler'

local gui = require 'gui'
local utils = require 'core.utils'
local affix_types = utils.get_item_affixes()
local unique_items = utils.get_unique_items()
local mythic_items = utils.get_mythic_items()

local settings = {
    enabled = false,
    use_keybind = false,
    item_use_stash = true,
    timeout = 0,
    allow_external = true,
    -- item_magic = utils.item_enum['SALVAGE'],
    -- item_rare = utils.item_enum['SALVAGE'],
    -- item_legendary = utils.item_enum['SALVAGE'],
    item_legendary_or_lower = utils.item_enum['SALVAGE'],
    item_unique = utils.item_enum['SELL'],
    item_junk = utils.item_enum['SALVAGE'],
    ancestral_item_legendary = utils.item_enum['SALVAGE'],
    ancestral_item_unique = utils.item_enum['SELL'],
    ancestral_item_mythic = utils.item_enum['KEEP'],
    ancestral_item_junk = utils.item_enum['SALVAGE'],
    ancestral_keep_max_aspect = true,
    ancestral_ga_count = 0,
    ancestral_unique_ga_count = 0,
    ancestral_mythic_ga_count = 0,
    ancestral_filter = false,
    ancestral_affix_count = 0,
    ancestral_affix_ga_count = 0,
    ancestral_affix = {},
    ancestral_unique = {},
    ancestral_mythic = {},
    aggresive_movement = false,
    path_angle = 10,
    restock_items = {},
    stash_socketables = utils.stash_extra_enum['NEVER'],
    stash_consumables = utils.stash_extra_enum['NEVER'],
    stash_keys = utils.stash_extra_enum['NEVER'],
    max_inventory = 25,
}

function settings.get_keybind_state()
    local toggle_key = gui.elements.keybind_toggle:get_key();
    local toggle_state = gui.elements.keybind_toggle:get_state();

    -- If not using keybind, skip
    if not settings.use_keybind then
        return true
    end

    if settings.use_keybind and toggle_key ~= 0x0A and toggle_state == 1 then
        return true
    end
    return false
end

function settings.get_export_keybind_state()
    local toggle_key = gui.elements.export_keybind_toggle:get_key();
    local toggle_state = gui.elements.export_keybind_toggle:get_state();

    -- If not using keybind, skip
    if not settings.use_keybind then
        return true
    end

    if settings.use_keybind and toggle_key ~= 0x0A and toggle_state == 1 then
        return true
    end
    return false
end

function settings:update_settings()
    settings.enabled = gui.elements.main_toggle:get()
    settings.use_keybind = gui.elements.use_keybind:get()
    settings.item_legendary_or_lower = gui.elements.item_legendary_or_lower:get()
    settings.item_unique = gui.elements.item_unique:get()
    settings.item_junk = gui.elements.item_junk:get()
    settings.ancestral_item_legendary = gui.elements.ancestral_item_legendary:get()
    settings.ancestral_item_unique = gui.elements.ancestral_item_unique:get()
    settings.ancestral_item_mythic = gui.elements.ancestral_item_mythic:get()
    settings.ancestral_item_junk = gui.elements.ancestral_item_junk:get()
    settings.ancestral_keep_max_aspect = gui.elements.ancestral_keep_max_aspect:get()
    settings.ancestral_ga_count = gui.elements.ancestral_ga_count_slider:get()
    settings.ancestral_unique_ga_count = gui.elements.ancestral_unique_ga_count_slider:get()
    settings.ancestral_mythic_ga_count = gui.elements.ancestral_mythic_ga_count_slider:get()
    settings.ancestral_filter = gui.elements.ancestral_filter_toggle:get()
    settings.ancestral_unique_filter = gui.elements.ancestral_unique_filter_toggle:get()
    settings.ancestral_affix_count = gui.elements.ancestral_affix_count_slider:get()
    settings.ancestral_affix_ga_count = gui.elements.ancestral_affix_ga_count_slider:get()
    settings.path_angle = gui.elements.explorer_path_angle_slider:get()
    settings.ancestral_affix = {}
    for _,affix_type in pairs(affix_types) do
        settings.ancestral_affix[affix_type.name] = {}
        for _,affix in pairs(affix_type.data) do
            local checkbox_name = tostring(affix_type.name) .. '_affix_' .. tostring(affix.sno_id)
            if gui.elements[checkbox_name] and gui.elements[checkbox_name]:get() then
                settings.ancestral_affix[affix_type.name][affix.sno_id] = true
            end
        end
    end
    settings.ancestral_unique = {}
    for _,item in pairs(unique_items) do
        local checkbox_name = 'unique_' .. tostring(item.sno_id)
        if gui.elements[checkbox_name] and gui.elements[checkbox_name]:get() then
            settings.ancestral_unique[item.sno_id] = true
        end
    end
    settings.ancestral_mythic = {}
    for _,item in pairs(mythic_items) do
        local checkbox_name = 'mythic_' .. tostring(item.sno_id)
        if gui.elements[checkbox_name] and gui.elements[checkbox_name]:get() then
            settings.ancestral_mythic[item.sno_id] = true
        end
    end
    settings.restock_items = {}
    settings.stash_socketables = gui.elements.stash_socketables:get()
    settings.stash_consumables = gui.elements.stash_consumables:get()
    settings.stash_keys = gui.elements.stash_keys:get()
    for _,item in pairs(utils.get_restock_items()) do
        local sno_id = item.sno_id
        local slider_name = plugin_label .. 'restock_' .. tostring(sno_id)
        settings.restock_items[#settings.restock_items+1] = {
            sno_id = sno_id,
            name = item.name,
            max = gui.elements[slider_name]:get(),
            min = item.min
        }
    end
    settings.max_inventory = gui.elements.max_inventory:get()
end

utils.settings = settings
return settings