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

local pipe_filenames = {
    "corner-down-left",
    "corner-down-right",
    "corner-up-left",
    "corner-up-right",
    "cross",
    "ending-down",
    "ending-left",
    "ending-right",
    "ending-up",
    "straight-horizontal-window",
    "straight-horizontal",
    "straight-vertical-single",
    "straight-vertical-window",
    "straight-vertical",
    "t-down",
    "t-left",
    "t-right",
    "t-up",
}

local pipe_to_ground_filenames = {
    "down",
    "left",
    "right",
    "up",
}

local recipe_order = {
    ["red"] = "a",
    ["orange"] = "b",
    ["yellow"] = "c",
    ["green"] = "d",
    ["blue"] = "e",
    ["purple"] = "f",
    ["pink"] = "g",
    ["black"] = "h",
    ["white"] = "i",
}

local rgb_colors = {
    -- red = { r = 0.5, g = 0, b = 0 },
    -- orange = { r = 0.5, g = 0.25, b = 0 },
    -- yellow = { r = 0.5, g = 0.5, b = 0 },
    -- green = { r = 0, g = 0.5, b = 0 },
    -- blue = { r = 0, g = 0, b = 0.5 },
    -- purple = { r = 0.25, g = 0, b = 0.5 },
    -- pink = { r = 0.5, g = 0, b = 0.5 },
    -- white = { r = 0.5, g = 0.5, b = 0.5 },
    -- black = { r = 0, g = 0, b = 0 },
    red = settings.startup["color-coded-pipes-red"].value,
    orange = settings.startup["color-coded-pipes-orange"].value,
    yellow = settings.startup["color-coded-pipes-yellow"].value,
    green = settings.startup["color-coded-pipes-green"].value,
    blue = settings.startup["color-coded-pipes-blue"].value,
    purple = settings.startup["color-coded-pipes-purple"].value,
    pink = settings.startup["color-coded-pipes-pink"].value,
    white = settings.startup["color-coded-pipes-white"].value,
    black = settings.startup["color-coded-pipes-black"].value,
}

for _, fluid in pairs(data.raw["fluid"]) do
    if fluid.base_color then
        rgb_colors[fluid.name] = fluid.base_color
    end
end

local color_mode = settings.startup["color-coded-pipes-color-mode"].value

local function replace_dash_with_underscore(str)
    return string.gsub(str, "-", "_")
end

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

    color.a = 0.55
    local built_from_base_item = data.raw["fluid"][name] and true or false

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

local pipe_painting_planner = table.deepcopy(data.raw["selection-tool"]["selection-tool"])
pipe_painting_planner.name = "pipe-painting-planner"
pipe_painting_planner.entity_type_filters = { "pipe", "pipe-to-ground", "storage-tank" }

data:extend{ pipe_painting_planner }

local pipe_painting_shortcut = table.deepcopy(data.raw["shortcut"]["give-upgrade-planner"])
pipe_painting_shortcut.name = "give-pipe-painting-shortcut"
pipe_painting_shortcut.item_to_spawn = "pipe-painting-planner"

data:extend{ pipe_painting_shortcut }


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
                            name = pipe_color .. "-pipe",
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
                            name = pipe_color .. "-pipe-to-ground",
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
                            name = pipe_color .. "-storage-tank",
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
