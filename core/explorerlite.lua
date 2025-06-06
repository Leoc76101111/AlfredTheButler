local MinHeap = {}
MinHeap.__index = MinHeap

function MinHeap.new(compare)
    --console.print("Creating new MinHeap.")
    return setmetatable({heap = {}, compare = compare or function(a, b) return a < b end}, MinHeap)
end

function MinHeap:push(value)
    --console.print("Pushing value into MinHeap.")
    table.insert(self.heap, value)
    self:siftUp(#self.heap)
end

function MinHeap:pop()
    --console.print("Popping value from MinHeap.")
    local root = self.heap[1]
    self.heap[1] = self.heap[#self.heap]
    table.remove(self.heap)
    self:siftDown(1)
    return root
end

function MinHeap:peek()
    --console.print("Peeking value from MinHeap.")
    return self.heap[1]
end

function MinHeap:empty()
    --console.print("Checking if MinHeap is empty.")
    return #self.heap == 0
end

function MinHeap:siftUp(index)
    --console.print("Sifting up in MinHeap.")
    local parent = math.floor(index / 2)
    while index > 1 and self.compare(self.heap[index], self.heap[parent]) do
        self.heap[index], self.heap[parent] = self.heap[parent], self.heap[index]
        index = parent
        parent = math.floor(index / 2)
    end
end

function MinHeap:siftDown(index)
    --console.print("Sifting down in MinHeap.")
    local size = #self.heap
    while true do
        local smallest = index
        local left = 2 * index
        local right = 2 * index + 1
        if left <= size and self.compare(self.heap[left], self.heap[smallest]) then
            smallest = left
        end
        if right <= size and self.compare(self.heap[right], self.heap[smallest]) then
            smallest = right
        end
        if smallest == index then break end
        self.heap[index], self.heap[smallest] = self.heap[smallest], self.heap[index]
        index = smallest
    end
end

function MinHeap:contains(value)
    --console.print("Checking if MinHeap contains value.")
    for _, v in ipairs(self.heap) do
        if v == value then return true end
    end
    return false
end

local utils = require "core.utils"
local settings = require "core.settings"
local explorerlite = {
    enabled = false,
    is_task_running = false, --added to prevent boss dead pathing 
}
local target_position = nil
local grid_size = 2            -- Size of grid cells in meters
local max_target_distance = 120 -- Maximum distance for a new target
local target_distance_states = {120, 40, 20, 5}
local target_distance_index = 1
local unstuck_target_distance = 15 -- Maximum distance for an unstuck target
local stuck_threshold = 2      -- Seconds before the character is considered "stuck"
local last_position = nil
local last_move_time = 0
local stuck_check_interval = 60  -- Check every 2 seconds
local stuck_distance_threshold = 0.5  -- Consider stuck if moved less than 0.5 units
local last_stuck_check_time = 0
local last_stuck_check_position = nil
local original_target = nil

-- A* pathfinding variables
local current_path = {}
local path_index = 1

-- Neue Variable für die letzte Bewegungsrichtung
local last_movement_direction = nil

--ai fix for kill monsters path
function explorerlite:clear_path_and_target()
    console.print("Clearing path and target.")
    target_position = nil
    current_path = {}
    path_index = 1
end

local function calculate_distance(point1, point2)
    --console.print("Calculating distance between points.")
    if not point2.x and point2 then
        return point1:dist_to_ignore_z(point2:get_position())
    end
    return point1:dist_to_ignore_z(point2)
end



--ai fix for stairs
local function set_height_of_valid_position(point)
    --console.print("Setting height of valid position.")
    return utility.set_height_of_valid_position(point)
end

local function get_grid_key(point)
    --console.print("Getting grid key.")
    return math.floor(point:x() / grid_size) .. "," ..
        math.floor(point:y() / grid_size) .. "," ..
        math.floor(point:z() / grid_size)
end

local explored_area_bounds = {
    min_x = math.huge,
    max_x = -math.huge,
    min_y = math.huge,
    max_y = -math.huge,
    min_z = math.huge,
    max_z = math.huge
}

local function is_point_in_explored_area(point)
    --console.print("Checking if point is in explored area.")
    return point:x() >= explored_area_bounds.min_x and point:x() <= explored_area_bounds.max_x and
        point:y() >= explored_area_bounds.min_y and point:y() <= explored_area_bounds.max_y and
        point:z() >= explored_area_bounds.min_z and point:z() <= explored_area_bounds.max_z
end


local function find_unstuck_target()
    console.print("Finding unstuck target.")
    local player_pos = get_player_position()
    local valid_targets = {}

    for x = -unstuck_target_distance, unstuck_target_distance, grid_size do
        for y = -unstuck_target_distance, unstuck_target_distance, grid_size do
            local point = vec3:new(
                player_pos:x() + x,
                player_pos:y() + y,
                player_pos:z()
            )
            point = set_height_of_valid_position(point)

            local distance = calculate_distance(player_pos, point)
            if utility.is_point_walkeable(point) and distance >= 2 and distance <= unstuck_target_distance then
                table.insert(valid_targets, point)
            end
        end
    end

    if #valid_targets > 0 then
        return valid_targets[math.random(#valid_targets)]
    end

    return nil
end

explorerlite.find_unstuck_target = find_unstuck_target


local function handle_stuck_player()
    local current_time = os.time()
    local player_pos = get_player_position()

    if not last_stuck_check_position then
        last_stuck_check_position = player_pos
        last_stuck_check_time = current_time
        return false
    end

    if current_time - last_stuck_check_time >= stuck_check_interval then
        local distance_moved = calculate_distance(player_pos, last_stuck_check_position)

        if distance_moved < stuck_distance_threshold then
            console.print("Player appears to be stuck. Finding temporary target.")
            original_target = target_position
            local temp_target = find_unstuck_target()
            if temp_target then
                target_position = temp_target
                --console.print("Temporary target set: " .. tostring(temp_target))

            else
                console.print("Failed to find temporary target.")
            end
            return true
        elseif original_target and distance_moved >= stuck_distance_threshold * 2 then
            console.print("Player has moved. Returning to original target.")
            target_position = original_target
            original_target = nil
        end

        last_stuck_check_position = player_pos
        last_stuck_check_time = current_time
    end

    return false
end

local function check_walkable_area()
    --console.print("Checking walkable area.")
    if os.time() % 1 ~= 0 then return end  -- Only run every 5 seconds

    local player_pos = get_player_position()
    local check_radius = 15 -- Überprüfungsradius in Metern

    for x = -check_radius, check_radius, grid_size do
        for y = -check_radius, check_radius, grid_size do
            for z = -check_radius, check_radius, grid_size do -- Inclui z no loop
                local point = vec3:new(
                    player_pos:x() + x,
                    player_pos:y() + y,
                    player_pos:z() + z
                )
                print("Checking point:", point:x(), point:y(), point:z()) -- Debug print
                point = set_height_of_valid_position(point)

                if utility.is_point_walkeable(point) then
                    if is_point_in_explored_area(point) then
                        --graphics.text_3d("Explored", point, 15, color_white(128))
                    else
                        --graphics.text_3d("unexplored", point, 15, color_green(255))
                    end
                end
            end
        end
    end
end

function explorerlite:reset_exploration()
    --console.print("Resetting exploration.")
    explored_area_bounds = {
        min_x = math.huge,
        max_x = -math.huge,
        min_y = math.huge,
        max_y = -math.huge,
    }
    target_position = nil
    last_position = nil
    last_move_time = 0
    current_path = {}
    path_index = 1
    exploration_mode = "unexplored"
    last_movement_direction = nil

    console.print("Exploration reset. All areas marked as unexplored.")
end

function vec3.__add(v1, v2)
    --console.print("Adding two vectors.")
    return vec3:new(v1:x() + v2:x(), v1:y() + v2:y(), v1:z() + v2:z())
end

-- A* pathfinding functions
local function heuristic(a, b)
    --console.print("Calculating heuristic.")
    return calculate_distance(a, b)
end

local function get_neighbors(point)
    --console.print("Getting neighbors of point.")
    local neighbors = {}
    local directions = {
        { x = 1, y = 0 }, { x = -1, y = 0 }, { x = 0, y = 1 }, { x = 0, y = -1 },
        { x = 1, y = 1 }, { x = 1, y = -1 }, { x = -1, y = 1 }, { x = -1, y = -1 }
    }
    for _, dir in ipairs(directions) do
        local neighbor = vec3:new(
            point:x() + dir.x * grid_size,
            point:y() + dir.y * grid_size,
            point:z()
        )
        neighbor = set_height_of_valid_position(neighbor)
        if utility.is_point_walkeable(neighbor) then
            if not last_movement_direction or
                (dir.x ~= -last_movement_direction.x or dir.y ~= -last_movement_direction.y) then
                table.insert(neighbors, neighbor)
            end
        end
    end

    if #neighbors == 0 and last_movement_direction then
        local back_direction = vec3:new(
            point:x() - last_movement_direction.x * grid_size,
            point:y() - last_movement_direction.y * grid_size,
            point:z()
        )
        back_direction = set_height_of_valid_position(back_direction)
        if utility.is_point_walkeable(back_direction) then
            table.insert(neighbors, back_direction)
        end
    end

    return neighbors
end

local function reconstruct_path(came_from, current)
    local path = { current }
    while came_from[get_grid_key(current)] do
        current = came_from[get_grid_key(current)]
        table.insert(path, 1, current)
    end

    -- Filter points with a less aggressive approach
    local filtered_path = { path[1] }
    for i = 2, #path - 1 do
        local prev = path[i - 1]
        local curr = path[i]
        local next = path[i + 1]

        local dir1 = { x = curr:x() - prev:x(), y = curr:y() - prev:y() }
        local dir2 = { x = next:x() - curr:x(), y = next:y() - curr:y() }

        -- Calculate the angle between directions
        local dot_product = dir1.x * dir2.x + dir1.y * dir2.y
        local magnitude1 = math.sqrt(dir1.x^2 + dir1.y^2)
        local magnitude2 = math.sqrt(dir2.x^2 + dir2.y^2)
        local angle = math.acos(dot_product / (magnitude1 * magnitude2))

        -- Use the angle from settings, converting degrees to radians
        local angle_threshold = math.rad(settings.path_angle)

        -- Keep points if the angle is greater than the threshold from settings
        if angle > angle_threshold then
            table.insert(filtered_path, curr)
        end
    end
    table.insert(filtered_path, path[#path])

    return filtered_path
end

local function a_star(start, goal)
    --console.print("Starting A* pathfinding.")
    local closed_set = {}
    local came_from = {}
    local g_score = { [get_grid_key(start)] = 0 }
    local f_score = { [get_grid_key(start)] = heuristic(start, goal) }
    local iterations = 0

    local open_set = MinHeap.new(function(a, b)
        return f_score[get_grid_key(a)] < f_score[get_grid_key(b)] -- Does that work?
    end)
    open_set:push(start)

    while not open_set:empty() do
        iterations = iterations + 1
        if iterations > 6666 then
            console.print("Max iterations reached, aborting!")
            break
        end

        local current = open_set:pop()
        if calculate_distance(current, goal) < grid_size then
            max_target_distance = target_distance_states[1]
            target_distance_index = 1
            return reconstruct_path(came_from, current)
        end

        closed_set[get_grid_key(current)] = true

        for _, neighbor in ipairs(get_neighbors(current)) do
            if not closed_set[get_grid_key(neighbor)] then
                local tentative_g_score = g_score[get_grid_key(current)] + calculate_distance(current, neighbor)

                if not g_score[get_grid_key(neighbor)] or tentative_g_score < g_score[get_grid_key(neighbor)] then
                    came_from[get_grid_key(neighbor)] = current
                    g_score[get_grid_key(neighbor)] = tentative_g_score
                    f_score[get_grid_key(neighbor)] = g_score[get_grid_key(neighbor)] + heuristic(neighbor, goal)

                    if not open_set:contains(neighbor) then
                        open_set:push(neighbor)
                    end
                end
            end
        end
    end

    if target_distance_index < #target_distance_states then
        target_distance_index = target_distance_index + 1
        max_target_distance = target_distance_states[target_distance_index]
        console.print("No path found. Reducing max target distance to " .. max_target_distance)
    else
        console.print("No path found even after reducing max target distance.")
    end

    return nil
end

local last_a_star_call = 0.0




local function check_if_stuck()
    --console.print("Checking if character is stuck.")
    local current_pos = get_player_position()
    local current_time = os.time()

    if last_position and calculate_distance(current_pos, last_position) < 0.1 then
        if current_time - last_move_time > stuck_threshold then
            return true
        end
    else
        last_move_time = current_time
    end

    last_position = current_pos

    return false
end

explorerlite.check_if_stuck = check_if_stuck

function explorerlite:set_custom_target(target)
    console.print("Setting custom target.")
    target_position = target
end

function explorerlite:movement_spell_to_target(target)
    local local_player = get_local_player()
    if not local_player then return end

    if not settings.use_evade then return end

    local movement_spell_id = {
        337031, -- General Evade
    }


    -- Check if the dash spell is off cooldown and ready to cast
    for _, spell_id in ipairs(movement_spell_id) do
        if local_player:is_spell_ready(spell_id) then
            -- Cast the dash spell towards the target's position
            local success = cast_spell.position(spell_id, target, 3.0) -- A little delay or else rogue goes turbo in dashing
            if success then
                console.print("Successfully used movement spell to target.")
            else
                console.print("Failed to use movement spell.")
            end
        else
            console.print("Movement spell on cooldown.")
        end
    end
end

local function move_to_target()
    if explorerlite.is_task_running then
        return  -- Do not set a path if a task is running
    end

    if target_position then
        local player_pos = get_player_position()
        if calculate_distance(player_pos, target_position) > 500 then
            current_path = {}
            path_index = 1
            return
        end

        local current_core_time = get_time_since_inject()
        local time_since_last_call = current_core_time - last_a_star_call

        if not current_path or #current_path == 0 or path_index > #current_path or time_since_last_call >= 0.50 then
            path_index = 1
            current_path = nil
            current_path = a_star(player_pos, target_position)
            last_a_star_call = current_core_time

            if not current_path then
                console.print("No path found to target. Finding new target.")
                return
            end
        end

        local next_point = current_path[path_index]
        if next_point and not next_point:is_zero() then
            explorerlite:movement_spell_to_target(next_point)
            local new_player_pos = get_player_position()
            if calculate_distance(player_pos, new_player_pos) == 0 then
                pathfinder.request_move(next_point)
            end
        end

        if next_point and next_point.x and not next_point:is_zero() and calculate_distance(player_pos, next_point) < grid_size then
            local direction = {
                x = next_point:x() - player_pos:x(),
                y = next_point:y() - player_pos:y()
            }
            last_movement_direction = direction
            path_index = path_index + 1
        end

        if calculate_distance(player_pos, target_position) < 2 then
            target_position = nil
            current_path = {}
            path_index = 1
        end
    else
        -- Move to center if no target
        console.print("No target found. Moving to center.")
        pathfinder.force_move_raw(vec3:new(9.204102, 8.915039, 0.000000))
    end
end

local function move_to_target_aggresive()
    if target_position then
        pathfinder.force_move_raw(target_position)
    else
        -- Move to center if no target
        console.print("No target found. Moving to center.")
        pathfinder.force_move_raw(vec3:new(9.204102, 8.915039, 0.000000))
    end
end


function explorerlite:move_to_target()
    console.print("Moving to target")
    if handle_stuck_player() then
        -- If we've just set a temporary target, we want to move to it immediately
        if settings.aggresive_movement then
            move_to_target_aggresive()
        else
            move_to_target()
        end
        return
    end

    if settings.aggresive_movement then
        move_to_target_aggresive()
    else
        move_to_target()
    end
end


local last_call_time = 0.0
on_update(function()
    if not settings.enabled then
        return
    end

    if explorerlite.is_task_running then
         return -- Don't run explorer logic if a task is running
    end

    local world = world.get_current_world()
    if world then
        local world_name = world:get_name()
        if world_name:match("Sanctuary") or world_name:match("Limbo") then
            return
        end
        -- Check if the player is not in Cerrigar
        if not utils.player_in_zone("Scos_Cerrigar") then
            return -- Exit the function if not in Cerrigar
        end
    end

    local current_core_time = get_time_since_inject()
    if current_core_time - last_call_time > 0.45 then
        last_call_time = current_core_time

        check_walkable_area()
        local is_stuck = check_if_stuck()
        if is_stuck then
            console.print("Character was stuck. Finding new target and attempting revive")
            target_position = find_target(false)
            target_position = set_height_of_valid_position(target_position)
            last_move_time = os.time()
            current_path = {}
            path_index = 1

            local local_player = get_local_player()
            if local_player and local_player:is_dead() then
                revive_at_checkpoint()
            end
        end
    end
end)

on_render(function()
    if not settings.enabled then
        return
    end

    -- dont slide frames here so drawings feel smooth
    if target_position then
        if target_position.x then
            graphics.text_3d("TARGET_1", target_position, 20, color_red(255))
        else
            if target_position and target_position:get_position() then
                graphics.text_3d("TARGET_2", target_position:get_position(), 20, color_orange(255))
            end
        end
    end

    if current_path then
        for i, point in ipairs(current_path) do
            local color = (i == path_index) and color_green(255) or color_yellow(255)
            graphics.text_3d("PATH_1", point, 15, color)
        end
    end
end)

return explorerlite
