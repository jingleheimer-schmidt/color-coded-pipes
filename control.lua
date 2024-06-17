
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
            local contents = fluidbox.get_fluid_system_contents(index)
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

---@param event CustomCommandData
local function color_code_pipes(event)
    local player_index = event.player_index
    if not player_index then return end
    local player = game.get_player(player_index)
    if not player then return end
    local surface = player.surface
    local force = player.force
    local found_pipes = surface.find_entities_filtered{name = "pipe", force = force}
    local found_underground_pipes = surface.find_entities_filtered{name = "pipe-to-ground", force = force}
    local found_storage_tanks = surface.find_entities_filtered{name = "storage-tank", force = force}

    for _, pipe in pairs(found_pipes) do
        local fluid_name = get_fluid_name(pipe)
        local pipe_color = fluid_to_color_map[fluid_name]
        if pipe_color then
            pipe.order_upgrade{
                force = force,
                target = pipe_color .. "-pipe",
                player = player,
                direction = pipe.direction
            }
        end
    end
    for _, pipe in pairs(found_underground_pipes) do
        local fluid_name = get_fluid_name(pipe)
        local pipe_color = fluid_to_color_map[fluid_name]
        if pipe_color then
            pipe.order_upgrade{
                force = force,
                target = pipe_color .. "-pipe-to-ground",
                player = player,
                direction = pipe.direction
            }
        end
    end
    for _, storage_tank in pairs(found_storage_tanks) do
        local fluid_name = get_fluid_name(storage_tank)
        local pipe_color = fluid_to_color_map[fluid_name]
        if pipe_color then
            storage_tank.order_upgrade{
                force = force,
                target = pipe_color .. "-storage-tank",
                player = player,
                direction = storage_tank.direction
            }
        end
    end
end

local function add_commands()
    commands.add_command("paint-pipes", "- replace base game pipes with colored versions matching their contents", color_code_pipes)
end

local function reset_technology_effects()
    for _, force in pairs(game.forces) do
        force.reset_technology_effects()
    end
end

script.on_init(function()
    -- add_commands()
    reset_technology_effects()
end)

script.on_load(function()
    -- add_commands()
end)

script.on_configuration_changed(function()
    reset_technology_effects()
end)

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


-- chat command to "unpaint" all the pipes

-- for _, pipe in pairs(game.player.surface.find_entities_filtered{type = "pipe"}) do
--     pipe.order_upgrade{
--         force = game.player.force,
--         target = "pipe",
--         player = game.player,
--         direction = pipe.direction
--     }
-- end
-- for _, pipe in pairs(game.player.surface.find_entities_filtered{type = "pipe-to-ground"}) do
--     pipe.order_upgrade{
--         force = game.player.force,
--         target = "pipe-to-ground",
--         player = game.player,
--         direction = pipe.direction
--     }
-- end
-- for _, storage_tank in pairs(game.player.surface.find_entities_filtered{type = "storage-tank"}) do
--     storage_tank.order_upgrade{
--         force = game.player.force,
--         target = "storage-tank",
--         player = game.player,
--         direction = storage_tank.direction
--     }
-- end


-- comand to filter quickbar slots for testing stuff
-- local function filter_quickbar()
--     local fluid_pipes = {}
--     local rainbow_pipes = {}
--     local player = game.get_player("asher_sky")
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