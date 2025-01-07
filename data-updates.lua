
-----------------------------------------
-- import util constants and functions --
-----------------------------------------

local color_coded_util = require("color-coded-util")
local pipe_filenames = color_coded_util.pipe_filenames
local pipe_to_ground_filenames = color_coded_util.pipe_to_ground_filenames
local color_order = color_coded_util.recipe_order
local rgb_colors = color_coded_util.rgb_colors
local replace_dash_with_underscore = color_coded_util.replace_dash_with_underscore
local append = color_coded_util.append


------------------------------------------------------------
--- list of base pipes to create color-coded variants of ---
------------------------------------------------------------

local base_entities = {
    { type = "storage-tank",   name = "storage-tank",   order = "-a[1]" },
    { type = "pipe",           name = "pipe",           order = "-b[1]" },
    { type = "pipe-to-ground", name = "pipe-to-ground", order = "-c[1]" },
    { type = "pump",           name = "pump",           order = "-d[1]" },
}
local pipe_plus_entities = {
    { type = "pipe-to-ground", name = "pipe-to-ground-2", order = "-c[2]" },
    { type = "pipe-to-ground", name = "pipe-to-ground-3", order = "-c[3]" },
}
local flow_control_entities = {
    { type = "storage-tank", name = "pipe-elbow",    order = "-c[5]" },
    { type = "storage-tank", name = "pipe-junction", order = "-c[4]" },
    { type = "storage-tank", name = "pipe-straight", order = "-c[6]" },
}
local storage_tank_2_2_0_entities = {
    { type = "storage-tank", name = "storage-tank2", order = "-a[2]" },
}
local zithorian_extra_storage_tanks_entities = {
    { type = "storage-tank", name = "fluid-tank-1x1", order = "-a[3]" },
    { type = "storage-tank", name = "fluid-tank-2x2", order = "-a[4]" },
    { type = "storage-tank", name = "fluid-tank-3x4", order = "-a[5]" },
    { type = "storage-tank", name = "fluid-tank-5x5", order = "-a[6]" },
}

if mods["pipe_plus"] then append(base_entities, pipe_plus_entities) end
if mods["Flow Control"] then append(base_entities, flow_control_entities) end
if mods["StorageTank2_2_0"] then append(base_entities, storage_tank_2_2_0_entities) end
if mods["zithorian-extra-storage-tanks-port"] then append(base_entities, zithorian_extra_storage_tanks_entities) end


---------------------------------------
-- create the color-coded item group --
---------------------------------------

local item_group = table.deepcopy(data.raw["item-group"]["logistics"])
item_group.name = "color-coded-pipes"
item_group.order = "g-pipes"
item_group.icons = { { icon = "__color-coded-pipes__/graphics/icons/crafting-menu-icon/crafting-menu-icon.png", icon_size = 224 } }
item_group.localised_name = { "item-group-name.color-coded-pipes" }
item_group.localised_description = { "item-group-description.color-coded-pipes" }
local regroup_recipes = settings.startup["color-coded-pipes-regroup-recipes"].value
local show_rainbow_recipes = settings.startup["color-coded-pipes-show-rainbow-recipes"].value
local show_fluid_recipes = settings.startup["color-coded-pipes-show-fluid-recipes"].value
if regroup_recipes and not (show_rainbow_recipes or show_fluid_recipes) then
    item_group.icons[1].icon = "__color-coded-pipes__/graphics/icons/crafting-menu-icon/crafting-menu-icon-base.png"
    item_group.localised_name = { "item-group-name.fluid-handling" }
end
data:extend { item_group }


---------------------------------------------------
-- create subgroups for the color-coded variants --
---------------------------------------------------

for _, group in pairs(base_entities) do
    for _, prefix in pairs({ "fluid-", "rainbow-" }) do
        local subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
        if subgroup then
            subgroup.name = prefix .. "color-coded-" .. group.name
            subgroup.group = "color-coded-pipes"
            subgroup.order = subgroup.order .. (prefix == "fluid-" and "-b[fluid]" or "-a[rainbow]") .. group.order
            data:extend { subgroup }
        end
    end
end


-------------------------------------------------------------------------------------------------
-- add a fast_replaceable_group to the base pipes so that all the color-coded pipes inherit it --
-------------------------------------------------------------------------------------------------

for _, base in pairs(base_entities) do
    local entity = data.raw[base.type][base.name]
    if entity then
        local fast_replaceable_group = entity.fast_replaceable_group or base.name
        data.raw[base.type][base.name].fast_replaceable_group = fast_replaceable_group
    end
end


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
    if color_order[color_name] then
        order = order .. "-" .. (color_order[color_name] or "")
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
        item.hidden_in_factoriopedia = true
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
    local result_count = 0
    for _, result in pairs(color_coded_recipe.results) do
        if result.name == base_name then
            result.name = new_recipe_name
            result_count = result.amount or result.amount_max or 1
        end
    end
    if built_from_base_item then
        color_coded_recipe.hidden_in_factoriopedia = true
    end
    local recipe_ingredient_type = settings.startup["color-coded-pipes-recipe-ingredients"].value
    if recipe_ingredient_type == "base-item" then
        color_coded_recipe.ingredients = { { type = "item", name = base_name, amount = result_count } }
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
            elseif overlay_layer.layers then
                overlay_layer.layers[1].filename = "__color-coded-pipes__/graphics/" .. name .. "/overlay-" .. name .. ".png"
                overlay_layer.layers[1].tint = color
                overlay_layer.layers[2] = nil
            end
            prototype.pictures.picture[direction] = { layers = { original_layer, overlay_layer } }
        end
        -- prototype.pictures.fluid_background = nil
        -- prototype.pictures.window_background = nil
        -- prototype.pictures.flow_sprite = nil
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

    for _, base in pairs(base_entities) do
        create_color_overlay_item(base.type, base.name, color_name, color, built_from_base_item)
        create_color_overlay_recipe(base.type, base.name, color_name, color, built_from_base_item)
        create_color_overlay_entity(base.type, base.name, color_name, color, built_from_base_item)
        create_color_overlay_corpse(base.type, base.name, color_name, color, built_from_base_item)
    end

end


-----------------------------------------------
-- move base item recipes to color-coded tab --
-----------------------------------------------

if settings.startup["color-coded-pipes-regroup-recipes"].value then
    for _, base in pairs(base_entities) do
        local base_recipe = data.raw["recipe"][base.name]
        local base_item = data.raw["item"][base.name]
        if base_recipe or base_item then
            local subgroup_name = base_item and base_item.subgroup or base_recipe and base_recipe.subgroup
            local subgroup = subgroup_name and data.raw["item-subgroup"][subgroup_name]
            if subgroup then
                local color_coded_subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
                color_coded_subgroup.name = "color-coded-" .. subgroup.name
                color_coded_subgroup.group = "color-coded-pipes"
                color_coded_subgroup.order = "a[1]" .. subgroup.order
                data:extend { color_coded_subgroup }
                if base_recipe then base_recipe.subgroup = color_coded_subgroup.name end
                if base_item then base_item.subgroup = color_coded_subgroup.name end
            end
        end
    end
end


--------------------------------------------------------
-- add color-coded pipes to the main menu simulations --
--------------------------------------------------------

if settings.startup["color-coded-main-menu-simulations"].value then
    for _, simulation in pairs(data.raw["utility-constants"]["default"].main_menu_simulations) do
        simulation.mods = simulation.mods or {}
        table.insert(simulation.mods, "color-coded-pipes")
    end
end
