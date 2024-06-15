local colors = {
    ["red"] = "red",
    ["orange"] = "orange",
    ["yellow"] = "yellow",
    ["green"] = "green",
    ["blue"] = "blue",
    ["purple"] = "purple",
    ["pink"] = "pink",
    ["black"] = "black",
    ["white"] = "white",
}


local color_mode = settings.startup["color-coded-pipes-color-mode"].value


local color_coded_util = require("color-coded-util")
local pipe_filenames = color_coded_util.pipe_filenames
local pipe_to_ground_filenames = color_coded_util.pipe_to_ground_filenames
local recipe_order = color_coded_util.recipe_order
local rgb_colors = color_coded_util.rgb_colors
local replace_dash_with_underscore = color_coded_util.replace_dash_with_underscore

---------------------------------------------------
-- create subgroups for the color-coded variants --
---------------------------------------------------

local pipe_subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
if not pipe_subgroup then log("subgroup not found") end
pipe_subgroup.name = "color-coded-pipe"
pipe_subgroup.order = pipe_subgroup.order .. "a"

local pipe_to_ground_subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
if not pipe_to_ground_subgroup then log("subgroup not found") end
pipe_to_ground_subgroup.name = "color-coded-pipe-to-ground"
pipe_to_ground_subgroup.order = pipe_to_ground_subgroup.order .. "b"

local storage_tank_subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
if not storage_tank_subgroup then log("subgroup not found") end
storage_tank_subgroup.name = "color-coded-storage-tank"
storage_tank_subgroup.order = storage_tank_subgroup.order .. "c"

data:extend{ pipe_subgroup, pipe_to_ground_subgroup, storage_tank_subgroup }

local fluid_color_pipe_subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
if not fluid_color_pipe_subgroup then log("subgroup not found") end
fluid_color_pipe_subgroup.name = "fluid-color-coded-pipe"
fluid_color_pipe_subgroup.order = fluid_color_pipe_subgroup.order .. "a[fluid]"

local fluid_color_pipe_to_ground_subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
if not fluid_color_pipe_to_ground_subgroup then log("subgroup not found") end
fluid_color_pipe_to_ground_subgroup.name = "fluid-color-coded-pipe-to-ground"
fluid_color_pipe_to_ground_subgroup.order = fluid_color_pipe_to_ground_subgroup.order .. "b[fluid]"

local fluid_color_storage_tank_subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
if not fluid_color_storage_tank_subgroup then log("subgroup not found") end
fluid_color_storage_tank_subgroup.name = "fluid-color-coded-storage-tank"
fluid_color_storage_tank_subgroup.order = fluid_color_storage_tank_subgroup.order .. "c[fluid]"

data:extend{ fluid_color_pipe_subgroup, fluid_color_pipe_to_ground_subgroup, fluid_color_storage_tank_subgroup }


---------------------------------
-- create color-coded entities --
---------------------------------

data.raw["storage-tank"]["storage-tank"].fast_replaceable_group = "storage-tank"

---@param item data.ItemPrototype
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


---@param pipe data.ItemPrototype | data.PipePrototype
---@param fluid_color Color
---@return data.IconData
local function create_fluid_color_pipe_icons(pipe, fluid_color)
    local icon_base = {
        icon = pipe.icon,
        icon_size = pipe.icon_size,
        icon_mipmaps = pipe.icon_mipmaps
    }
    local icon_overlay = table.deepcopy(icon_base)
    icon_overlay.tint = fluid_color
    icon_overlay.icon = "__color-coded-pipes__/graphics/overlay-pipe-icon/overlay-pipe-icon.png"
    return { icon_base, icon_overlay }
end


---@param name string
---@param color Color
---@param built_from_base_item boolean
local function create_fluid_color_pipe_entity(name, color, built_from_base_item)

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

    pipe.icons = create_fluid_color_pipe_icons(pipe, color)

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
local function create_fluid_color_pipe_item(name, color)

    local pipe_item = table.deepcopy(data.raw["item"]["pipe"])
    if not pipe_item then log("pipe item not found") return end
    local pipe_item_name = name .. "-pipe"
    pipe_item.name = pipe_item_name
    pipe_item.place_result = pipe_item_name
    pipe_item.localised_name = { "color-coded.name", { "entity-name.pipe" }, { "fluid-name." .. name } }
    pipe_item.icons = create_fluid_color_pipe_icons(pipe_item, color)
    pipe_item.order = get_order(pipe_item, name)
    pipe_item.subgroup = get_subgroup("pipe", name)
    data:extend{ pipe_item }
