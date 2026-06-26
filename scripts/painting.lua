
local constants = require("__color-coded-pipes__.scripts.constants") ---@module "scripts.constants"
local fluid_to_color_map = constants.fluid_to_color_map

--- Returns the name of the fluid in a given entity's fluidbox
---@param entity LuaEntity
---@return string
local function get_fluid_name(entity)

    local fluid_contents = entity.get_fluid_contents()
    if fluid_contents and next(fluid_contents) then
        local max_name, max_amount = nil, 0
        for name, count in pairs(fluid_contents) do
            if count > max_amount then
                max_name, max_amount = name, count
            end
        end
        if max_name then
            return max_name
        end
    end

    local fluids_count = entity.fluids_count
    if fluids_count and fluids_count > 0 then
        local max_name, max_amount = nil, 0
        for i = 1, fluids_count do
            local segment = entity.has_fluid_segment(i) and entity.get_fluid_segment_fluid(i) or nil
            if segment then
                if segment.amount > max_amount then
                    max_name, max_amount = segment.name, segment.amount
                end
            end
        end
        if max_name then
            return max_name
        end
    end

    return ""
end

--- Replaces a given pipe with a color-coded version based on the fluid it contains
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
                target = { name = name, quality = pipe.quality },
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
                local entity = surface.create_entity {
                    name = name,
                    position = position,
                    force = force,
                    direction = direction,
                    quality = pipe.quality,
                    fast_replace = true,
                    spill = false,
                    player = nil,
                }
                if entity then entity.last_user = player end
            end
        end
    end
end

--- Replaces a color-coded pipe with its base uncolored version
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
                target = { name = target_name, quality = pipe.quality },
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
                local entity = surface.create_entity {
                    name = target_name,
                    position = position,
                    force = force,
                    direction = direction,
                    quality = pipe.quality,
                    fast_replace = true,
                    spill = false,
                    player = nil,
                }
                if entity then entity.last_user = player end
            end
        end
    else
        local upgrade_target = pipe.get_upgrade_target()
        if upgrade_target then
            local color_coded_upgrade_target = upgrade_target.name:find("-color-coded-", 1, true)
            if color_coded_upgrade_target then
                pipe.cancel_upgrade(player.force, player)
            end
        end
    end
end

return {
    get_fluid_name = get_fluid_name,
    paint_pipe = paint_pipe,
    unpaint_pipe = unpaint_pipe,
}
