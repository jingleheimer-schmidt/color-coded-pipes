
local fluid_to_color_map = {
    ["water"] = "blue",
    ["crude-oil"] = "black",
    ["steam"] = "white",
    ["heavy-oil"] = "red",
    ["light-oil"] = "orange",
    ["petroleum-gas"] = "purple",
    ["sulfuric-acid"] = "yellow",
    ["lubricant"] = "green",
}

---@param entity LuaEntity
---@return string
local function get_fluid_name(entity)
    local fluid_name = ""
    local fluidbox = entity.fluidbox
    if fluidbox and fluidbox.valid then
        for index = 1, #fluidbox do
            local contents = fluidbox.get_fluid_segment_contents(index)
            if contents then
                local amount = 0
                for name, count in pairs(contents) do
                    if count > amount then
                        amount = count
                        fluid_name = name
                    end
                end
                break
            end
        end
    end
    return fluid_name
end

---@param player LuaPlayer
---@param entity LuaEntity
---@param color string
local function paint_entity(player, entity, color)
    if not entity.valid then return end
    local pipe_type = entity.type
    local planner_mod_enabled = script.active_mods["color-coded-pipe-planner"]
    local name = color .. "-color-coded-" .. pipe_type
    local force = entity.force
    local direction = entity.direction
    if planner_mod_enabled and player.mod_settings["color-coded-pipe-planner-bots-required"].value then
        entity.order_upgrade {
            force = force,
            -- target = fluid_name .. "-" .. pipe_type,
            target = name,
            player = player,
            direction = direction
        }
    else
        local surface = entity.surface
        local position = entity.position
        if surface.can_fast_replace {
                name = name,
                position = position,
                direction = direction,
                force = force,
            } then
            local replacement_entity = surface.create_entity {
                name = name,
                position = entity.position,
                force = entity.force,
                direction = entity.direction,
                fluidbox = entity.fluidbox,
                fast_replace = true,
                spill = false,
                player = nil,
            }
            replacement_entity.last_user = player
        end
    end
end

---@param player LuaPlayer
---@param entity LuaEntity
local function unpaint_entity(player, entity)
    if not entity.valid then return end
    local pipe_type = entity.type
    local planner_mod_enabled = script.active_mods["color-coded-pipe-planner"]
    local force = entity.force
    local direction = entity.direction
    if planner_mod_enabled and player.mod_settings["color-coded-pipe-planner-bots-required"].value then
        entity.order_upgrade {
            force = force,
            target = pipe_type,
            player = player,
            direction = direction
        }
    else
        local surface = entity.surface
        local position = entity.position
        if surface.can_fast_replace {
                name = pipe_type,
                position = position,
                direction = direction,
                force = force,
            } then
            local replacement_entity = surface.create_entity {
                name = pipe_type,
                position = position,
                force = force,
                direction = direction,
                fluidbox = entity.fluidbox,
                fast_replace = true,
                spill = false,
                player = nil,
            }
            replacement_entity.last_user = player
        end
    end
end

---@param type string
---@return string[]
local function get_color_coded_names(type)
    local color_coded_names = { type }
    local rbg = {
        "red",
        "orange",
        "yellow",
        "green",
        "blue",
        "purple",
        "pink",
        "black",
        "white",
    }
    for _, color in pairs(rbg) do
        local prototype_name = color .. "-color-coded-" .. type
        if prototypes.entity[prototype_name] then
            table.insert(color_coded_names, prototype_name)
        end
    end
    for _, fluid in pairs(prototypes.fluid) do
        local prototype_name = fluid.name .. "-color-coded-" .. type
        if prototypes.entity[prototype_name] then
            table.insert(color_coded_names, prototype_name)
        end
    end
    return color_coded_names
end


