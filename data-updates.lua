
local color_coded_util = require("color-coded-util")
local pipe_filenames = color_coded_util.pipe_filenames
local pipe_to_ground_filenames = color_coded_util.pipe_to_ground_filenames
local recipe_order = color_coded_util.recipe_order
local rgb_colors = color_coded_util.rgb_colors
local replace_dash_with_underscore = color_coded_util.replace_dash_with_underscore

---------------------------------------------------
-- create subgroups for the color-coded variants --
---------------------------------------------------

local function create_rainbow_subgroup(name_suffix, order_suffix)
    local subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
    if not subgroup then
        log("subgroup not found")
    else
        subgroup.name = "color-coded-" .. name_suffix
        subgroup.order = subgroup.order .. order_suffix
        return subgroup
    end
end

local pipe_subgroup = create_rainbow_subgroup("pipe", "a")
local pipe_to_ground_subgroup = create_rainbow_subgroup("pipe-to-ground", "b")
local pump_subgroup = create_rainbow_subgroup("pump", "c")
local storage_tank_subgroup = create_rainbow_subgroup("storage-tank", "d")

data:extend{ pipe_subgroup, pipe_to_ground_subgroup, pump_subgroup, storage_tank_subgroup }

local function create_fluid_subgroup(name_suffix, order_suffix)
    local subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
    if not subgroup then
        log("subgroup not found")
    else
        subgroup.name = "fluid-color-coded-" .. name_suffix
        subgroup.order = subgroup.order .. order_suffix
        return subgroup
    end
end

local fluid_pipe_subgroup = create_fluid_subgroup("pipe", "a[fluid]")
local fluid_pipe_to_ground_subgroup = create_fluid_subgroup("pipe-to-ground", "b[fluid]")
local fluid_pump_subgroup = create_fluid_subgroup("pump", "c[fluid]")
local fluid_storage_tank_subgroup = create_fluid_subgroup("storage-tank", "d[fluid]")

data:extend{ fluid_pipe_subgroup, fluid_pipe_to_ground_subgroup, fluid_pump_subgroup, fluid_storage_tank_subgroup }


---------------------------------
-- create color-coded entities --
---------------------------------

-- add a fast_replaceable_group to the base storage tank so that all the color-coded storage tanks inherit it
data.raw["storage-tank"]["storage-tank"].fast_replaceable_group = "storage-tank"

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


---@param recipe_to_match string
---@param recipe_to_add string
local function add_recipe_to_technology_effects(recipe_to_match, recipe_to_add)
    for _, technology in pairs(data.raw["technology"]) do
        if technology.effects then
            for _, effect in pairs(technology.effects) do
                if effect.type == "unlock-recipe" and effect.recipe == recipe_to_match then
                    table.insert(technology.effects, { type = "unlock-recipe", recipe = recipe_to_add })
                end
            end
        end
        if technology.normal and technology.normal.effects then
            for _, effect in pairs(technology.normal.effects) do
                if effect.type == "unlock-recipe" and effect.recipe == recipe_to_match then
                    table.insert(technology.normal.effects, { type = "unlock-recipe", recipe = recipe_to_add })
                end
            end
        end
        if technology.expensive and technology.expensive.effects then
            for _, effect in pairs(technology.expensive.effects) do
                if effect.type == "unlock-recipe" and effect.recipe == recipe_to_match then
                    table.insert(technology.expensive.effects, { type = "unlock-recipe", recipe = recipe_to_add })
                end
            end
        end
    end
end


---@param prototype data.ItemPrototype | data.PipePrototype | data.PipeToGroundPrototype | data.PumpPrototype | data.StorageTankPrototype
---@param color Color
---@param type string
---@return data.IconData
local function create_color_overlay_icons(prototype, color, type)
    local overlay_path = "__color-coded-pipes__/graphics/overlay-" .. type .. "-icon/overlay-" .. type .. "-icon.png"
    local icon_base = {
        icon = prototype.icon,
        icon_size = prototype.icon_size,
        icon_mipmaps = prototype.icon_mipmaps
    }
    local icon_overlay = {
        icon = overlay_path,
        icon_size = prototype.icon_size,
        icon_mipmaps = prototype.icon_mipmaps,
        tint = color
    }
    return { icon_base, icon_overlay }
end


