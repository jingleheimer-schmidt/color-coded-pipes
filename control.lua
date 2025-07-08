
local util = require("util")
local constants = require("__color-coded-pipes__.scripts.constants")
local painting = require("__color-coded-pipes__.scripts.painting")
local base_entities = constants.base_entities
local pipe_colors = constants.pipe_colors
local paint_pipe = painting.paint_pipe
local unpaint_pipe = painting.unpaint_pipe

local function setup_storage()
    storage.entity_names = {}
    for _, entity_data in pairs(base_entities) do
        local entity_name = entity_data.name
        if prototypes.entity[entity_name] then table.insert(storage.entity_names, entity_name) end
        for color_name, _ in pairs(pipe_colors) do
            local prototype_name = color_name .. "-color-coded-" .. entity_name
            if prototypes.entity[prototype_name] then table.insert(storage.entity_names, prototype_name) end
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

local function build_color_name_cycles()
    storage.forward_colors = {}
    storage.reverse_colors = {}
    local orders = {}
    for color_name in pairs(pipe_colors) do
        local pipe_recipe = prototypes.recipe[color_name .. "-color-coded-pipe"]
        if pipe_recipe and not pipe_recipe.hidden_in_factoriopedia then
            orders[pipe_recipe.order] = color_name
        end
    end

    local sorted_orders = {}
    for order in pairs(orders) do
        table.insert(sorted_orders, order)
    end
    table.sort(sorted_orders)

    for i, order in ipairs(sorted_orders) do
        local current = orders[order]
        local next_index = (i % #sorted_orders) + 1
        local next_color = orders[sorted_orders[next_index]]
        storage.forward_colors[current] = next_color
        storage.reverse_colors[next_color] = current
    end
end

---@param event EventData.CustomInputEvent
local function on_custom_input(event)
    local input_name = event.input_name
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then return end

    local item_name, item_type, color_name

    if player.cursor_stack and player.cursor_stack.valid_for_read then
        item_name = player.cursor_stack.name
        color_name, item_type = item_name:match("^(.-)%-color%-coded%-(.+)$")
    elseif player.cursor_ghost then
        local ghost = player.cursor_ghost or ""
        if type(ghost) == "string" then
            item_name = ghost
        elseif type(ghost.name) == "string" then
            item_name = ghost.name
        elseif type(ghost.name.name) == "string" then
            item_name = ghost.name.name
        end
        color_name, item_type = item_name:match("^(.-)%-color%-coded%-(.+)$")
    else
        return
    end

    if not (color_name and item_type) then return end
    local target_color
    if input_name == "color-coded-pipes-next-color" then
        target_color = storage.forward_colors[color_name]
    elseif input_name == "color-coded-pipes-previous-color" then
        target_color = storage.reverse_colors[color_name]
    end
    if not target_color then return end

    local target_name = target_color .. "-color-coded-" .. item_type
    if not prototypes.item[target_name] then return end

    local inventory = player.get_main_inventory()
    if inventory and inventory.valid then
        local found, stack_index = inventory.find_item_stack(target_name)
        if found and player.cursor_stack.can_set_stack(found) then
            local count = found.count
            player.clear_cursor()
            player.cursor_stack.swap_stack(found)
            player.hand_location = { inventory = inventory.index, slot = stack_index or 1 }
            player.create_local_flying_text {
                text = { "", 
                    "[item=" .. target_name .. "]",
                    { "fluid-name." .. target_color },
                    { "",
                        " (",
                        count,
                        ")"
                    },
                },
                create_at_cursor = true,
            }
            return
        end
    end

    -- If item not in inventory, fallback to ghost cursor
    player.clear_cursor()
    player.cursor_ghost = target_name
    player.create_local_flying_text {
        text = { "",
            "[item=" .. target_name .. "]",
            { "fluid-name." .. target_color },
            { "",
                " (",
                { "color-coded.ghost" },
                ")"
            },
        },
        create_at_cursor = true,
    }
end

script.on_event("color-coded-pipes-next-color", on_custom_input)
script.on_event("color-coded-pipes-previous-color", on_custom_input)

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
    build_color_name_cycles()
end)

script.on_load(function()
    add_commands()
end)

script.on_configuration_changed(function()
    setup_storage()
    reset_technology_effects()
    add_automatic_underground_pipe_connector_support()
    build_color_name_cycles()
end)


-- -- build a bunch of pipes to see what they look like
-- local count = 1
-- for name, prototype in pairs(game.fluid_prototypes) do
--     local surface = game.player.surface
--     local force = game.player.force
--     local fluid_name = proto.name
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

