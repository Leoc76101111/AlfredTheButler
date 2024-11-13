local plugin_label = 'alfred_the_butler'

local json = require 'core.json'
local tracker = require 'core.tracker'

local utils    = {
    settings = {},
    last_dump_time = 0,
}
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
}
local item_affix = {}
local item_aspect = {}
local item_unique = {}
local item_restock = {
    {sno_id = 1866012, name = 'Horde Compass', item_type = 'key', max = 33, min = 1},
    {sno_id = 1489420, name = 'Malignant Heart', item_type = 'consumables', max = 1650, min = 4},
    {sno_id = 1502128, name = 'Living Steel', item_type = 'consumables', max = 1650, min = 12},
    {sno_id = 1518053, name = 'Distilled Fear', item_type = 'consumables', max = 1650, min = 12},
    {sno_id = 1522891, name = 'Exquisite Blood', item_type = 'consumables', max = 1650, min = 12},
    {sno_id = 1524917, name = 'Mucus-Slick Egg', item_type = 'consumables', max = 850, min = 2},
    {sno_id = 1524924, name = 'Shard of Agony', item_type = 'consumables', max = 850, min = 2},
    {sno_id = 1810144, name = 'Sandscorched Shackles', item_type = 'consumables', max = 850, min = 2},
    {sno_id = 1812685, name = 'Pincushioned Doll', item_type = 'consumables', max = 850, min = 2},
}
local item_restock_by_id = {}
for _,item in pairs(item_restock) do
    item_restock_by_id[item.sno_id] = item
end
utils.npc_enum = {
    BLACKSMITH = 'TWN_Scos_Cerrigar_Crafter_Blacksmith',
    SILVERSMITH = 'TWN_Scos_Cerrigar_Vendor_Silversmith',
    WEAPON = 'TWN_Scos_Cerrigar_Vendor_Weapons',
    STASH = 'Stash',
    GAMBLER = 'TWN_Scos_Cerrigar_Vendor_Gambler',
    ALCHEMIST = 'TWN_Scos_Cerrigar_Crafter_Alchemist',
    HEALER = 'TWN_Scos_Cerrigar_Service_Healer',
    PORTAL = 'TownPortal',
}
utils.npc_loc_enum = {
    BLACKSMITH = vec3:new(-1685.359375, -596.5830078125, 37.8603515625),
    SILVERSMITH = vec3:new(-1676.4697265625, -581.1435546875, 37.861328125),
    WEAPON = vec3:new(-1658.69921875, -620.0205078125, 37.888671875),
    STASH = vec3:new(-1684.1199951172, -592.11602783203, 37.606800079346),
    GAMBLER = vec3:new(-1675.5791015625, -599.30859375, 36.9267578125),
    ALCHEMIST = vec3:new(-1671.6494140625, -607.0947265625, 37.7255859375),
    HEALER = vec3:new(-1671.0791015625, -600.92578125, 36.9130859375),
    PORTAL = vec3:new(-1656.7141113281, -598.21716308594, 36.28515625)
}
utils.item_enum = {
    KEEP = 0,
    SALVAGE = 1,
    SELL = 2
}
utils.restock_enum = {
    ACTIVE = 0,
    PASSIVE = 1
}

utils.mythics = {
    ['1901484'] = "Tyrael's Might",
    ['223271'] = 'The Grandfather',
    ['241930'] = "Andariel's Visage",
    ['359165'] = 'Ahavarion, Spear of Lycander',
    ['221017'] = 'Doombringer',
    ['609820'] = 'Harlequin Crest',
    ['1275935'] = 'Melted Heart of Selig',
    ['1306338'] = '‍Ring of Starless Skies',
    ['2059803'] = 'Shroud of False Death',
    ['1982241'] = 'Nesekem, the Herald',
    ['2059799'] = 'Heir of Perdition',
    ['2059813'] = 'Shattered Vow',
}