---@param name string
---@param color Color
---@param entity_type string
local function create_color_overlay_item(name, color, entity_type)

    local item = table.deepcopy(data.raw["item"][entity_type])
    if not item then
        log(entity_type .. " item not found")
        return
    end

    local item_name = name .. "-" .. entity_type
    item.name = item_name
    item.place_result = item_name
    item.localised_name = { "color-coded.name", { "entity-name." .. entity_type }, { "fluid-name." .. name } }
    item.icons = create_color_overlay_icons(item, color, entity_type)
    item.order = get_order(item, name)
    item.subgroup = get_subgroup(entity_type, name)
    data:extend{ item }
end

---@param base_recipe_name string
---@param name string
---@param built_from_base_item boolean
local function create_color_overlay_recipe(base_recipe_name, name, built_from_base_item)
    local new_recipe = table.deepcopy(data.raw["recipe"][base_recipe_name])
    if not new_recipe then log(base_recipe_name .. " recipe not found") return end

    local new_recipe_name = name .. "-" .. base_recipe_name
    new_recipe.name = new_recipe_name
    new_recipe.result = new_recipe.result and new_recipe_name or nil
    new_recipe.results = new_recipe.results and { { type = "item", name = new_recipe_name, amount = 1 } } or nil

    if built_from_base_item then
        new_recipe.hidden = true
    end

    if new_recipe.normal then
        new_recipe.normal.result = new_recipe.normal.result and new_recipe_name or nil
        new_recipe.normal.results = new_recipe.normal.results and { { type = "item", name = new_recipe_name, amount = 1 } } or nil
        if built_from_base_item then
            new_recipe.normal.hidden = true
        end
    end

    if new_recipe.expensive then
        new_recipe.expensive.result = new_recipe.expensive.result and new_recipe_name or nil
        new_recipe.expensive.results = new_recipe.expensive.results and { { type = "item", name = new_recipe_name, amount = 1 } } or nil
        if built_from_base_item then
            new_recipe.expensive.hidden = true
        end
    end

    new_recipe.localised_name = { "color-coded.name", { "entity-name." .. base_recipe_name }, { "fluid-name." .. name } }
    add_recipe_to_technology_effects(base_recipe_name, new_recipe_name)
    data:extend{ new_recipe }
end



---@param name string
---@param color Color
---@param built_from_base_item boolean
local function create_color_overlay_pipe_entity(name, color, built_from_base_item)

    local pipe = table.deepcopy(data.raw["pipe"]["pipe"])
    if not pipe then log("pipe entity not found") return end

    local pipe_name = name .. "-pipe"
    if built_from_base_item then
        pipe.placeable_by = { item = pipe.name, count = 1 }
    else
        pipe.minable.result = pipe_name
    end
    pipe.name = pipe_name

    pipe.order = get_order(pipe, name)
    pipe.subgroup = get_subgroup("pipe", name)

    for _, filename in pairs(pipe_filenames) do
        local property_name = replace_dash_with_underscore(filename)
        local original_layer = table.deepcopy(pipe.pictures[property_name]) ---@type data.Sprite
        local overlay_layer = table.deepcopy(pipe.pictures[property_name]) ---@type data.Sprite
        overlay_layer.filename = "__color-coded-pipes__/graphics/overlay-pipe-" .. filename .. "/overlay-hr-pipe-" .. filename .. "@0.5x.png"
        overlay_layer.hr_version.filename = "__color-coded-pipes__/graphics/overlay-pipe-" .. filename .. "/overlay-hr-pipe-" .. filename .. ".png"
        overlay_layer.tint = color
        overlay_layer.hr_version.tint = color
        pipe.pictures[property_name] = {}
        pipe.pictures[property_name].layers = { original_layer, overlay_layer }
    end
    pipe.localised_name = { "color-coded.name", { "entity-name.pipe" }, { "fluid-name." .. name } }
    -- pipe.corpse = name .. "-pipe-remnants"

    pipe.icons = create_color_overlay_icons(pipe, color, "pipe")

    if pipe.fluid_box.pipe_covers then
        local directions = { "north", "east", "south", "west" }
        for _, direction in pairs(directions) do
            local original_layer = table.deepcopy(pipe.fluid_box.pipe_covers[direction].layers[1]) ---@type data.Sprite
            local overlay_layer = table.deepcopy(pipe.fluid_box.pipe_covers[direction].layers[1]) ---@type data.Sprite
            local shadow_layer = table.deepcopy(pipe.fluid_box.pipe_covers[direction].layers[2]) ---@type data.Sprite
            overlay_layer.filename = "__color-coded-pipes__/graphics/overlay-pipe-cover-" .. direction .. "/overlay-hr-pipe-cover-" .. direction .. "@0.5x.png"
            overlay_layer.hr_version.filename = "__color-coded-pipes__/graphics/overlay-pipe-cover-" .. direction .. "/overlay-hr-pipe-cover-" .. direction .. ".png"
            overlay_layer.tint = color
            overlay_layer.hr_version.tint = color
            pipe.fluid_box.pipe_covers[direction].layers = { shadow_layer, original_layer, overlay_layer }
        end
    end

    data:extend{ pipe }
