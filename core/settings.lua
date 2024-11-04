local gui = require 'gui'
local utils = require 'core.utils'
local affix_types = utils.get_item_affixes()

local settings = {
    enabled = false,
    use_keybind = false,
    item_use_stash = false,
    inventory_limit = 20,
    timeout = 120,
    -- item_magic = utils.item_enum['SALVAGE'],
    -- item_rare = utils.item_enum['SALVAGE'],
    -- item_legendary = utils.item_enum['SALVAGE'],
    item_legendary_or_lower = utils.item_enum['SALVAGE'],
    item_unique = utils.item_enum['SELL'],
    item_junk = utils.item_enum['SALVAGE'],
    ancestral_item_legendary = utils.item_enum['SALVAGE'],
    ancestral_item_unique = utils.item_enum['SELL'],
    ancestral_item_junk = utils.item_enum['SALVAGE'],
    ancestral_keep_max_aspect = true,
    ancestral_ga_count = 0,
    ancestral_filter = false,
    ancestral_affix_count = 0,
    ancestral_affix_ga_count = 0,
    ancestral_affix = {}
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

function settings:update_settings()
    settings.enabled = gui.elements.main_toggle:get()
    settings.use_keybind = gui.elements.use_keybind:get()
    settings.item_use_stash = gui.elements.stash_toggle:get()
    settings.inventory_limit = gui.elements.inventory_limit_slider:get()
    settings.timeout = gui.elements.timeout_slider:get()
    settings.item_legendary_or_lower = gui.elements.item_legendary_or_lower:get()
    settings.item_unique = gui.elements.item_unique:get()
    settings.item_junk = gui.elements.item_junk:get()
    settings.ancestral_item_legendary = gui.elements.ancestral_item_legendary:get()
    settings.ancestral_item_unique = gui.elements.ancestral_item_unique:get()
    settings.ancestral_item_junk = gui.elements.ancestral_item_junk:get()
    settings.ancestral_keep_max_aspect = gui.elements.ancestral_keep_max_aspect:get()
    settings.ancestral_ga_count = gui.elements.ancestral_ga_count_slider:get()
    settings.ancestral_filter = gui.elements.ancestral_filter_toggle:get()
    settings.ancestral_affix_count = gui.elements.ancestral_affix_count_slider:get()
    settings.ancestral_affix_ga_count = gui.elements.ancestral_affix_ga_count_slider:get()
    settings.ancestral_affix = {}
    for _,affix_type in pairs(affix_types) do
        for _,affix in pairs(affix_type) do
            local checkbox_name = tostring(name) .. '_affix_' .. tostring(affix.sno_id)
            if gui.elements[checkbox_name] and gui.elements[checkbox_name]:get() then
                settings.ancestral_affix[affix.sno_id] = true
            end
        end
    end
end
return settings