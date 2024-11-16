
-----------------------------------------
-- import util constants and functions --
-----------------------------------------

local color_coded_util = require("color-coded-util")
local pipe_filenames = color_coded_util.pipe_filenames
local pipe_to_ground_filenames = color_coded_util.pipe_to_ground_filenames
local recipe_order = color_coded_util.recipe_order
local rgb_colors = color_coded_util.rgb_colors
local replace_dash_with_underscore = color_coded_util.replace_dash_with_underscore


---------------------------------------------------
-- create subgroups for the color-coded variants --
---------------------------------------------------

local function create_subgroup(name_suffix, order_suffix, fluid)
    local subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
    if not subgroup then
        log("subgroup not found")
    else
        subgroup.name = (fluid and "fluid-" or "") .. "color-coded-" .. name_suffix
        subgroup.order = subgroup.order .. order_suffix
        data:extend { subgroup }
    end
end

local group_sorting = {
    { entity_type = "pipe",           order = "a" },
    { entity_type = "pipe-to-ground", order = "b" },
    { entity_type = "pump",           order = "c" },
    { entity_type = "storage-tank",   order = "d" }
}

for _, group in pairs(group_sorting) do
    create_subgroup(group.entity_type, group.order, false)
    create_subgroup(group.entity_type, group.order .. "[fluid]", true)
end


----------------------------------------------------------------------------------------------------------------
-- add a fast_replaceable_group to the base storage tank so that all the color-coded storage tanks inherit it --
----------------------------------------------------------------------------------------------------------------

local fast_replaceable_group = data.raw["storage-tank"]["storage-tank"].fast_replaceable_group or "storage-tank"
data.raw["storage-tank"]["storage-tank"].fast_replaceable_group = fast_replaceable_group


------------------------------------
-- just a couple helper functions --
------------------------------------

-- get the order for a color-coded item or entity
---@param item data.ItemPrototype | data.PipePrototype | data.PipeToGroundPrototype | data.StorageTankPrototype | data.PumpPrototype
---@param color_name string?
---@return string
local function get_order(item, color_name)
    local order = item.order or ""
    local fluid = data.raw["fluid"][color_name]
    if fluid then
        order = order .. "-" .. (fluid.order or "")
    end
    if recipe_order[color_name] then
        order = order .. "-" .. (recipe_order[color_name] or "")
    end
    return order
end


-- get the subgroup for a color-coded item or entity
---@param type string
---@param name string
---@return string
local function get_subgroup(type, name)
    if data.raw["fluid"][name] then
        return "fluid-color-coded-" .. type
    else
        return "color-coded-" .. type
    end
end


-- add a color-coded variant to all the same technology effects as its base version
---@param recipe_to_match string
---@param recipe_to_add string
---@return boolean
local function add_recipe_to_technology_effects(recipe_to_match, recipe_to_add)
    local added_to_technology = false
    for _, technology in pairs(data.raw["technology"]) do
        local effect_tables = { technology.effects, }
        for _, effect_table in pairs(effect_tables) do
            if effect_table then
                for _, effect in pairs(effect_table) do
                    if effect.type == "unlock-recipe" and effect.recipe == recipe_to_match then
                        table.insert(effect_table, { type = "unlock-recipe", recipe = recipe_to_add })
                        added_to_technology = true
                    end
                end
            end
        end
    end
    return added_to_technology
end


-- create icons for a color-coded item or entity
---@param prototype data.ItemPrototype | data.PipePrototype | data.PipeToGroundPrototype | data.PumpPrototype | data.StorageTankPrototype
---@param color Color
---@param type string
---@return data.IconData
local function create_color_overlay_icons(prototype, color, type)
    local overlay_path = "__color-coded-pipes__/graphics/icons/overlay-" .. type .. "-icon/overlay-" .. type .. "-icon.png"
    local icons = prototype.icons
    local icon_base = {
        icon = prototype.icon,
        icon_size = prototype.icon_size,
    }
    local icon_overlay = {
        icon = overlay_path,
        icon_size = prototype.icon_size,
        tint = color
    }
    if icons then
        icon_overlay.icon_size = icons[1].icon_size
        table.insert(icons, icon_overlay)
    else
        icons = { icon_base, icon_overlay }
    end
    return icons