end


---@param name string
---@param color Color
---@param placeable_by_base_item boolean
local function create_color_overlay_pipe_to_ground_entity(name, color, placeable_by_base_item)

    local pipe_to_ground = table.deepcopy(data.raw["pipe-to-ground"]["pipe-to-ground"])
    if not pipe_to_ground then log("pipe-to-ground entity not found") return end
    local pipe_to_ground_name = name .. "-pipe-to-ground"
    if placeable_by_base_item then
        pipe_to_ground.placeable_by = { item = pipe_to_ground.name, count = 1 }
    else
        pipe_to_ground.minable.result = pipe_to_ground_name
    end
    pipe_to_ground.name = pipe_to_ground_name

    pipe_to_ground.order = get_order(pipe_to_ground, name)
    pipe_to_ground.subgroup = get_subgroup("pipe-to-ground", name)

    for _, filename in pairs(pipe_to_ground_filenames) do
        local property_name = replace_dash_with_underscore(filename)
        local original_layer = table.deepcopy(pipe_to_ground.pictures[property_name]) ---@type data.Sprite
        local overlay_layer = table.deepcopy(pipe_to_ground.pictures[property_name]) ---@type data.Sprite
        overlay_layer.filename = "__color-coded-pipes__/graphics/overlay-pipe-to-ground-" .. filename .. "/overlay-hr-pipe-to-ground-" .. filename .. "@0.5x.png"
        overlay_layer.hr_version.filename = "__color-coded-pipes__/graphics/overlay-pipe-to-ground-" .. filename .. "/overlay-hr-pipe-to-ground-" .. filename .. ".png"
        overlay_layer.tint = color
        overlay_layer.hr_version.tint = color
        pipe_to_ground.pictures[property_name] = {}
        pipe_to_ground.pictures[property_name].layers = { original_layer, overlay_layer }
    end
    pipe_to_ground.localised_name = { "color-coded.name", { "entity-name.pipe-to-ground" }, { "fluid-name." .. name } }
    -- pipe_to_ground.corpse = name .. "-pipe-to-ground-remnants"
    pipe_to_ground.icons = create_color_overlay_icons(pipe_to_ground, color, "pipe-to-ground")

    if pipe_to_ground.fluid_box.pipe_covers then
        local directions = { "north", "east", "south", "west" }
        for _, direction in pairs(directions) do
            local original_layer = table.deepcopy(pipe_to_ground.fluid_box.pipe_covers[direction].layers[1]) ---@type data.Sprite
            local overlay_layer = table.deepcopy(pipe_to_ground.fluid_box.pipe_covers[direction].layers[1]) ---@type data.Sprite
            local shadow_layer = table.deepcopy(pipe_to_ground.fluid_box.pipe_covers[direction].layers[2]) ---@type data.Sprite
            overlay_layer.filename = "__color-coded-pipes__/graphics/overlay-pipe-cover-" .. direction .. "/overlay-hr-pipe-cover-" .. direction .. "@0.5x.png"
            overlay_layer.hr_version.filename = "__color-coded-pipes__/graphics/overlay-pipe-cover-" .. direction .. "/overlay-hr-pipe-cover-" .. direction .. ".png"
            overlay_layer.tint = color
            overlay_layer.hr_version.tint = color
            pipe_to_ground.fluid_box.pipe_covers[direction].layers = { shadow_layer, original_layer, overlay_layer }
        end
    end
    data:extend{ pipe_to_ground }
end