end

---@param name string
---@param built_from_base_item boolean
local function create_fluid_color_pipe_recipe(name, built_from_base_item)

    local pipe_recipe = table.deepcopy(data.raw["recipe"]["pipe"])
    if not pipe_recipe then log("pipe recipe not found") return end
    local pipe_recipe_name = name .. "-pipe"
    pipe_recipe.name = pipe_recipe_name
    pipe_recipe.result = pipe_recipe.result and pipe_recipe_name or nil
    pipe_recipe.results = pipe_recipe.results and { { type = "item", name = pipe_recipe_name, amount = 1 } } or nil
    if built_from_base_item then
        pipe_recipe.hidden = true
    end
    if pipe_recipe.normal then
        pipe_recipe.normal.result = pipe_recipe.normal.result and pipe_recipe_name or nil
        pipe_recipe.normal.results = pipe_recipe.normal.results and { { type = "item", name = pipe_recipe_name, amount = 1 } } or nil
        if built_from_base_item then
            pipe_recipe.normal.hidden = true
        end
    end
    if pipe_recipe.expensive then
        pipe_recipe.expensive.result = pipe_recipe.expensive.result and pipe_recipe_name or nil
        pipe_recipe.expensive.results = pipe_recipe.expensive.results and { { type = "item", name = pipe_recipe_name, amount = 1 } } or nil
        if built_from_base_item then
            pipe_recipe.expensive.hidden = true
        end
    end
    pipe_recipe.localised_name = { "color-coded.name", { "entity-name.pipe" }, { "fluid-name." .. name } }
    data:extend{ pipe_recipe }
end

---@param pipe_to_ground data.ItemPrototype | data.PipeToGroundPrototype
---@param color Color
---@return data.IconData
local function create_fluid_color_pipe_to_ground_icons(pipe_to_ground, color)
    local icon_base = {
        icon = pipe_to_ground.icon,
        icon_size = pipe_to_ground.icon_size,
        icon_mipmaps = pipe_to_ground.icon_mipmaps
    }
    local icon_overlay = table.deepcopy(icon_base)
    icon_overlay.tint = color
    icon_overlay.icon = "__color-coded-pipes__/graphics/overlay-pipe-to-ground-icon/overlay-pipe-to-ground-icon.png"
    return { icon_base, icon_overlay }
end

---@param name string
---@param color Color
---@param placeable_by_base_item boolean
local function create_fluid_color_pipe_to_ground_entity(name, color, placeable_by_base_item)

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
    pipe_to_ground.icons = create_fluid_color_pipe_to_ground_icons(pipe_to_ground, color)

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

---@param name string
---@param color Color
local function create_fluid_color_pipe_to_ground_item(name, color)

    local pipe_to_ground_item = table.deepcopy(data.raw["item"]["pipe-to-ground"])
    if not pipe_to_ground_item then log("pipe-to-ground item not found") return end
    local pipe_to_ground_item_name = name .. "-pipe-to-ground"
    pipe_to_ground_item.name = pipe_to_ground_item_name
    pipe_to_ground_item.place_result = pipe_to_ground_item_name
    pipe_to_ground_item.localised_name = { "color-coded.name", { "entity-name.pipe-to-ground" }, { "fluid-name." .. name } }
    pipe_to_ground_item.icons = create_fluid_color_pipe_to_ground_icons(pipe_to_ground_item, color)
    pipe_to_ground_item.order = get_order(pipe_to_ground_item, name)
    pipe_to_ground_item.subgroup = get_subgroup("pipe-to-ground", name)
    data:extend{ pipe_to_ground_item }
end