end


----------------------------------------------
-- functions to create color-coded variants --
----------------------------------------------

-- create a color-coded version of an item
---@param entity_type string
---@param name string
---@param color Color
local function create_color_overlay_item(entity_type, name, color)
    local item = table.deepcopy(data.raw["item"][entity_type])
    if not item then
        log(entity_type .. " item not found")
        return
    end
    local item_name = name .. "-color-coded-" .. entity_type
    item.name = item_name
    item.place_result = item_name
    item.localised_name = { "color-coded.name", { "entity-name." .. entity_type }, { "fluid-name." .. name } }
    item.icons = create_color_overlay_icons(item, color, entity_type)
    item.order = get_order(item, name)
    item.subgroup = get_subgroup(entity_type, name)
    data:extend { item }
end


-- create a color-coded version of a recipe
---@param base_recipe_name string
---@param name string
---@param built_from_base_item boolean
local function create_color_overlay_recipe(base_recipe_name, name, built_from_base_item)
    local new_recipe = table.deepcopy(data.raw["recipe"][base_recipe_name])
    if not new_recipe then log(base_recipe_name .. " recipe not found") return end
    local new_recipe_name = name .. "-color-coded-" .. base_recipe_name
    new_recipe.name = new_recipe_name
    new_recipe.results = { { type = "item", name = new_recipe_name, amount = 1 } }
    if built_from_base_item then
        new_recipe.hidden = true
    end
    new_recipe.localised_name = { "color-coded.name", { "entity-name." .. base_recipe_name }, { "fluid-name." .. name } }
    if not built_from_base_item then
        local added_to_technology = add_recipe_to_technology_effects(base_recipe_name, new_recipe_name)
        if added_to_technology then
            new_recipe.enabled = false
        end
    end
    data:extend { new_recipe }
end