---@param fluid_name string
---@param fluid_color Color
---@param placeable_by_base_item boolean
local function create_color_overlay_storage_tank_entity(fluid_name, fluid_color, placeable_by_base_item)

    local storage_tank = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
    if not storage_tank then log("storage-tank entity not found") return end
    local storage_tank_name = fluid_name .. "-storage-tank"
    if placeable_by_base_item then
        storage_tank.placeable_by = { item = storage_tank.name, count = 1 }
    else
        storage_tank.minable.result = storage_tank_name
    end
    storage_tank.name = storage_tank_name
    storage_tank.order = get_order(storage_tank, fluid_name)
    storage_tank.subgroup = get_subgroup("storage-tank", fluid_name)
    local base_sheet = table.deepcopy(storage_tank.pictures.picture.sheets[1])
    local shadow_sheet = table.deepcopy(storage_tank.pictures.picture.sheets[2])
    local overlay_sheet = table.deepcopy(base_sheet)
    overlay_sheet.filename = "__color-coded-pipes__/graphics/overlay-storage-tank/overlay-storage-tank.png"
    overlay_sheet.hr_version.filename = "__color-coded-pipes__/graphics/overlay-storage-tank/overlay-hr-storage-tank.png"
    overlay_sheet.tint = fluid_color
    overlay_sheet.hr_version.tint = fluid_color
    storage_tank.pictures.picture.sheets = {
        [1] = base_sheet,
        [2] = overlay_sheet,
        [3] = shadow_sheet
    }
    storage_tank.localised_name = { "color-coded.name", { "entity-name.storage-tank" }, { "fluid-name." .. fluid_name } }
    -- storage_tank.corpse = color .. "-storage-tank-remnants"
    storage_tank.icons = create_color_overlay_icons(storage_tank, fluid_color, "storage-tank")

    if storage_tank.fluid_box.pipe_covers then
        local directions = { "north", "east", "south", "west" }
        for _, direction in pairs(directions) do
            local original_layer = table.deepcopy(storage_tank.fluid_box.pipe_covers[direction].layers[1]) ---@type data.Sprite
            local overlay_layer = table.deepcopy(storage_tank.fluid_box.pipe_covers[direction].layers[1]) ---@type data.Sprite
            local shadow_layer = table.deepcopy(storage_tank.fluid_box.pipe_covers[direction].layers[2]) ---@type data.Sprite
            overlay_layer.filename = "__color-coded-pipes__/graphics/overlay-pipe-cover-" .. direction .. "/overlay-hr-pipe-cover-" .. direction .. "@0.5x.png"
            overlay_layer.hr_version.filename = "__color-coded-pipes__/graphics/overlay-pipe-cover-" .. direction .. "/overlay-hr-pipe-cover-" .. direction .. ".png"
            overlay_layer.tint = fluid_color
            overlay_layer.hr_version.tint = fluid_color
            storage_tank.fluid_box.pipe_covers[direction].layers = { shadow_layer, original_layer, overlay_layer }
        end
    end

    data:extend{ storage_tank }
end




---@param name string
---@param color Color
---@param built_from_base_item boolean
local function create_color_overlay_pump(name, color, built_from_base_item)

    local pump = table.deepcopy(data.raw["pump"]["pump"])
    if not pump then log("pump entity not found") return end
    local pump_name = name .. "-pump"
    if built_from_base_item then
        pump.placeable_by = { item = pump.name, count = 1 }
    else
        pump.minable.result = pump_name
    end
    pump.name = pump_name
    pump.order = get_order(pump, name)
    pump.subgroup = get_subgroup("pump", name)
    for _, direction in pairs({ "north", "east", "south", "west" }) do
        local original_layer = table.deepcopy(pump.animations[direction]) ---@type data.Animation
        local overlay_layer = table.deepcopy(pump.animations[direction]) ---@type data.Animation
        -- overlay_layer.filename = "__color-coded-pipes__/graphics/overlay-pump/overlay-pump-" .. direction .. ".png"
        overlay_layer.hr_version.filename = "__color-coded-pipes__/graphics/overlay-pump-" .. direction .. "/overlay-hr-pump-" .. direction .. ".png"
        overlay_layer.tint = color
        overlay_layer.hr_version.tint = color
        pump.animations[direction] = { layers = { original_layer, overlay_layer } }
    end
    pump.localised_name = { "color-coded.name", { "entity-name.pump" }, { "fluid-name." .. name } }
    pump.icons = create_color_overlay_icons(pump, color, "pump")
    data:extend{ pump }
end



-- local fluids = data.raw["fluid"]
-- for _, fluid in pairs(fluids) do
--     local fluid_color = fluid.base_color
--     local fluid_name = fluid.name

--     if not (fluid_color.r and fluid_color.g and fluid_color.b) then
--         log("fluid " .. fluid_name .. " has no color")
--         goto next_fluid
--     end

--     fluid_color.a = 0.75

--     create_fluid_color_pipe_entity(fluid_name, fluid_color, true)
--     create_fluid_color_pipe_item(fluid_name, fluid_color)
--     -- create_fluid_color_pipe_recipe(fluid_name, fluid_color)

