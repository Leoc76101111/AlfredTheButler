local plugin_label = 'alfred_the_butler'
local json = require 'core.json'
local tracker = require 'core.tracker'
local utils    = {}
local item_types = {
    'helm',
    'chest',
    'gloves',
    'pants',
    'boots',
    'amulet',
    'ring',
    'weapon',
    'offhand',
    'unique',
}
local item_affix = {}
local item_aspect = {}

utils.item_enum = {
    KEEP = 0,
    SALVAGE = 1,
    SELL = 2
}

utils.mythics = {}
utils.mythics['1901484'] = "Tyrael's Might"
utils.mythics['223271'] = 'The Grandfather'
utils.mythics['241930'] = "Andariel's Visage"
utils.mythics['359165'] = 'Ahavarion, Spear of Lycander'
utils.mythics['221017'] = 'Doombringer'
utils.mythics['609820'] = 'Harlequin Crest'
utils.mythics['1275935'] = 'Melted Heart of Selig'
utils.mythics['1306338'] = '‍Ring of Starless Skies'
utils.mythics['2059803'] = 'Shroud of False Death'
utils.mythics['1982241'] = 'Nesekem, the Herald'
utils.mythics['2059799'] = 'Heir of Perdition'
utils.mythics['2059813'] = 'Shattered Vow'

local function get_plugin_root_path()
    local plugin_root = string.gmatch(package.path, '.*?\\?')()
    plugin_root = plugin_root:gsub('?','')
    return plugin_root
end

local function get_affixes_and_aspect(name)
    local filename = get_plugin_root_path()
    filename = filename .. 'data\\affix\\' .. name .. '.json'
    local file, err = io.open(filename,'r')
    if not file then
        utils.log('error opening file' .. filename)
        return
    end
    io.input(file)
    local data = json.decode(io.read())
    io.close(file)
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


local function get_export_filename(is_backup)
    local filename = get_plugin_root_path()
    filename = filename .. 'data\\export'
    if is_backup then
        filename = filename .. '\\alfred-backup-'
    else
        filename = filename .. '\\alfred-'
    end        
    filename = filename .. os.time(os.date('!*t'))
    filename = filename .. '.json'
    return filename
end

local function get_import_full_filename(name)
    local filename = get_plugin_root_path()
    filename = filename .. 'data\\import\\'
    filename = filename .. name
    return filename
end

function utils.get_character_class()
    local local_player = get_local_player();
    local class_id = local_player:get_character_class_id()
    local character_classes = {
        [0] = 'sorcerer',
        [1] = 'barbarian',
        [3] = 'rogue',
        [5] = 'druid',
        [6] = 'necromancer',
        [7] = 'spiritborn'
    }
    if character_classes[class_id] then
        return character_classes[class_id]
    else
        return 'default'
    end
end

function utils.get_item_affixes()
    return item_affix
end

function utils.get_item_aspects()
    return item_aspect
end

function utils.import_filters(elements)
    local filename = get_import_full_filename(elements.affix_import_name:get())
    local file, err = io.open(filename,'r')
    if not file then
        utils.log('error opening file' .. filename)
        return
    end
    io.input(file)
    local data = io.read()
    if pcall(function () return json.decode(data) end) then
        local new_affix = json.decode(data)
        local new_affix_set = {}
        for _,affix in pairs(new_affix) do
            new_affix_set[affix] = true
        end
        -- make a backup
        utils.export_filters(elements,true)

        -- clear and set new affix
        for _,affix_type in pairs(item_affix) do
            for _,affix in pairs(affix_type.data) do
                local checkbox_name = tostring(affix_type.name) .. '_affix_' .. tostring(affix.sno_id)
                if new_affix_set[checkbox_name] then
                    elements[checkbox_name]:set(true)
                else
                    elements[checkbox_name]:set(false)
                end
            end
        end
    else
        utils.log('error in import file' .. filename)
    end
    io.close(file)
    utils.log('export ' .. filename .. ' done')
    return
end

function utils.export_filters(elements,is_backup)
    local selected_affix = {}
    for _,affix_type in pairs(item_affix) do
        for _,affix in pairs(affix_type.data) do
            local checkbox_name = tostring(affix_type.name) .. '_affix_' .. tostring(affix.sno_id)
            if elements[checkbox_name]:get() then
                selected_affix[#selected_affix+1] = checkbox_name
            end
        end
    end
    local filename = get_export_filename(is_backup)
    local file, err = io.open(filename,'w')
    if not file then
        utils.log('error opening file' .. filename)
    end
    io.output(file)
    io.write(json.encode(selected_affix))
    io.close(file)
    
    utils.log('export ' .. filename .. ' done')
    return
end

function utils.log(msg)
    console.print(plugin_label .. ': ' .. tostring(msg))
    return
end

function utils.get_greater_affix_count(display_name)
    local count = 0
    for _ in display_name:gmatch('GreaterAffix') do
       count = count + 1
    end
    return count
end

function utils.update_tracker_count(settings)
    local counter = 0
    local salvage_counter = 0
    local sell_counter = 0
    local stash_counter = 0
    local local_player = get_local_player()
    if not local_player then return end
    local items = local_player:get_inventory_items()
    for _, item in pairs(items) do
        if item then
            counter = counter + 1
            local display_name = item:get_display_name()
            local greater_affix_count = utils.get_greater_affix_count(display_name)
            local item_id = item:get_sno_id()
            local is_unique = false
            local item_settings
            
            if item:get_rarity() == 6 then
                is_unique = true
            end

            if item:is_locked() or utils.mythics[item_id] ~= nil then
                item_settings = utils.item_enum['KEEP']
            elseif greater_affix_count > 0 then
                if item:is_junk() then
                    item_settings = settings.ancestral_item_junk
                elseif is_unique then
                    item_settings = settings.ancestral_item_unique
                else
                    item_settings = settings.ancestral_item_legendary
                end
            else
                if item:is_junk() then
                    item_settings = settings.item_junk
                elseif is_unique then
                    item_settings = settings.item_unique
                else
                    item_settings = settings.item_legendary_or_lower
                end
            end

            if item_settings == utils.item_enum['SELL'] then
                sell_counter = sell_counter + 1
            elseif item_settings == utils.item_enum['SALVAGE'] then
                salvage_counter = salvage_counter + 1
            else
                stash_counter = stash_counter + 1
            end
        else
            utils.log('no item??')
        end
    end
    tracker.inventory_count = counter
    tracker.salvage_count = salvage_counter
    tracker.sell_count = sell_counter
    tracker.stash_count = stash_counter
    tracker.inventory_limit = settings.inventory_limit
end

function utils.player_in_zone(zname)
    return get_current_world():get_current_zone_name() == zname
end

function utils.get_blacksmith()

end

function utils.get_vendor()

end

function utils.distance_to()

end

for _,types in pairs(item_types) do
    get_affixes_and_aspect(types)
end

return utils