---@param name string
---@param built_from_base_item boolean
local function create_fluid_color_pipe_to_ground_recipe(name, built_from_base_item)

    local pipe_to_ground_recipe = table.deepcopy(data.raw["recipe"]["pipe-to-ground"])
    if not pipe_to_ground_recipe then log("pipe-to-ground recipe not found") return end
    local pipe_to_ground_recipe_name = name .. "-pipe-to-ground"
    pipe_to_ground_recipe.name = pipe_to_ground_recipe_name
    pipe_to_ground_recipe.result = pipe_to_ground_recipe.result and pipe_to_ground_recipe_name or nil
    pipe_to_ground_recipe.results = pipe_to_ground_recipe.results and { { type = "item", name = pipe_to_ground_recipe_name, amount = 1 } } or nil
    if built_from_base_item then
        pipe_to_ground_recipe.hidden = true
    end
    if pipe_to_ground_recipe.normal then
        pipe_to_ground_recipe.normal.result = pipe_to_ground_recipe.normal.result and pipe_to_ground_recipe_name or nil
        pipe_to_ground_recipe.normal.results = pipe_to_ground_recipe.normal.results and { { type = "item", name = pipe_to_ground_recipe_name, amount = 1 } } or nil
        if built_from_base_item then
            pipe_to_ground_recipe.normal.hidden = true
        end
    end
    if pipe_to_ground_recipe.expensive then
        pipe_to_ground_recipe.expensive.result = pipe_to_ground_recipe.expensive.result and pipe_to_ground_recipe_name or nil
        pipe_to_ground_recipe.expensive.results = pipe_to_ground_recipe.expensive.results and { { type = "item", name = pipe_to_ground_recipe_name, amount = 1 } } or nil
        if built_from_base_item then
            pipe_to_ground_recipe.expensive.hidden = true
        end
    end
    pipe_to_ground_recipe.localised_name = { "color-coded.name", { "entity-name.pipe-to-ground" }, { "fluid-name." .. name } }
    data:extend{ pipe_to_ground_recipe }
end

---@param storage_tank data.ItemPrototype | data.StorageTankPrototype
---@param fluid_color Color
---@return data.IconData
local function create_fluid_color_storage_tank_icons(storage_tank, fluid_color)
    local icon_base = {
        icon = storage_tank.icon,
        icon_size = storage_tank.icon_size,
        icon_mipmaps = storage_tank.icon_mipmaps
    }
    local icon_overlay = table.deepcopy(icon_base)
    icon_overlay.tint = fluid_color
    icon_overlay.icon = "__color-coded-pipes__/graphics/overlay-storage-tank-icon/overlay-storage-tank-icon.png"
    return { icon_base, icon_overlay }
end

---@param fluid_name string
---@param fluid_color Color
---@param placeable_by_base_item boolean
local function create_fluid_color_storage_tank_entity(fluid_name, fluid_color, placeable_by_base_item)

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
    storage_tank.icons = create_fluid_color_storage_tank_icons(storage_tank, fluid_color)

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
local function create_fluid_color_storage_tank_item(name, color)

    local storage_tank = table.deepcopy(data.raw["item"]["storage-tank"])
    if not storage_tank then log("storage-tank item not found") return end
    local storage_tank_name = name .. "-storage-tank"
    storage_tank.name = storage_tank_name
    storage_tank.place_result = storage_tank_name
    storage_tank.localised_name = { "color-coded.name", { "entity-name.storage-tank" }, { "fluid-name." .. name } }
    storage_tank.icons = create_fluid_color_storage_tank_icons(storage_tank, color)
    storage_tank.order = get_order(storage_tank, name)
    storage_tank.subgroup = get_subgroup("storage-tank", name)
    data:extend{ storage_tank }
end

