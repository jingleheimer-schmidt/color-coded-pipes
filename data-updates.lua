
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

---@param name_suffix string
---@param order_suffix string
---@param fluid boolean
local function create_subgroup(name_suffix, order_suffix, fluid)
    local subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
    if not subgroup then
        log("subgroup not found")
    else
        subgroup.name = (fluid and "fluid-" or "rainbow-") .. "color-coded-" .. name_suffix
        subgroup.order = subgroup.order .. (fluid and "-b[fluid]" or "-a[rainbow]") .. order_suffix
        data:extend { subgroup }
    end
end

local group_sorting = {
    { entity_name = "pipe",           order = "a-1" },
    { entity_name = "pipe-to-ground", order = "b-1" },
    { entity_name = "pump",           order = "c-1" },
    { entity_name = "storage-tank",   order = "d-1" }
}

if mods["pipe_plus"] then
    table.insert(group_sorting, { entity_name = "pipe-to-ground-2", order = "b-2" })
    table.insert(group_sorting, { entity_name = "pipe-to-ground-3", order = "b-3" })
end
if mods["Flow Control"] then
    table.insert(group_sorting, { entity_name = "pipe-junction", order = "b-4" })
    table.insert(group_sorting, { entity_name = "pipe-elbow", order = "b-5" })
    table.insert(group_sorting, { entity_name = "pipe-straight", order = "b-6" })
end
if mods["StorageTank2_2_0"] then
    table.insert(group_sorting, { entity_name = "storage-tank2", order = "d-2" })
end

for _, group in pairs(group_sorting) do
    create_subgroup(group.entity_name, group.order, false)
    create_subgroup(group.entity_name, group.order, true)
end


----------------------------------------------------------------------------------------------------------------
-- add a fast_replaceable_group to the base storage tank so that all the color-coded storage tanks inherit it --
----------------------------------------------------------------------------------------------------------------

local fast_replaceable_group = data.raw["storage-tank"]["storage-tank"].fast_replaceable_group or "storage-tank"
data.raw["storage-tank"]["storage-tank"].fast_replaceable_group = fast_replaceable_group


------------------------------------
-- just a couple helper functions --
------------------------------------

---@alias color_coded_prototypes data.ItemPrototype | data.PipePrototype | data.PipeToGroundPrototype | data.PumpPrototype | data.StorageTankPrototype | data.CorpsePrototype

-- get the order for a color-coded item or entity
---@param item color_coded_prototypes
---@param color_name string?
---@return string
local function get_order(item, color_name)
    local order = item.order or ""
    local base_name = item.name:match("color%-coded%-(.*)") or item.name
    if order == "" then
        order = data.raw["recipe"][base_name] and data.raw["recipe"][base_name].order or ""
    end
    if order == "" then
        order = data.raw["item"][base_name] and data.raw["item"][base_name].order or ""
    end
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
        return "rainbow-color-coded-" .. type
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
---@param prototype color_coded_prototypes
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


---@param old_entity_name string
---@param new_entity_name string
---@param simulation data.SimulationDefinition
local function update_factoriopedia_simulation(old_entity_name, new_entity_name, simulation)
    simulation.init = simulation.init or ""
    simulation.init = simulation.init .. [[
        for _, surface in pairs(game.surfaces) do
            local original_entities = surface.find_entities_filtered { name = "]] .. old_entity_name .. [[" }
            for _, original_entity in pairs(original_entities) do
                surface.create_entity {
                    name = "]] .. new_entity_name .. [[",
                    position = original_entity.position,
                    force = original_entity.force,
                    direction = original_entity.direction,
                    fluidbox = original_entity.fluidbox,
                    fast_replace = true,
                    spill = false
                }
            end
        end
    ]]
end


----------------------------------------------
-- functions to create color-coded variants --
----------------------------------------------

-- create a color-coded version of an item
---@param base_type string
---@param base_name string
---@param color_name string
---@param color Color
---@param built_from_base_item boolean
local function create_color_overlay_item(base_type, base_name, color_name, color, built_from_base_item)
    local item = table.deepcopy(data.raw["item"][base_name])
    if not item then
        log(base_name .. " item not found")
        return
    end
    local item_name = color_name .. "-color-coded-" .. base_name
    item.name = item_name
    item.place_result = item_name
    local localised_name = item.localised_name
    if not localised_name then localised_name = { "entity-name." .. base_name } end
    item.localised_name = { "color-coded.name", localised_name, { "fluid-name." .. color_name } }
    item.icons = create_color_overlay_icons(item, color, base_name)
    item.icon = nil
    item.order = get_order(item, color_name)
    item.subgroup = get_subgroup(base_name, color_name)
    if built_from_base_item then
        item.hidden = true
    end
    data:extend { item }
