
-- local fluid_to_color_map = {
--     ["water"] = "blue",
--     ["crude-oil"] = "black",
--     ["steam"] = "white",
--     ["heavy-oil"] = "red",
--     ["light-oil"] = "orange",
--     ["petroleum-gas"] = "purple",
--     ["sulfuric-acid"] = "yellow",
--     ["lubricant"] = "green",
-- }

-- ---@param entity LuaEntity
-- ---@return string
-- local function get_fluid_name(entity)
--     local fluid_name = "crude-oil"
--     local fluidbox = entity.fluidbox
--     if fluidbox and fluidbox.valid then
--         for index = 1, #fluidbox do
--             local contents = fluidbox.get_fluid_system_contents(index)
--             if contents then
--                 local amount = 0
--                 for name, count in pairs(contents) do
--                     if count > amount then
--                         amount = count
--                         fluid_name = name
--                     end
--                 end
--             end
--         end
--     end
--     return fluid_name
-- end

-- for _, surface in pairs(game.surfaces) do
--     local original_pipes = surface.find_entities_filtered{name="pipe"}
--     for _, pipe in pairs(original_pipes) do
--         local fluid_name = get_fluid_name(pipe)
--         local pipe_color = fluid_to_color_map[fluid_name]
--         if pipe_color then
--             surface.create_entity{
--                 name = pipe_color .. "-pipe",
--                 position = pipe.position,
--                 force = pipe.force,
--                 direction = pipe.direction,
--                 fluidbox = pipe.fluidbox,
--                 fast_replace = true,
--                 spill = false
--             }
--         end
--     end
--     local original_pipe_to_grounds = surface.find_entities_filtered{name="pipe-to-ground"}
--     for _, pipe_to_ground in pairs(original_pipe_to_grounds) do
--         local fluid_name = get_fluid_name(pipe_to_ground)
--         local pipe_color = fluid_to_color_map[fluid_name]
--         if pipe_color then
--             surface.create_entity{
--                 name = pipe_color .. "-pipe-to-ground",
--                 position = pipe_to_ground.position,
--                 force = pipe_to_ground.force,
--                 direction = pipe_to_ground.direction,
--                 fluidbox = pipe_to_ground.fluidbox,
--                 fast_replace = true,
--                 spill = false
--             }
--         end
--     end
-- end
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

-- -- local function get_closest_color(r, g, b)
-- --     local color_rgbs = {
-- --         {name = "red", rgb = {255, 0, 0}},
-- --         {name = "orange", rgb = {255, 75, 0}},
-- --         {name = "yellow", rgb = {255, 255, 0}},
-- --         {name = "green", rgb = {0, 128, 0}},
-- --         {name = "blue", rgb = {0, 0, 255}},
-- --         {name = "purple", rgb = {128, 0, 128}},
-- --         {name = "pink", rgb = {255, 192, 203}},
-- --         {name = "black", rgb = {5, 5, 5}},
-- --         {name = "white", rgb = {200, 200, 200}}
-- --     }

-- --     local function distance(color1, color2)
-- --         local sum = 0
-- --         for i = 1, 3 do
-- --             sum = sum + (color1[i] - color2[i])^2
-- --         end
-- --         return math.sqrt(sum)
-- --     end

-- --     local min_distance = math.huge
-- --     local closest_color = "unknown"

-- --     for _, color in pairs(color_rgbs) do
-- --         local d = distance(color.rgb, {r, g, b})
-- --         if d < min_distance then
-- --             min_distance = d
-- --             closest_color = color.name
-- --         end
-- --     end

-- --     return closest_color
-- -- end

-- -- local function get_fluid_color(fluid_name)
-- --     local fluid = game.fluid_prototypes[fluid_name]
-- --     local fluid_color = fluid.base_color
-- --     return get_closest_color(fluid_color.r, fluid_color.g, fluid_color.b)
-- -- end

-- -- local selected_pipe = game.player.selected
-- -- local selected_fluidbox = selected_pipe and selected_pipe.fluidbox

-- -- game.print(serpent.line(selected_fluidbox))

-- -- for _, fluidbox_fluid in ipairs(selected_fluidbox) do
-- --     if type(fluidbox_fluid) ~= "userdata" then
-- --         game.print(fluidbox_fluid.name)
-- --         local fluid_name = fluidbox_fluid.name
-- --         local pipe_color = get_fluid_color(fluid_name)
-- --         game.print(pipe_color)
-- --     end
-- -- end

-- -- -- if selected_pipe and selected_fluidbox and selected_fluidbox[1] then
-- -- --     local fluid_name = selected_pipe.fluidbox[1].name
-- -- --     local pipe_color = get_fluid_color(fluid_name)
-- -- --     game.player.surface.create_entity{
-- -- --         name = pipe_color .. "-pipe",
-- -- --         position = selected_pipe.position,
-- -- --         force = selected_pipe.force,
-- -- --         direction = selected_pipe.direction,
-- -- --         fast_replace = true
-- -- --     }
-- -- -- end

-- -- -- for _, surface in pairs(game.surfaces) do
-- -- --     local original_pipes = surface.find_entities_filtered{type="pipe"}
-- -- --     for _, pipe in pairs(original_pipes) do
-- -- --         local fluidbox = pipe.fluidbox
-- -- --         if fluidbox and fluidbox[1] then
-- -- --             local fluid_name = game.player.selected.fluidbox[1].name
-- -- --             local pipe_color = get_fluid_color(fluid_name)
-- -- --             surface.create_entity{
-- -- --                 name = pipe_color .. "-pipe",
-- -- --                 position = pipe.position,
-- -- --                 force = pipe.force,
-- -- --                 direction = pipe.direction,
-- -- --                 fast_replace = true
-- -- --             }
-- -- --         end
-- -- --     end
-- -- -- end