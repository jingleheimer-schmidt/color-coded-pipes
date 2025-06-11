
local util = require("util")
local constants = require("scripts.constants")
local painting = require("scripts.painting")
local base_entities = constants.base_entities
local pipe_colors = constants.pipe_colors
local paint_pipe = painting.paint_pipe
local unpaint_pipe = painting.unpaint_pipe

local function setup_storage()
    storage.entity_names = {}
    for _, entity_data in pairs(base_entities) do
        table.insert(storage.entity_names, entity_data.name)
    end
    for _, name in pairs(storage.entity_names) do
        for color, _ in pairs(pipe_colors) do
            local prototype_name = color .. "-color-coded-" .. name
            if prototypes.entity[prototype_name] then
                table.insert(storage.entity_names, prototype_name)
            end
        end
    end
end

---@param event CustomCommandData
local function paint_pipes(event)
    local player_index = event.player_index
    if not player_index then return end
    local player = game.get_player(player_index)
    if not player then return end
    local surface = player.surface
    local force = player.force
    local parameter = event.parameter or ""
    local planner_mode, bots_required = parameter:match("([^,%s]+)[,%s]*([^,%s]*)")
    bots_required = (bots_required == "true") and true or false
    local found_entities = surface.find_entities_filtered { name = storage.entity_names, force = force }
    for _, entity in pairs(found_entities) do
        paint_pipe(player, entity, bots_required, planner_mode)
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
    local bots_required = event.parameter == "true" and true or false
    local found_entities = surface.find_entities_filtered { name = storage.entity_names, force = force }
    for _, entity in pairs(found_entities) do
        unpaint_pipe(player, entity, bots_required)
    end
end

local function add_commands()
    commands.add_command("paint-pipes", "<color mode: fluid|rainbow>, <bots required: true|false> - replace pipes with color-coded versions", paint_pipes)
    commands.add_command("unpaint-pipes", "<bots required: true|false> - replace color-coded pipes with their base versions", unpaint_pipes)
end

local function reset_technology_effects()
    for _, force in pairs(game.forces) do
        force.reset_technology_effects()
    end
end

local function update_simulation()
    if game.simulation then
        paint_pipes { player_index = 1, parameter = "fluid, false", name = "paint-pipes", tick = game.tick }
    end
end

local function add_automatic_underground_pipe_connector_support()
    if not script.active_mods["automatic-underground-pipe-connectors"] then return end
    local new_undergrounds = {}
    for _, entity_data in pairs(base_entities) do
        if entity_data.type == "pipe-to-ground" then
            for color_name, color in pairs(pipe_colors) do
                local underground_name = color_name .. "-color-coded-" .. entity_data.name
                local pipe_name = color_name .. "-color-coded-pipe"
                new_undergrounds[underground_name] = { entity = pipe_name, item = pipe_name }
            end
        end
    end
    if next(new_undergrounds) then
        remote.call("automatic-underground-pipe-connectors", "add_undergrounds", new_undergrounds)
    end
end

script.on_init(function()
    setup_storage()
    add_commands()
    reset_technology_effects()
    update_simulation()
    add_automatic_underground_pipe_connector_support()
end)

script.on_load(function()
    add_commands()
end)

script.on_configuration_changed(function()
    setup_storage()
    reset_technology_effects()
    add_automatic_underground_pipe_connector_support()
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

