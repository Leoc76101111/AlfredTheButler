local utils    = {}
local item_types = {
    {name = "helm", data = require "data.affix.helm"},
    {name = "chest", data = require "data.affix.chest"},
    {name = "gloves", data = require "data.affix.gloves"},
    {name = "pants", data = require "data.affix.pants"},
    {name = "boots", data = require "data.affix.boots"},
    {name = "amulet", data = require "data.affix.amulet"},
    {name = "ring", data = require "data.affix.ring"},
    {name = "weapon", data = require "data.affix.weapon"},
    {name = "offhand", data = require "data.affix.offhand"},
    {name = "unique", data = require "data.affix.unique"},
}
local item_affix = {}
local item_aspect = {}

local function get_affixes_and_aspect(name,data)
    local affix_group = {
        name = name,
        data = {}
    }
    for _,affix in pairs(data) do
        if affix.is_aspect == false then
            affix_group.data[#affix_group.data+1] = affix
        else
            item_aspect[#item_aspect+1] = affix
        end
    end
    item_affix[#item_affix+1] = affix_group
end

local function get_plugin_root_path()
    local plugin_root = string.gmatch(package.path, '.*?\\?')()
    plugin_root = plugin_root:gsub("?","")
    return plugin_root
end

local function get_export_filename()
    local filename = get_plugin_root_path()
    filename = filename .. "\\data\\export\\alfred-"
    filename = filename .. os.time(os.date("!*t"))
    filename = filename .. ".lua"
    return filename
end

local function get_import_full_filename(name)
    local filename = get_plugin_root_path()
    filename = filename .. "\\data\\export\\"
    filename = filename .. name
    return filename
end

function utils.get_character_class()
    local local_player = get_local_player();
    local class_id = local_player:get_character_class_id()
    local character_classes = {
        [0] = "sorcerer",
        [1] = "barbarian",
        [3] = "rogue",
        [5] = "druid",
        [6] = "necromancer",
        [7] = "spiritborn"
    }
    if character_classes[class_id] then
        return character_classes[class_id]
    else
        return "default"
    end
end

function utils.get_item_affixes()
    return item_affix
end

function utils.get_item_aspects()
    return item_aspect
end

function utils.import_filters(name)
    return
end

function utils.export_filters(elements)
    local selected_affix = {}
    for _,affix_type in pairs(item_affix) do
        for _,affix in pairs(affix_type.data) do
            local checkbox_name = tostring(affix_type.name) .. '_affix_' .. tostring(affix.sno_id)
            if elements[checkbox_name]:get() then
                selected_affix[#selected_affix+1] = checkbox_name
            end
        end
    end
    local filename = get_export_filename()
    local file, err = io.open(filename,"w")
    if not file then
        console.print("error opening file")
    end
    file:write("local affix = {\n")
    for _,affix in pairs(selected_affix) do
        file:write('"')
        file:write(affix)
        file:write('",\n')
    end
    file:write("}\nreturn affix")
    file:close()
    
    console.print('export ' .. filename .. ' done')
    return
end

for _,types in pairs(item_types) do
    get_affixes_and_aspect(types.name,types.data)
end

return utils