---@param event CustomCommandData
local function paint_pipes(event)
    local player_index = event.player_index
    if not player_index then return end
    local player = game.get_player(player_index)
    if not player then return end
    local surface = player.surface
    local force = player.force
    local found_pipes = surface.find_entities_filtered { name = get_color_coded_names("pipe"), force = force }
    local found_underground_pipes = surface.find_entities_filtered { name = get_color_coded_names("pipe-to-ground"), force = force }
    local found_pumps = surface.find_entities_filtered { name = get_color_coded_names("pump"), force = force }
    local found_storage_tanks = surface.find_entities_filtered { name = get_color_coded_names("storage-tank"), force = force }
    for _, pipe in pairs(found_pipes) do
        local fluid_name = get_fluid_name(pipe)
        local pipe_color = fluid_to_color_map[fluid_name]
        if pipe_color and pipe.valid then
            paint_entity(player, pipe, pipe_color)
        end
    end
    for _, pipe in pairs(found_underground_pipes) do
        local fluid_name = get_fluid_name(pipe)
        local pipe_color = fluid_to_color_map[fluid_name]
        if pipe_color and pipe.valid then
            paint_entity(player, pipe, pipe_color)
        end
    end
    for _, pump in pairs(found_pumps) do
        local fluid_name = get_fluid_name(pump)
        local pipe_color = fluid_to_color_map[fluid_name]
        if pipe_color and pump.valid then
            paint_entity(player, pump, pipe_color)
        end
    end
    for _, storage_tank in pairs(found_storage_tanks) do
        local fluid_name = get_fluid_name(storage_tank)
        local pipe_color = fluid_to_color_map[fluid_name]
        if pipe_color and storage_tank.valid then
            paint_entity(player, storage_tank, pipe_color)
        end
    end
end

---@param event CustomCommandData
local function unpaint_pipes(event)
    local player_index = event.player_index
    if not player_index then return end
    local player = game.get_player(player_index)
    if not player then return end
    local surface = player.surface
    local force = player.force
    local found_pipes = surface.find_entities_filtered { name = get_color_coded_names("pipe"), force = force }
    local found_underground_pipes = surface.find_entities_filtered { name = get_color_coded_names("pipe-to-ground"), force = force }
    local found_pumps = surface.find_entities_filtered { name = get_color_coded_names("pump"), force = force }
    local found_storage_tanks = surface.find_entities_filtered { name = get_color_coded_names("storage-tank"), force = force }
    for _, pipe in pairs(found_pipes) do
        unpaint_entity(player, pipe)
    end
    for _, pipe in pairs(found_underground_pipes) do
        unpaint_entity(player, pipe)
    end
    for _, pump in pairs(found_pumps) do
        unpaint_entity(player, pump)
    end
    for _, storage_tank in pairs(found_storage_tanks) do
        unpaint_entity(player, storage_tank)
    end
end

local function add_commands()
    commands.add_command("paint-pipes", "- replace base game pipes with colored versions matching their contents",
        paint_pipes)
    commands.add_command("unpaint-pipes", "- replace colored pipes with base game versions", unpaint_pipes)
end

local function reset_technology_effects()
    for _, force in pairs(game.forces) do
        force.reset_technology_effects()
    end
end

script.on_init(function()
    add_commands()
    reset_technology_effects()
end)

script.on_load(function()
    add_commands()
end)

script.on_configuration_changed(function()
    reset_technology_effects()
end)


-- -- build a bunch of pipes to see what they look like
-- local count = 1
-- for name, prototype in pairs(game.fluid_prototypes) do
--     local surface = game.player.surface
--     local force = game.player.force
--     local fluid_name = prototype.name
--     if game.entity_prototypes[fluid_name .. "-pipe"] then
--         local underground = surface.create_entity{
--             name = fluid_name .. "-pipe-to-ground",
--             position = {x = game.player.position.x + count -1, y = game.player.position.y + 2},
--             force = force,
--             direction = defines.direction.south,
--         }
--         local pipe_length = 3
--         for i = 0, pipe_length do
--             local pipe = surface.create_entity{
--                 name = fluid_name .. "-pipe",
--                 position = {x = game.player.position.x + count - 1, y = game.player.position.y + 3 + i},
--                 force = force,
--             }
--         end
--         local tank = surface.create_entity{
--             name = fluid_name .. "-storage-tank",
--             position = {x = game.player.position.x + count, y = game.player.position.y + 5 + pipe_length},
--             force = force,
--         }
--         tank.insert_fluid{
--             name = fluid_name,
--             amount = 10000
--         }
--         count = count + 3
--     end
-- end