end


-- create a color-coded version of a recipe
---@param base_type string
---@param base_name string
---@param color_name string
---@param color Color
---@param built_from_base_item boolean
local function create_color_overlay_recipe(base_type, base_name, color_name, color, built_from_base_item)
    local color_coded_recipe = table.deepcopy(data.raw["recipe"][base_name])
    if not color_coded_recipe then log(base_name .. " recipe not found") return end
    local new_recipe_name = color_name .. "-color-coded-" .. base_name
    color_coded_recipe.name = new_recipe_name
    for _, result in pairs(color_coded_recipe.results) do
        if result.name == base_name then
            result.name = new_recipe_name
        end
    end
    if built_from_base_item then
        color_coded_recipe.hidden = true
    end
    local localised_name = color_coded_recipe.localised_name
    if not localised_name then localised_name = { "entity-name." .. base_name } end
    color_coded_recipe.localised_name = { "color-coded.name", localised_name, { "fluid-name." .. color_name } }
    if not built_from_base_item then
        local added_to_technology = add_recipe_to_technology_effects(base_name, new_recipe_name)
        if added_to_technology then
            color_coded_recipe.enabled = false
        end
    end
    color_coded_recipe.icons = data.raw["item"][new_recipe_name].icons
    color_coded_recipe.icon = nil
    data:extend { color_coded_recipe }
end


---@param prototype color_coded_prototypes
---@param name string
---@param color Color
local function add_overlay_to_pipe(prototype, name, color)
    for _, filename in pairs(pipe_filenames) do
        local property_name = replace_dash_with_underscore(filename)
        local original_layer = table.deepcopy(prototype.pictures[property_name]) ---@type data.Sprite
        local overlay_layer = table.deepcopy(prototype.pictures[property_name]) ---@type data.Sprite
        if overlay_layer.filename then
            overlay_layer.filename = "__color-coded-pipes__/graphics/" .. name .. "/overlay-" .. name .. "-" .. filename .. ".png"
            overlay_layer.tint = color
        end
        prototype.pictures[property_name] = {}
        prototype.pictures[property_name].layers = { original_layer, overlay_layer }
    end
end


---@param prototype color_coded_prototypes
---@param name string
---@param color Color
local function add_overlay_to_pipe_to_ground(prototype, name, color)
    for _, filename in pairs(pipe_to_ground_filenames) do
        local property_name = replace_dash_with_underscore(filename)
        local original_layer = table.deepcopy(prototype.pictures[property_name]) ---@type data.Sprite
        local overlay_layer = table.deepcopy(prototype.pictures[property_name]) ---@type data.Sprite
        if overlay_layer.filename then
            overlay_layer.filename = "__color-coded-pipes__/graphics/" .. name .. "/overlay-" .. name .. "-" .. filename .. ".png"
            overlay_layer.tint = color
        end
        prototype.pictures[property_name] = {}
        prototype.pictures[property_name].layers = { original_layer, overlay_layer }
    end
end


---@param prototype color_coded_prototypes
---@param name string
---@param color Color
local function add_overlay_to_pump(prototype, name, color)
    for _, direction in pairs({ "north", "east", "south", "west" }) do
        local original_layer = table.deepcopy(prototype.animations[direction]) ---@type data.Animation
        local overlay_layer = table.deepcopy(prototype.animations[direction]) ---@type data.Animation
        if overlay_layer.filename then
            overlay_layer.filename = "__color-coded-pipes__/graphics/" .. name .. "/overlay-" .. name .. "-" .. direction .. ".png"
            overlay_layer.tint = color
        end
        prototype.animations[direction] = { layers = { original_layer, overlay_layer } }
    end
end