-- create a color-coded version of a pipe, pipe-to-ground, pump, or storage tank
---@param entity_type string
---@param color_name string
---@param color Color
---@param built_from_base_item boolean
local function create_color_overlay_entity(entity_type, color_name, color, built_from_base_item)
    local entity = table.deepcopy(data.raw[entity_type][entity_type])
    entity = entity --[[@as data.PipePrototype | data.PipeToGroundPrototype | data.StorageTankPrototype | data.PumpPrototype]]
    if not entity then log(entity_type .. " entity not found") return  end
    local entity_name = color_name .. "-color-coded-" .. entity_type
    if built_from_base_item then
        entity.placeable_by = { item = entity.name, count = 1 }
    else
        entity.minable.result = entity_name
    end
    entity.name = entity_name
    entity.order = get_order(entity, color_name)
    entity.subgroup = get_subgroup(entity_type, color_name)
    entity.icons = create_color_overlay_icons(entity, color, entity_type)
    entity.localised_name = { "color-coded.name", { "entity-name." .. entity_type }, { "fluid-name." .. color_name } }
    entity.corpse = color_name .. "-color-coded-" .. entity_type .. "-remnants"
    if data.raw["fluid"][color_name] then
        entity.npt_compat = { mod = "color-coded-pipes", ignore = true }
    end
    if entity.fluid_box.pipe_covers then
        for _, direction in pairs({ "north", "east", "south", "west" }) do
            local original_layer = table.deepcopy(entity.fluid_box.pipe_covers[direction].layers[1]) ---@type data.Sprite
            local overlay_layer = table.deepcopy(entity.fluid_box.pipe_covers[direction].layers[1]) ---@type data.Sprite
            local shadow_layer = table.deepcopy(entity.fluid_box.pipe_covers[direction].layers[2]) ---@type data.Sprite
            if overlay_layer.filename then
                overlay_layer.filename = "__color-coded-pipes__/graphics/pipe-covers/overlay/overlay-pipe-cover-" .. direction .. ".png"
                overlay_layer.tint = color
            end
            entity.fluid_box.pipe_covers[direction].layers = { shadow_layer, original_layer, overlay_layer }
        end
    end
    if entity_type == "pipe" then
        for _, filename in pairs(pipe_filenames) do
            local property_name = replace_dash_with_underscore(filename)
            local original_layer = table.deepcopy(entity.pictures[property_name]) ---@type data.Sprite
            local overlay_layer = table.deepcopy(entity.pictures[property_name]) ---@type data.Sprite
            if overlay_layer.filename then
                overlay_layer.filename = "__color-coded-pipes__/graphics/pipe/overlay/overlay-pipe-" .. filename .. ".png"
                overlay_layer.tint = color
            end
            entity.pictures[property_name] = {}
            entity.pictures[property_name].layers = { original_layer, overlay_layer }
        end
    elseif entity_type == "pipe-to-ground" then
        for _, filename in pairs(pipe_to_ground_filenames) do
            local property_name = replace_dash_with_underscore(filename)
            local original_layer = table.deepcopy(entity.pictures[property_name]) ---@type data.Sprite
            local overlay_layer = table.deepcopy(entity.pictures[property_name]) ---@type data.Sprite
            if overlay_layer.filename then
                overlay_layer.filename = "__color-coded-pipes__/graphics/pipe-to-ground/overlay/overlay-pipe-to-ground-" .. filename .. ".png"
                overlay_layer.tint = color
            end
            entity.pictures[property_name] = {}
            entity.pictures[property_name].layers = { original_layer, overlay_layer }
        end
    elseif entity_type == "pump" then
        for _, direction in pairs({ "north", "east", "south", "west" }) do
            local original_layer = table.deepcopy(entity.animations[direction]) ---@type data.Animation
            local overlay_layer = table.deepcopy(entity.animations[direction]) ---@type data.Animation
            if overlay_layer.filename then
                overlay_layer.filename = "__color-coded-pipes__/graphics/pump/overlay/overlay-pump-" .. direction .. ".png"
                overlay_layer.tint = color
            end
            entity.animations[direction] = { layers = { original_layer, overlay_layer } }
        end
    elseif entity_type == "storage-tank" then
        local base_sheet = table.deepcopy(entity.pictures.picture.sheets[1])
        local shadow_sheet = table.deepcopy(entity.pictures.picture.sheets[2])
        local overlay_sheet = table.deepcopy(base_sheet)
        if overlay_sheet.filename then
            overlay_sheet.filename = "__color-coded-pipes__/graphics/storage-tank/overlay/overlay-storage-tank.png"
            overlay_sheet.tint = color
        end
        entity.pictures.picture.sheets = {
            [1] = base_sheet,
            [2] = overlay_sheet,
            [3] = shadow_sheet
        }
    end
    data:extend { entity }
end

---@param entity_name string
---@param color_name string
---@param color Color
local function create_color_overlay_corpse(entity_name, color_name, color)
    local corpse = table.deepcopy(data.raw["corpse"][entity_name .. "-remnants"])
    corpse.name = color_name .. "-color-coded-" .. entity_name .. "-remnants"
    -- corpse.icons = create_color_overlay_icons(corpse, color, entity_type)
    corpse.localised_name = { "color-coded.name", { "entity-name." .. entity_name }, { "fluid-name." .. color_name } }
    corpse.animation_overlay = table.deepcopy(corpse.animation)
    if corpse.animation_overlay.filename then
        corpse.animation_overlay.filename = "__color-coded-pipes__/graphics/" .. entity_name .. "/overlay/overlay-" .. entity_name .. "-remnants.png"
        corpse.animation_overlay.tint = color
    else
        for _, rotated_animation in pairs(corpse.animation_overlay) do
            if rotated_animation.filename then
                rotated_animation.filename = "__color-coded-pipes__/graphics/" .. entity_name .. "/overlay/overlay-" .. entity_name .. "-remnants.png"
                rotated_animation.tint = color
            end
        end
    end
    data:extend { corpse }
end


------------------------------------------------------------------------------------
-- create color-coded versions of pipes, pipe-to-ground, storage tanks, and pumps --
------------------------------------------------------------------------------------

