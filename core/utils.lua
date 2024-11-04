local utils    = {}
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
local item_types = {
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

for _,types in pairs(item_types) do
    get_affixes_and_aspect(types.name,types.data)
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

return utils