---@param prototype color_coded_prototypes
---@param name string
---@param color Color
local function add_overlay_to_storage_tank(prototype, name, color)
    if prototype.pictures.picture.sheets then
        local base_sheet = table.deepcopy(prototype.pictures.picture.sheets[1])
        local shadow_sheet = table.deepcopy(prototype.pictures.picture.sheets[2])
        local overlay_sheet = table.deepcopy(base_sheet)
        if overlay_sheet.filename then
            overlay_sheet.filename = "__color-coded-pipes__/graphics/" .. name .. "/overlay-" .. name .. ".png"
            overlay_sheet.tint = color
        end
        prototype.pictures.picture.sheets = {
            [1] = base_sheet,
            [2] = overlay_sheet,
            [3] = shadow_sheet
        }
    elseif prototype.pictures.picture.layers then
        local original_layer = table.deepcopy(prototype.pictures.picture.layers[1]) ---@type data.Sprite
        local overlay_layer = table.deepcopy(prototype.pictures.picture.layers[1]) ---@type data.Sprite
        if overlay_layer.filename then
            overlay_layer.filename = "__color-coded-pipes__/graphics/" .. name .. "/overlay-" .. name .. ".png"
            overlay_layer.tint = color
        end
        prototype.pictures.picture.layers = { original_layer, overlay_layer }
    else
        for _, direction in pairs({ "north", "east", "south", "west" }) do
            local original_layer = table.deepcopy(prototype.pictures.picture[direction]) ---@type data.Sprite
            local overlay_layer = table.deepcopy(prototype.pictures.picture[direction]) ---@type data.Sprite
            if overlay_layer.filename then
                overlay_layer.filename = "__color-coded-pipes__/graphics/" .. name .. "/overlay-" .. name .. "-" .. direction .. ".png"
                overlay_layer.tint = color
            end
            prototype.pictures.picture[direction] = { layers = { original_layer, overlay_layer } }
        end
        prototype.pictures.fluid_background = nil
        prototype.pictures.window_background = nil
        prototype.pictures.flow_sprite = nil
    end
end


-- create a color-coded version of a pipe, pipe-to-ground, pump, or storage tank
---@param base_type string
---@param base_name string
---@param color_name string
---@param color Color
---@param built_from_base_item boolean
local function create_color_overlay_entity(base_type, base_name, color_name, color, built_from_base_item)
    local entity = table.deepcopy(data.raw[base_type][base_name]) --[[@as color_coded_prototypes]]
    if not entity then log(base_name .. " entity not found") return  end
    local entity_name = color_name .. "-color-coded-" .. base_name
    if built_from_base_item then
        entity.placeable_by = { item = base_name, count = 1 }
        entity.hidden_in_factoriopedia = true
    else
        entity.minable.result = entity_name
    end
    entity.name = entity_name
    entity.order = get_order(entity, color_name)
    entity.subgroup = get_subgroup(base_name, color_name)
    entity.icons = create_color_overlay_icons(entity, color, base_name)
    entity.icon = nil
    local localised_name = entity.localised_name
    if not localised_name then localised_name = { "entity-name." .. base_name } end
    entity.localised_name = { "color-coded.name", localised_name, { "fluid-name." .. color_name } }
    entity.corpse = color_name .. "-color-coded-" .. base_name .. "-remnants"
    if mods["no-pipe-touching"] then
        entity.npt_compat = { mod = "color-coded-pipes", tag = color_name }
    end
    if entity.factoriopedia_simulation then
        update_factoriopedia_simulation(base_name, entity_name, entity.factoriopedia_simulation)
    end
    if entity.fluid_box.pipe_covers then
        for _, direction in pairs({ "north", "east", "south", "west" }) do
            local original_layer = table.deepcopy(entity.fluid_box.pipe_covers[direction].layers[1]) ---@type data.Sprite
            local overlay_layer = table.deepcopy(entity.fluid_box.pipe_covers[direction].layers[1]) ---@type data.Sprite
            local shadow_layer = table.deepcopy(entity.fluid_box.pipe_covers[direction].layers[2]) ---@type data.Sprite
            if overlay_layer.filename then
                overlay_layer.filename = "__color-coded-pipes__/graphics/pipe-covers/overlay-pipe-cover-" .. direction .. ".png"
                overlay_layer.tint = color
            end
            entity.fluid_box.pipe_covers[direction].layers = { shadow_layer, original_layer, overlay_layer }
        end
    end
    if base_type == "pipe" then
        add_overlay_to_pipe(entity, base_name, color)
    elseif base_type == "pipe-to-ground" then
        add_overlay_to_pipe_to_ground(entity, base_name, color)
    elseif base_type == "pump" then
        add_overlay_to_pump(entity, base_name, color)
    elseif base_type == "storage-tank" then
        add_overlay_to_storage_tank(entity, base_name, color)
    end
    data:extend { entity }