-- comand to filter quickbar slots for testing stuff
-- local function filter_quickbar()
--     local fluid_pipes = {}
--     local rainbow_pipes = {}
--     local player = game.player
--     rainbow_pipes = {
--         "red",
--         "orange",
--         "yellow",
--         "green",
--         "blue",
--         "purple",
--         "pink",
--         "black",
--         "white",
--     }
--     for name, prototype in pairs(game.fluid_prototypes) do
--         if game.entity_prototypes[name .. "-pipe"] then
--             table.insert(fluid_pipes, name)
--         end
--     end

--     local quickbar_index = 1
--     for _, pipe_color in pairs(rainbow_pipes) do
--         if game.item_prototypes[pipe_color .. "-pipe"] then
--             player.set_quick_bar_slot(quickbar_index, game.item_prototypes[pipe_color .. "-pipe"])
--             quickbar_index = quickbar_index + 1
--         end
--     end
--     quickbar_index = 11
--     for _, pipe_color in pairs(rainbow_pipes) do
--         if game.item_prototypes[pipe_color .. "-pipe-to-ground"] then
--             player.set_quick_bar_slot(quickbar_index, game.item_prototypes[pipe_color .. "-pipe-to-ground"])
--             quickbar_index = quickbar_index + 1
--         end
--     end
--     quickbar_index = 21
--     for _, pipe_color in pairs(rainbow_pipes) do
--         if game.item_prototypes[pipe_color .. "-pump"] then
--             player.set_quick_bar_slot(quickbar_index, game.item_prototypes[pipe_color .. "-pump"])
--             quickbar_index = quickbar_index + 1
--         end
--     end
--     quickbar_index = 31
--     for _, pipe_color in pairs(rainbow_pipes) do
--         if game.item_prototypes[pipe_color .. "-storage-tank"] then
--             player.set_quick_bar_slot(quickbar_index, game.item_prototypes[pipe_color .. "-storage-tank"])
--             quickbar_index = quickbar_index + 1
--         end
--     end
--     quickbar_index = 41
--     for _, pipe_color in pairs(fluid_pipes) do
--         if game.item_prototypes[pipe_color .. "-pipe"] then
--             player.set_quick_bar_slot(quickbar_index, game.item_prototypes[pipe_color .. "-pipe"])
--             quickbar_index = quickbar_index + 1
--         end
--     end
--     quickbar_index = 51
--     for _, pipe_color in pairs(fluid_pipes) do
--         if game.item_prototypes[pipe_color .. "-pipe-to-ground"] then
--             player.set_quick_bar_slot(quickbar_index, game.item_prototypes[pipe_color .. "-pipe-to-ground"])
--             quickbar_index = quickbar_index + 1
--         end
--     end
--     quickbar_index = 61
--     for _, pipe_color in pairs(fluid_pipes) do
--         if game.item_prototypes[pipe_color .. "-pump"] then
--             player.set_quick_bar_slot(quickbar_index, game.item_prototypes[pipe_color .. "-pump"])
--             quickbar_index = quickbar_index + 1
--         end
--     end
--     quickbar_index = 71
--     for _, pipe_color in pairs(fluid_pipes) do
--         if game.item_prototypes[pipe_color .. "-storage-tank"] then
--             player.set_quick_bar_slot(quickbar_index, game.item_prototypes[pipe_color .. "-storage-tank"])
--             quickbar_index = quickbar_index + 1
--         end
--     end
-- end
-- filter_quickbar()

