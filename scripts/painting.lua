
local constants = require("__color-coded-pipes__.scripts.constants")
local fluid_to_color_map = constants.fluid_to_color_map

--- Returns the name of the fluid in a given entity's fluidbox
---@param entity LuaEntity
---@return string
local function get_fluid_name(entity)
    local fluidbox = entity.fluidbox
    if not (fluidbox and fluidbox.valid) then return "" end

    for i = 1, #fluidbox do
        -- Try segment contents first
        local contents = fluidbox.get_fluid_segment_contents(i)
        if contents and next(contents) then
            local max_name, max_amount = nil, 0
            for name, count in pairs(contents) do
                if count > max_amount then
                    max_name, max_amount = name, count
                end
            end
            return max_name or ""
        end

        -- Fall back to fluidbox[i].name
        local fluid = fluidbox[i]
        if fluid and fluid.name then
            return fluid.name
        end

        -- Try locked fluid
        local locked = fluidbox.get_locked_fluid(i)
        if locked then
            return locked
        end

        -- Finally try filter
        local filter = fluidbox.get_filter(i)
        if filter and filter.name then
            return filter.name
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
                local entity = surface.create_entity {
                    name = name,
                    position = position,
                    force = force,
                    direction = direction,
                    quality = pipe.quality,
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
                local entity = surface.create_entity {
                    name = target_name,
                    position = position,
                    force = force,
                    direction = direction,
                    quality = pipe.quality,
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

return {
    get_fluid_name = get_fluid_name,
    paint_pipe = paint_pipe,
    unpaint_pipe = unpaint_pipe,
}