end


---@param base_type string
---@param base_name string
---@param color_name string
---@param color Color
---@param built_from_base_item boolean
local function create_color_overlay_corpse(base_type, base_name, color_name, color, built_from_base_item)
    local corpse = table.deepcopy(data.raw["corpse"][base_name .. "-remnants"])
    local remnant_uses_base_corpse = false
    local corpse_mapping = {
        ["pipe-elbow"] = "pipe",
        ["pipe-junction"] = "pipe",
        ["pipe-straight"] = "pipe",
    }
    if not corpse then
        local remnant_name = corpse_mapping[base_name] or base_type
        corpse = table.deepcopy(data.raw["corpse"][remnant_name .. "-remnants"])
        remnant_uses_base_corpse = true
    end
    if not corpse then return end
    corpse.name = color_name .. "-color-coded-" .. base_name .. "-remnants"
    corpse.icons = create_color_overlay_icons(corpse, color, base_name)
    corpse.icon = nil
    corpse.order = get_order(corpse, color_name)
    local localised_name = corpse.localised_name
    if not localised_name then localised_name = { "entity-name." .. base_name } end
    corpse.localised_name = { "color-coded.name", localised_name, { "fluid-name." .. color_name } }
    corpse.animation_overlay = table.deepcopy(corpse.animation)
    if remnant_uses_base_corpse then
        base_name = corpse_mapping[base_name] or base_type
    end
    if corpse.animation_overlay.filename then
        corpse.animation_overlay.filename = "__color-coded-pipes__/graphics/" .. base_name .. "/overlay-" .. base_name .. "-remnants.png"
        corpse.animation_overlay.tint = color
    else
        for _, rotated_animation in pairs(corpse.animation_overlay) do
            if rotated_animation.filename then
                rotated_animation.filename = "__color-coded-pipes__/graphics/" .. base_name .. "/overlay-" .. base_name .. "-remnants.png"
                rotated_animation.tint = color
            end
        end
    end
    data:extend { corpse }
end


------------------------------------------------------------------------------------
-- create color-coded versions of pipes, pipe-to-ground, storage tanks, and pumps --
------------------------------------------------------------------------------------

local hide_rainbow_recipes = not settings.startup["color-coded-pipes-show-rainbow-recipes"].value
local hide_fluid_recipes = not settings.startup["color-coded-pipes-show-fluid-recipes"].value

for color_name, color in pairs(rgb_colors) do
    local is_fluid_color = data.raw["fluid"][color_name] and true or false
    local is_rainbow_color = not is_fluid_color
    local built_from_base_item = (hide_rainbow_recipes and is_rainbow_color) or (hide_fluid_recipes and is_fluid_color)
    local base_pipes = {
        { type = "pipe",           name = "pipe" },
        { type = "pipe-to-ground", name = "pipe-to-ground" },
        { type = "storage-tank",   name = "storage-tank" },
        { type = "pump",           name = "pump" },
    }
    if mods["pipe_plus"] then
        table.insert(base_pipes, { type = "pipe-to-ground", name = "pipe-to-ground-2" })
        table.insert(base_pipes, { type = "pipe-to-ground", name = "pipe-to-ground-3" })
    end
    if mods["Flow Control"] then
        table.insert(base_pipes, { type = "storage-tank", name = "pipe-elbow" })
        table.insert(base_pipes, { type = "storage-tank", name = "pipe-junction" })
        table.insert(base_pipes, { type = "storage-tank", name = "pipe-straight" })
    end
    if mods["StorageTank2_2_0"] then
        table.insert(base_pipes, { type = "storage-tank", name = "storage-tank2" })
    end

    for _, base in pairs(base_pipes) do
        create_color_overlay_item(base.type, base.name, color_name, color, built_from_base_item)
        create_color_overlay_recipe(base.type, base.name, color_name, color, built_from_base_item)
        create_color_overlay_entity(base.type, base.name, color_name, color, built_from_base_item)
        create_color_overlay_corpse(base.type, base.name, color_name, color, built_from_base_item)
    end

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