---@param name string
---@param built_from_base_item boolean
local function create_fluid_color_storage_tank_recipe(name, built_from_base_item)

    local storage_tank = table.deepcopy(data.raw["recipe"]["storage-tank"])
    if not storage_tank then log("storage-tank recipe not found") return end
    local storage_tank_name = name .. "-storage-tank"
    storage_tank.name = storage_tank_name
    storage_tank.result = storage_tank.result and storage_tank_name or nil
    storage_tank.results = storage_tank.results and { { type = "item", name = storage_tank_name, amount = 1 } } or nil
    if built_from_base_item then
        storage_tank.hidden = true
    end
    if storage_tank.normal then
        storage_tank.normal.result = storage_tank.normal.result and storage_tank_name or nil
        storage_tank.normal.results = storage_tank.normal.results and { { type = "item", name = storage_tank_name, amount = 1 } } or nil
        if built_from_base_item then
            storage_tank.normal.hidden = true
        end
    end
    if storage_tank.expensive then
        storage_tank.expensive.result = storage_tank.expensive.result and storage_tank_name or nil
        storage_tank.expensive.results = storage_tank.expensive.results and { { type = "item", name = storage_tank_name, amount = 1 } } or nil
        if built_from_base_item then
            storage_tank.expensive.hidden = true
        end
    end
    storage_tank.localised_name = { "color-coded.name", { "entity-name.storage-tank" }, { "fluid-name." .. name } }
    for _, technology in pairs(data.raw["technology"]) do
        if technology.effects then
            for _, effect in pairs(technology.effects) do
                if effect.type == "unlock-recipe" and effect.recipe == "storage-tank" then
                    table.insert(technology.effects, { type = "unlock-recipe", recipe = storage_tank_name })
                end
            end
        end
        if technology.normal and technology.normal.effects then
            for _, effect in pairs(technology.normal.effects) do
                if effect.type == "unlock-recipe" and effect.recipe == "storage-tank" then
                    table.insert(technology.normal.effects, { type = "unlock-recipe", recipe = storage_tank_name })
                end
            end
        end
        if technology.expensive and technology.expensive.effects then
            for _, effect in pairs(technology.expensive.effects) do
                if effect.type == "unlock-recipe" and effect.recipe == "storage-tank" then
                    table.insert(technology.expensive.effects, { type = "unlock-recipe", recipe = storage_tank_name })
                end
            end
        end
    end
    data:extend{ storage_tank }
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
    -- if show_fluid_recipes and is_fluid_color then
    --     create_fluid_color_pipe_recipe(name, built_from_base_item)
    --     create_fluid_color_pipe_to_ground_recipe(name, built_from_base_item)
    --     create_fluid_color_storage_tank_recipe(name, built_from_base_item)
    -- end
    -- if show_rainbow_recipes and not is_fluid_color then
    --     create_fluid_color_pipe_recipe(name, built_from_base_item)
    --     create_fluid_color_pipe_to_ground_recipe(name, built_from_base_item)
    --     create_fluid_color_storage_tank_recipe(name, built_from_base_item)
    -- end

    create_fluid_color_pipe_entity(name, color, built_from_base_item)
    create_fluid_color_pipe_item(name, color)
    create_fluid_color_pipe_recipe(name, built_from_base_item)

    create_fluid_color_pipe_to_ground_entity(name, color, built_from_base_item)
    create_fluid_color_pipe_to_ground_item(name, color)
    create_fluid_color_pipe_to_ground_recipe(name, built_from_base_item)

    create_fluid_color_storage_tank_entity(name, color, built_from_base_item)
    create_fluid_color_storage_tank_item(name, color)
    create_fluid_color_storage_tank_recipe(name, built_from_base_item)

end

local base_filter_items = {
    "pipe",
    "pipe-to-ground",
    "storage-tank",
}
local entity_filters = {}
local alt_entity_filters = {}
local reverse_entity_filters = {}
local alt_reverse_entity_filters = {}

for _, name in pairs(base_filter_items) do
    table.insert(entity_filters, name)
    table.insert(alt_entity_filters, name)
    table.insert(reverse_entity_filters, name)
    table.insert(alt_reverse_entity_filters, name)
end
for name, _ in pairs(rgb_colors) do
    table.insert(entity_filters, name .. "-pipe")
    table.insert(entity_filters, name .. "-pipe-to-ground")
    table.insert(entity_filters, name .. "-storage-tank")
    table.insert(alt_entity_filters, name .. "-pipe")
    table.insert(alt_entity_filters, name .. "-pipe-to-ground")
    table.insert(alt_entity_filters, name .. "-storage-tank")
    table.insert(reverse_entity_filters, name .. "-pipe")
    table.insert(reverse_entity_filters, name .. "-pipe-to-ground")
    table.insert(reverse_entity_filters, name .. "-storage-tank")
    table.insert(alt_reverse_entity_filters, name .. "-pipe")
    table.insert(alt_reverse_entity_filters, name .. "-pipe-to-ground")
    table.insert(alt_reverse_entity_filters, name .. "-storage-tank")
