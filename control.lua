
local util = require("util")
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
            if contents and next(contents) then
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
---@param pipe LuaEntity
---@param bots_required boolean
---@param planner_mode string
local function paint_pipe(player, pipe, bots_required, planner_mode)
    if not pipe.valid then return end
    local fluid_name = get_fluid_name(pipe)
    local pipe_name = pipe.name
    local prefix = ((planner_mode == "fluid") and fluid_name) or fluid_to_color_map[fluid_name] or fluid_name
    local start_index, end_index = pipe_name:find(prefix .. "-color-coded-", 1, true)
    local pipe_color_needs_update = not (start_index and end_index)
    if pipe_color_needs_update then start_index, end_index = pipe_name:find("-color-coded-", 1, true) end
    local unpainted_pipe_name = pipe_color_needs_update and pipe_name:sub((end_index or 0) + 1) or pipe_name
    if fluid_name and fluid_name ~= "" and pipe_color_needs_update then
        local name = prefix .. "-color-coded-" .. unpainted_pipe_name
        local force = pipe.force
        local direction = pipe.direction
        if bots_required then
            pipe.order_upgrade {
                force = force,
                target = name,
                player = player,
                direction = direction
            }
        else
            local surface = pipe.surface
            local position = pipe.position
            if surface.can_fast_replace {
                    name = name,
                    position = position,
                    direction = direction,
                    force = force,
                } then
                local entity = player.surface.create_entity {
                    name = name,
                    position = position,
                    force = force,
                    direction = direction,
                    fluidbox = pipe.fluidbox,
                    fast_replace = true,
                    spill = false,
                    player = nil,
                }
                entity.last_user = player
            end
        end
    end
end

---@param player LuaPlayer
---@param pipe LuaEntity
---@param bots_required boolean
local function unpaint_pipe(player, pipe, bots_required)
    if not pipe.valid then return end
    local start_index, end_index = pipe.name:find("-color-coded-", 1, true)
    if start_index and end_index then
        local force = pipe.force
        local direction = pipe.direction
        local target_name = pipe.name:sub(end_index + 1)
        if bots_required then
            pipe.order_upgrade {
                force = force,
                target = target_name,
                player = player,
                direction = direction,
            }
        else
            local surface = pipe.surface
            local position = pipe.position
            if surface.can_fast_replace {
                    name = target_name,
                    position = position,
                    direction = direction,
                    force = force,
                } then
                local entity = player.surface.create_entity {
                    name = target_name,
                    position = position,
                    force = force,
                    direction = direction,
                    fluidbox = pipe.fluidbox,
                    fast_replace = true,
                    spill = false,
                    player = nil,
                }
                entity.last_user = player
            end
        end
    end
end

---@param names string[]
---@return string[]
local function color_coded(names)
    local color_coded_names = util.table.deepcopy(names)
    local colors = {
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
    local fluids = prototypes.fluid
    for _, name in pairs(names) do
        for _, color in pairs(colors) do
            local prototype_name = color .. "-color-coded-" .. name
            if prototypes.entity[prototype_name] then
                table.insert(color_coded_names, prototype_name)
            end
        end
        for _, fluid in pairs(fluids) do
            local prototype_name = fluid.name .. "-color-coded-" .. name
            if prototypes.entity[prototype_name] then
                table.insert(color_coded_names, prototype_name)
            end
        end
    end
    return color_coded_names
end

local base_entity_names = {
    "pipe",
    "pipe-to-ground",
    "storage-tank",
    "pump",
}
if script.active_mods["pipe_plus"] then
    table.insert(base_entity_names, "pipe-to-ground-2")
    table.insert(base_entity_names, "pipe-to-ground-3")
end
if script.active_mods["Flow Control"] then
    table.insert(base_entity_names, "pipe-elbow")
    table.insert(base_entity_names, "pipe-junction")
    table.insert(base_entity_names, "pipe-straight")
end
if script.active_mods["StorageTank2_2_0"] then
    table.insert(base_entity_names, "storage-tank2")
end
if script.active_mods["zithorian-extra-storage-tanks-port"] then
    table.insert(base_entity_names, "fluid-tank-1x1")
    table.insert(base_entity_names, "fluid-tank-2x2")
    table.insert(base_entity_names, "fluid-tank-3x4")
    table.insert(base_entity_names, "fluid-tank-5x5")
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
    local found_entities = surface.find_entities_filtered { name = color_coded(base_entity_names), force = force }
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
    local found_entities = surface.find_entities_filtered { name = color_coded(base_entity_names), force = force }
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

script.on_init(function()
    add_commands()
    reset_technology_effects()
    update_simulation()
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