for color_name, color in pairs(rgb_colors) do
    local show_rainbow_recipes = settings.startup["color-coded-pipes-show-rainbow-recipes"].value
    local show_fluid_recipes = settings.startup["color-coded-pipes-show-fluid-recipes"].value
    local is_fluid_color = data.raw["fluid"][color_name] and true or false
    local is_rainbow_color = not is_fluid_color
    local built_from_base_item = (is_fluid_color and not show_fluid_recipes) or (is_rainbow_color and not show_rainbow_recipes) and true or false

    create_color_overlay_entity("pipe", color_name, color, built_from_base_item)
    create_color_overlay_item("pipe", color_name, color)
    create_color_overlay_recipe("pipe", color_name, built_from_base_item)
    create_color_overlay_corpse("pipe", color_name, color)

    create_color_overlay_entity("pipe-to-ground", color_name, color, built_from_base_item)
    create_color_overlay_item("pipe-to-ground", color_name, color)
    create_color_overlay_recipe("pipe-to-ground", color_name, built_from_base_item)
    create_color_overlay_corpse("pipe-to-ground", color_name, color)

    create_color_overlay_entity("storage-tank", color_name, color, built_from_base_item)
    create_color_overlay_item("storage-tank", color_name, color)
    create_color_overlay_recipe("storage-tank", color_name, built_from_base_item)
    create_color_overlay_corpse("storage-tank", color_name, color)

    create_color_overlay_entity("pump", color_name, color, built_from_base_item)
    create_color_overlay_item("pump", color_name, color)
    create_color_overlay_recipe("pump", color_name, built_from_base_item)
    create_color_overlay_corpse("pump", color_name, color)
end


--------------------------------------------------------
-- add color-coded pipes to the main menu simulations --
--------------------------------------------------------

local init_script = [[

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
            end
        end
    end
    return fluid_name
end
for _, surface in pairs(game.surfaces) do
    local original_pipes = surface.find_entities_filtered { name = "pipe" }
    for _, pipe in pairs(original_pipes) do
        local fluid_name = get_fluid_name(pipe)
        if fluid_name ~= "" then
            surface.create_entity {
                name = fluid_name .. "-color-coded-pipe",
                position = pipe.position,
                force = pipe.force,
                direction = pipe.direction,
                fluidbox = pipe.fluidbox,
                fast_replace = true,
                spill = false
            }
        end
    end
    local original_pipe_to_grounds = surface.find_entities_filtered { name = "pipe-to-ground" }
    for _, pipe_to_ground in pairs(original_pipe_to_grounds) do
        local fluid_name = get_fluid_name(pipe_to_ground)
        if fluid_name ~= "" then
            surface.create_entity {
                name = fluid_name .. "-color-coded-pipe-to-ground",
                position = pipe_to_ground.position,
                force = pipe_to_ground.force,
                direction = pipe_to_ground.direction,
                fluidbox = pipe_to_ground.fluidbox,
                fast_replace = true,
                spill = false
            }
        end
    end
    local original_storage_tanks = surface.find_entities_filtered { name = "storage-tank" }
    for _, storage_tank in pairs(original_storage_tanks) do
        local fluid_name = get_fluid_name(storage_tank)
        if fluid_name ~= "" then
            surface.create_entity {
                name = fluid_name .. "-color-coded-storage-tank",
                position = storage_tank.position,
                force = storage_tank.force,
                direction = storage_tank.direction,
                fluidbox = storage_tank.fluidbox,
                fast_replace = true,
                spill = false
            }
        end
    end
    local original_pumps = surface.find_entities_filtered { name = "pump" }
    for _, pump in pairs(original_pumps) do
        local fluid_name = get_fluid_name(pump)
        if fluid_name ~= "" then
            surface.create_entity {
                name = fluid_name .. "-color-coded-pump",
                position = pump.position,
                force = pump.force,
                direction = pump.direction,
                fluidbox = pump.fluidbox,
                fast_replace = true,
                spill = false
            }
        end
    end
end

]]

if settings.startup["color-coded-main-menu-simulations"].value then
    for _, simulation in pairs(data.raw["utility-constants"]["default"].main_menu_simulations) do
        simulation.init = simulation.init or ""
        simulation.init = simulation.init .. init_script
    end
end