--     create_fluid_color_pipe_to_ground_entity(fluid_name, fluid_color, true)
--     create_fluid_color_pipe_to_ground_item(fluid_name, fluid_color)
--     -- create_fluid_color_pipe_to_ground_recipe(fluid_name, fluid_color)

--     create_fluid_color_storage_tank_entity(fluid_name, fluid_color, true)
--     create_fluid_color_storage_tank_item(fluid_name, fluid_color)
--     -- create_fluid_color_storage_tank_recipe(fluid_name, fluid_color)

--     ::next_fluid::

-- end

for name, color in pairs(rgb_colors) do

    -- color.a = 0.55
    local show_rainbow_recipes = settings.startup["color-coded-pipes-show-rainbow-recipes"].value
    local show_fluid_recipes = settings.startup["color-coded-pipes-show-fluid-recipes"].value
    local is_fluid_color = data.raw["fluid"][name] and true or false
    local is_rainbow_color = not is_fluid_color
    local built_from_base_item = (is_fluid_color and not show_fluid_recipes) or (is_rainbow_color and not show_rainbow_recipes) and true or false

    create_color_overlay_pipe_entity(name, color, built_from_base_item)
    create_color_overlay_item(name, color, "pipe")
    create_color_overlay_recipe("pipe", name, built_from_base_item)

    create_color_overlay_pipe_to_ground_entity(name, color, built_from_base_item)
    create_color_overlay_item(name, color, "pipe-to-ground")
    create_color_overlay_recipe("pipe-to-ground", name, built_from_base_item)

    create_color_overlay_storage_tank_entity(name, color, built_from_base_item)
    create_color_overlay_item(name, color, "storage-tank")
    create_color_overlay_recipe("storage-tank", name, built_from_base_item)

    create_color_overlay_pump(name, color, built_from_base_item)
    create_color_overlay_item(name, color, "pump")
    create_color_overlay_recipe("pump", name, built_from_base_item)

end



--------------------------------------------------------
-- add color-coded pipes to the main menu simulations --
--------------------------------------------------------

if settings.startup["color-coded-main-menu-simulations"].value then

    for _, simulation in pairs(data.raw["utility-constants"]["default"].main_menu_simulations) do
        simulation.init = simulation.init or ""
        simulation.init = simulation.init .. [[
            
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

            local function get_fluid_name(entity)
                local fluid_name = "crude-oil"
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
                        end
                    end
                end
                return fluid_name
            end

            for _, surface in pairs(game.surfaces) do
                local original_pipes = surface.find_entities_filtered{name="pipe"}
                for _, pipe in pairs(original_pipes) do
                    local fluid_name = get_fluid_name(pipe)
                    local pipe_color = fluid_to_color_map[fluid_name]
                    if pipe_color then
                        surface.create_entity{
                            -- name = pipe_color .. "-pipe",
                            name = fluid_name .. "-pipe",
                            position = pipe.position,
                            force = pipe.force,
                            direction = pipe.direction,
                            fluidbox = pipe.fluidbox,
                            fast_replace = true,
                            spill = false
                        }
                    end
                end
                local original_pipe_to_grounds = surface.find_entities_filtered{name="pipe-to-ground"}
                for _, pipe_to_ground in pairs(original_pipe_to_grounds) do
                    local fluid_name = get_fluid_name(pipe_to_ground)
                    local pipe_color = fluid_to_color_map[fluid_name]
                    if pipe_color then
                        surface.create_entity{
                            -- name = pipe_color .. "-pipe-to-ground",
                            name = fluid_name .. "-pipe-to-ground",
                            position = pipe_to_ground.position,
                            force = pipe_to_ground.force,
                            direction = pipe_to_ground.direction,
                            fluidbox = pipe_to_ground.fluidbox,
                            fast_replace = true,
                            spill = false
                        }
                    end
                end
                local original_storage_tanks = surface.find_entities_filtered{name="storage-tank"}
                for _, storage_tank in pairs(original_storage_tanks) do
                    local fluid_name = get_fluid_name(storage_tank)
                    local pipe_color = fluid_to_color_map[fluid_name]
                    if pipe_color then
                        surface.create_entity{
                            -- name = pipe_color .. "-storage-tank",
                            name = fluid_name .. "-storage-tank",
                            position = storage_tank.position,
                            force = storage_tank.force,
                            direction = storage_tank.direction,
                            fluidbox = storage_tank.fluidbox,
                            fast_replace = true,
                            spill = false
                        }
                    end
                end
            end

        ]]
    end

end