end

local pipe_painting_planner = table.deepcopy(data.raw["selection-tool"]["selection-tool"])
pipe_painting_planner.name = "pipe-painting-planner"
-- pipe_painting_planner.entity_type_filters = { "pipe", "pipe-to-ground", "storage-tank" }
-- pipe_painting_planner.alt_entity_type_filters = { "pipe", "pipe-to-ground", "storage-tank" }
pipe_painting_planner.entity_filters = entity_filters
pipe_painting_planner.alt_entity_filters = alt_entity_filters
pipe_painting_planner.selection_mode = { "friend", "upgrade", }
pipe_painting_planner.alt_selection_mode = { "friend", "cancel-upgrade", }

-- pipe_painting_planner.reverse_entity_type_filters = { "pipe", "pipe-to-ground", "storage-tank" }
-- pipe_painting_planner.alt_reverse_entity_type_filters = { "pipe", "pipe-to-ground", "storage-tank" }
pipe_painting_planner.reverse_entity_filters = reverse_entity_filters
pipe_painting_planner.alt_reverse_entity_filters = alt_reverse_entity_filters
pipe_painting_planner.reverse_selection_mode = { "friend", "upgrade", }
pipe_painting_planner.alt_reverse_selection_mode = { "friend", "upgrade", }

pipe_painting_planner.flags = {
    "not-stackable",
    "spawnable",
    -- "only-in-cursor",
    "mod-openable",
}
pipe_painting_planner.icon = "__color-coded-pipes__/graphics/selection-tool-icon/selection-tool-icon.png"
pipe_painting_planner.order = "c[automated-construction]-p[pipe-painting-planner]"
pipe_painting_planner.subgroup = data.raw["upgrade-item"]["upgrade-planner"].subgroup
-- pipe_painting_planner.icons = {
--     {
--         icon = pipe_painting_planner.icon,
--         icon_size = pipe_painting_planner.icon_size,
--         icon_mipmaps = pipe_painting_planner.icon_mipmaps,
--         tint = { r = 0.8, g = 0.5, b = 0.2, a = 1.0 }
--     }
-- }

data:extend { pipe_painting_planner }

local pipe_painting_shortcut = table.deepcopy(data.raw["shortcut"]["give-upgrade-planner"])
pipe_painting_shortcut.name = "give-pipe-painting-shortcut"
pipe_painting_shortcut.item_to_spawn = "pipe-painting-planner"
pipe_painting_shortcut.localised_name = { "shortcut-name.give-pipe-painting-shortcut" }
pipe_painting_shortcut.localised_description = { "shortcut-description.give-pipe-painting-shortcut" }
pipe_painting_shortcut.associated_control_input = "pipe-painting-custom-input"
pipe_painting_shortcut.order = "b[blueprints]-p[pipe-painting-planner]"
pipe_painting_shortcut.style = "default"
pipe_painting_shortcut.icon.filename = "__color-coded-pipes__/graphics/selection-planner-shortcut/pipe-painting-planner-x32-white.png"
pipe_painting_shortcut.small_icon.filename = "__color-coded-pipes__/graphics/selection-planner-shortcut/pipe-painting-planner-x24-white.png"
pipe_painting_shortcut.disabled_small_icon.filename = "__color-coded-pipes__/graphics/selection-planner-shortcut/pipe-painting-planner-x24.png"

data:extend{ pipe_painting_shortcut }

local pipe_painting_custom_input = {
    type = "custom-input",
    name = "pipe-painting-custom-input",
    key_sequence = "ALT + P",
    action = "spawn-item",
    item_to_spawn = "pipe-painting-planner",
}
data:extend{ pipe_painting_custom_input }

local delete_pipe_painting_planner_custom_input = {
    type = "custom-input",
    name = "delete-pipe-painting-planner",
    key_sequence = "mouse-button-2",
    action = "lua",
}
data:extend{ delete_pipe_painting_planner_custom_input }


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