local function get_plugin_root_path()
    local plugin_root = string.gmatch(package.path, '.*?\\?')()
    plugin_root = plugin_root:gsub('?','')
    return plugin_root
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
        if affix.is_aspect then
            item_aspect[affix.sno_id] = affix.name
        else
            affix_group.data[#affix_group.data+1] = affix
        end
    end
    item_affix[#item_affix+1] = affix_group
end
local function get_uniques()
    local filename = get_plugin_root_path()
    filename = filename .. 'data\\affix\\unique.json'
    local file, err = io.open(filename,'r')
    if not file then
        utils.log('error opening file' .. filename)
        return
    end
    io.input(file)
    local data = json.decode(io.read())
    io.close(file)
    for _,item in pairs(data) do
        item_unique[#item_unique+1] = item
    end
end
function utils.get_item_affixes()
    return item_affix
end
function utils.get_item_aspects()
    return item_aspect
end
function utils.get_unique_items()
    return item_unique
end
function utils.get_restock_items()
    return item_restock
end

function utils.log(msg)
    console.print(plugin_label .. ': ' .. tostring(msg))
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

function utils.player_in_zone(zname)
    return get_current_world():get_current_zone_name() == zname
end
function utils.reset_all_task()
    local previous = {}
    for key,data in pairs(tracker) do
        if key == 'previous' then
        elseif key == 'restock_items' then
            previous[key] = {}
            for key2,data2 in pairs(data) do
                previous[key][key2] = {}
                for key3,data3 in pairs(data2) do
                    previous[key][key2][key3] = data3
                end
            end
        else
            previous[key] = data
        end
    end
    tracker.previous = previous
    tracker.last_reset = 0
    tracker.timeout = false
    tracker.teleport = false
    tracker.teleport_done = false
    tracker.teleport_failed = false
    tracker.sell_failed = false
    tracker.sell_done = false
    tracker.salvage_failed = false
    tracker.salvage_done = false
    tracker.repair_failed = false
    tracker.repair_done = false
    tracker.stash_failed = false
    tracker.stash_done = false
    tracker.restock_failed = false
    tracker.restock_done = false
    tracker.all_task_done = false
end

function utils.get_npc(name)
    local actors = actors_manager:get_all_actors()
    for _, actor in pairs(actors) do
        local actor_name = actor:get_skin_name()
        if actor_name == name then
            return actor
        end
    end
    return nil
end
function utils.get_npc_location(name)
    return utils.npc_loc_enum[name]
end
function utils.distance_to(target)
    local player_pos = get_player_position()
    local target_pos

    if target.get_position then
        target_pos = target:get_position()
    elseif target.x then
        target_pos = target
    end

    return player_pos:dist_to(target_pos)
end
function utils.is_same_position(pos1, pos2)
    return pos1:x() == pos2:x() and pos1:y() == pos2:y() and pos1:z() == pos2:z()
end

function utils.get_greater_affix_count(display_name)
    local count = 0
    for _ in display_name:gmatch('GreaterAffix') do
       count = count + 1
    end
    return count
end
function utils.is_max_aspect(affix)
    local affix_id = affix.affix_name_hash
    if item_aspect[affix_id] then
        -- if ascending
        if affix:get_roll_max() > affix:get_roll_min() then
            -- simple direct comparison
            if affix:get_roll() == affix:get_roll_max() then return true end

            -- dealing with int value of max_roll
            if affix:get_roll_max() == math.floor(affix:get_roll_max()) then
                -- 0.5 for rounding instead of floor
                return math.floor(affix:get_roll() + 0.5) >= affix:get_roll_max()
            end

            -- dealing with decimals up to 2 places
            return math.floor((affix:get_roll() * 100) + 0.5) >= affix:get_roll_max() * 100
        else
            -- simple direct comparison
            if affix:get_roll() == affix:get_roll_min() then return true end

            -- dealing with int value of min_roll
            if affix:get_roll_min() == math.floor(affix:get_roll_min()) then
                -- 0.5 for rounding instead of floor
                return math.floor(affix:get_roll() + 0.5) <= affix:get_roll_min()
            end
            -- dealing with decimals up to 2 places
            return math.floor((affix:get_roll() * 100) + 0.5) <= affix:get_roll_min() * 100
        end

    end
    return false
end
function utils.is_correct_unique(item)
    local item_id = item:get_sno_id()
    return utils.settings.ancestral_unique[item_id]
end
function utils.is_correct_affix(item_type,affix)
    local affix_id = affix.affix_name_hash
    return utils.settings.ancestral_affix[item_type][affix_id]
end
function utils.get_item_type(item)
    local name = string.lower(item:get_name())
    local offhand = {
        'focus',
        'book',
        'totem',
        'shield'
    }
    local weapon = {
        '2h',
        '1h',
        'quarterstaff',
        'glaive'
    }
    if name:match('cache') then
        return 'cache'
    end
    for _,types in pairs(item_types) do
        if name:match(types) then
            return types
        end
    end
    for _,types in pairs(offhand) do
        if name:match(types) then
            return 'offhand'
        end
    end
    for _,types in pairs(weapon) do
        if name:match(types) then
            return 'weapon'
        end
    end
    return 'unknown'
end
function utils.is_salvage_or_sell(item,action)
    local item_id = item:get_sno_id()
    if item:is_locked() then return false end

    local item_type = utils.get_item_type(item)
    if item_type == 'cache' then return false end
    if item_type == 'unknown' then return false end

    local display_name = item:get_display_name()
    local ancestral_ga_count = utils.get_greater_affix_count(display_name)

    local is_unique = false
    if item:get_rarity() == 6 then
        is_unique = true
    end
    -- non ancestral
    if ancestral_ga_count <= 0 then
        if item:is_junk() and utils.settings.item_junk == action then
            return true
        elseif is_unique and utils.settings.item_unique == action then
            return true
        elseif not item:is_junk() and not is_unique and
            utils.settings.item_legendary_or_lower == action 
        then
            return true
        else
            return false
        end
    end

    -- ancestral 
    if item:is_junk() and utils.settings.ancestral_item_junk == action then
        return true
    end
    local item_affixes = item:get_affixes()
    local ancestral_affix_count = 0
    local ancestral_affix_ga_count = 0
    for _,affix in pairs(item_affixes) do
        if utils.settings.ancestral_keep_max_aspect and utils.is_max_aspect(affix) then
            return false
        end
        if item_type == 'unknown' then
            for _,types in pairs(item_types) do
                if utils.is_correct_affix(types,affix) then
                    ancestral_affix_count = ancestral_affix_count + 1
                    -- to do matching ga, might need some data collection
                end
            end
        else
            if utils.is_correct_affix(item_type,affix) then
                ancestral_affix_count = ancestral_affix_count + 1
                -- to do matching ga, might need some data collection
            end
        end
    end
    
    -- legendaries (not junk, not unique, not mythic)
    if not item:is_junk() and not is_unique and utils.mythics[tostring(item_id)] == nil and
        utils.settings.ancestral_item_legendary == action and
        (ancestral_ga_count < utils.settings.ancestral_ga_count or
        (utils.settings.ancestral_filter and
        ancestral_affix_count < utils.settings.ancestral_affix_count))
    then
        return true
    end
    -- uniques (not junk, is unique, not mythic)
    if not item:is_junk() and is_unique and utils.mythics[tostring(item_id)] == nil and
        utils.settings.ancestral_item_unique == action and
        (ancestral_ga_count < utils.settings.ancestral_unique_ga_count or
        (utils.settings.ancestral_filter and not utils.is_correct_unique(item)))
    then
        return true
    end
    -- mythics (not junk, not unique, is mythic)
    if not item:is_junk() and not is_unique and utils.mythics[tostring(item_id)] ~= nil and
        utils.settings.ancestral_item_mythic == action and
        ancestral_ga_count < utils.settings.ancestral_mythic_ga_count
    then
        return true
    end
    return false
end
function utils.get_restock_item_count(local_player,item)
    local counter = 0
    if item_restock_by_id[item.sno_id].item_type == 'key' then
        local key_items = local_player:get_dungeon_key_items()
        for _,key_item in pairs(key_items) do
            local item_count = key_item:get_stack_count()
            if item_count == 0 then
                item_count = 1
            end
            if key_item:get_sno_id() == item.sno_id then
                counter = counter + item_count
            end
        end
    elseif item_restock_by_id[item.sno_id].item_type == 'consumables' then
        local key_items = local_player:get_consumable_items()
        for _,key_item in pairs(key_items) do
            local item_count = key_item:get_stack_count()
            if item_count == 0 then
                item_count = 1
            end
            if key_item:get_sno_id() == item.sno_id then
                counter = counter + item_count
            end
        end
    end
    return counter
end
function utils.update_tracker_count()
    local salvage_counter = 0
    local sell_counter = 0
    local stash_counter = 0
    local local_player = get_local_player()
    if not local_player then return end
    local items = local_player:get_inventory_items()
    for _, item in pairs(items) do
        if item then
            if utils.is_salvage_or_sell(item,utils.item_enum['SALVAGE']) then
                salvage_counter = salvage_counter + 1
            elseif utils.is_salvage_or_sell(item,utils.item_enum['SELL']) then
                sell_counter = sell_counter + 1
            else
                stash_counter = stash_counter + 1
            end
        else
            utils.log('no item??')
        end
    end
    tracker.inventory_count = local_player:get_item_count()
    tracker.salvage_count = salvage_counter
    tracker.sell_count = sell_counter
    tracker.stash_count = stash_counter
    tracker.inventory_full = tracker.inventory_count == 33

    -- clean up tracker
    if #utils.settings.restock_items ~= #tracker.restock_items then
        local new_tracker_item = {}
        for _,tracker_item in pairs(tracker.restock_items) do
            for _,item in pairs(utils.settings.restock_items) do
                if item.sno_id == tracker_item.sno_id then
                    new_tracker_item[#new_tracker_item+1] = tracker_item
                end
            end
        end
        tracker.restock_items = new_tracker_item
    end
    tracker.restock_count = 0
    if #utils.settings.restock_items ~= 0 then
        for key,item in pairs(utils.settings.restock_items) do
            local counter = utils.get_restock_item_count(local_player,item)
            local stash_count = 9999
            if tracker.restock_items[key] and tracker.restock_items[key].stash >= 0 then
                stash_count = tracker.restock_items[key].stash
            end
            tracker.restock_items[key] = {
                sno_id = item.sno_id,
                name = item.name,
                min = item.min,
                max = item.max,
                item_type = item_restock_by_id[item.sno_id].item_type,
                count = counter,
                stash = stash_count
            }
            if counter < item.min then
                tracker.restock_count = tracker.restock_count +1
            end
        end
    else
        tracker.restock_items = {}
    end
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
        for _,affix in pairs(item_unique) do
            local checkbox_name = 'unique_affix_' .. tostring(affix.sno_id)
            if new_affix_set[checkbox_name] then
                elements[checkbox_name]:set(true)
            else
                elements[checkbox_name]:set(false)
            end
        end
    else
        utils.log('error in import file' .. filename)
    end
    io.close(file)
    utils.log('export ' .. filename .. ' done')
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
    for _,affix in pairs(item_unique) do
        local checkbox_name = 'unique_affix_' .. tostring(affix.sno_id)
        if elements[checkbox_name]:get() then
            selected_affix[#selected_affix+1] = checkbox_name
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
end
function utils.export_actors()
    -- debounce second
    local current_time = get_time_since_inject()
    if utils.last_dump_time + 1 >= current_time then return end

    local actors = actors_manager:get_all_actors()
    local data = {}
    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        local position = actor:get_position()
        data[#data+1] = {
            ['name'] = name,
            ['x'] = position:x(),
            ['y'] = position:y(),
            ['z'] = position:z()
        }
    end
    local filename = get_plugin_root_path()
    filename = filename .. 'data\\export'
    filename = filename .. '\\actors-'
    filename = filename .. os.time(os.date('!*t'))
    filename = filename .. '.json'
    local file, err = io.open(filename,'w')
    if not file then
        utils.log('error opening file' .. filename)
    end
    io.output(file)
    io.write(json.encode(data))
    io.close(file)
    utils.last_dump_time = current_time
end
function utils.export_inventory_info()
    -- debounce 10 seconds
    local current_time = get_time_since_inject()
    if utils.last_dump_time + 10 >= current_time then return end
    utils.last_dump_time = current_time
    local local_player = get_local_player()
    if not local_player then return end
    local items = local_player:get_inventory_items()
    local items_info = {}
    for _, item in pairs(items) do
        local item_info = {}
        if item then
            item_info['name'] = item:get_display_name()
            item_info['id'] = item:get_sno_id()
            item_info['type'] = utils.get_item_type(item)
            item_info['affix'] = {}
            item_info['aspect'] = {}
            for _,affix in pairs(item:get_affixes()) do
                local affix_id = affix.affix_name_hash
                if item_aspect[affix_id] then
                    item_info['aspect']['id'] = affix_id
                    item_info['aspect']['name'] = affix:get_name()
                    item_info['aspect']['roll'] = affix:get_roll()
                    item_info['aspect']['max_roll'] = affix:get_roll_max()
                    item_info['aspect']['min_roll'] = affix:get_roll_min()
                    item_info['aspect']['is_max'] = utils.is_max_aspect(affix)
                else
                    item_info['affix'][#item_info['affix']+1] = {
                        ['id'] = affix_id,
                        ['name'] = affix:get_name(),
                        ['roll'] = affix:get_roll(),
                        ['max_roll'] = affix:get_roll_max(),
                        ['min_roll'] = affix:get_roll_min()
                    }
                end
            end
        end
        items_info[#items_info+1] = item_info
    end
    local filename = get_plugin_root_path()
    filename = filename .. 'data\\export'
    filename = filename .. '\\items-'
    filename = filename .. os.time(os.date('!*t'))
    filename = filename .. '.json'
    local file, err = io.open(filename,'w')
    if not file then
        utils.log('error opening file' .. filename)
    end
    io.output(file)
    io.write(json.encode(items_info))
    io.close(file)
end
function utils.dump_tracker_info(tracker_data)
    if tracker_data.previous then
        utils.log('----------')
        utils.log('previous:')
        utils.dump_tracker_info(tracker_data.previous)
        utils.log('----------')
        utils.log('current:')
    end
    for key,data in pairs(tracker_data) do
        if key == 'previous' then
        elseif key == 'restock_items' then
            utils.log(key)
            for key2,data2 in pairs(data) do
                for key3,data3 in pairs(data2) do
                    utils.log(key .. '>' .. key2 .. '>' .. key3 .. ':' .. tostring(data3))
                end
            end
        else
            utils.log(key .. ':' .. tostring(data))
        end
    end
end

for _,types in pairs(item_types) do
    get_affixes_and_aspect(types)
end
get_uniques()

return utils