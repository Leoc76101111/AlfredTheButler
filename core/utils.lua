local utils    = {}

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

return utils