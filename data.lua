local rainbow_colors = {
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

local color_mode = settings.startup["color-coded-pipes-color-mode"].value

local function replace_dash_with_underscore(str)
    return string.gsub(str, "-", "_")
end

local function analyze_color(r, g, b)
    local color_rgbs = {
        {name = "red", rgb = {255, 0, 0}},
        {name = "orange", rgb = {255, 75, 0}},
        {name = "yellow", rgb = {255, 255, 0}},
        {name = "green", rgb = {0, 128, 0}},
        {name = "blue", rgb = {0, 0, 255}},
        {name = "purple", rgb = {128, 0, 128}},
        {name = "pink", rgb = {255, 192, 203}},
        {name = "black", rgb = {0, 0, 0}},
        {name = "white", rgb = {200, 200, 200}}
    }

    local function distance(color1, color2)
        local sum = 0
        for i = 1, 3 do
            sum = sum + (color1[i] - color2[i])^2
        end
        return math.sqrt(sum)
    end

    local min_distance = math.huge
    local closest_color = "unknown"

    for _, color in ipairs(color_rgbs) do
        local d = distance(color.rgb, {r, g, b})
        if d < min_distance then
            min_distance = d
            closest_color = color.name
        end
    end

    return closest_color
end

local fluid_colors = {}
local restrict_to_fluids = settings.startup["color-coded-pipes-restrict-to-fluids"].value
if restrict_to_fluids then
    for _, fluid in pairs(data.raw["fluid"]) do
        local base_color = fluid.base_color.r and fluid.base_color and fluid.base_color or false
        local flow_color = fluid.flow_color.r and fluid.flow_color and fluid.flow_color or false
        local color = base_color and analyze_color(base_color.r * 255, base_color.g * 255, base_color.b * 255)
        if not color or color == "unknown" then
            log("Unknown color for fluid " .. fluid.name)
        else
            log("Color for fluid " .. fluid.name .. " ( " .. serpent.line(base_color) .. " ) is " .. color)
            fluid_colors[fluid.name] = color
        end
    end
end

local pipe_subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
if not pipe_subgroup then log("subgroup not found") end
pipe_subgroup.name = "color-coded-pipe"
pipe_subgroup.order = pipe_subgroup.order .. "a"

local pipe_to_ground_subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
if not pipe_to_ground_subgroup then log("subgroup not found") end
pipe_to_ground_subgroup.name = "color-coded-pipe-to-ground"
pipe_to_ground_subgroup.order = pipe_to_ground_subgroup.order .. "b"

data:extend({ pipe_subgroup, pipe_to_ground_subgroup })

---@param color_id string
---@param color_name string
---@param color Color?
---@return data.CorpsePrototype
local function make_pipe_remnants(color_id, color_name, color)
    local pipe_remnants = table.deepcopy(data.raw["corpse"]["pipe-remnants"])
    if not pipe_remnants then log("remnants not found") end
    pipe_remnants.name = color_name .. "-pipe-remnants"
    for _, animation in pairs(pipe_remnants.animation) do
        if color then
            local original_animation = table.deepcopy(animation)
            local tinted_mask = table.deepcopy(animation)
            tinted_mask.tint = color
            tinted_mask.blend_mode = "overwrite"
            tinted_mask.filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe//hr-pipe-remnants@0.5x.png"
            tinted_mask.hr_version.filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe//hr-pipe-remnants.png"
            animation.layers = {
                tinted_mask,
                original_animation
            }
        else
            animation.filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe/" .. color_mode .. "/hr-pipe-remnants@0.5x.png"
            animation.hr_version.filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe/" .. color_mode .. "/hr-pipe-remnants.png"
        end
    end
    pipe_remnants.order = pipe_remnants.order .. (recipe_order[color_id] or "")
    return pipe_remnants
end

---@param color_name string
---@param pipe_name string
---@param color Color?
---@return data.PipePrototype
local function make_pipe_entity(color_name, pipe_name, color)
    local pipe = table.deepcopy(data.raw["pipe"]["pipe"])
    if not pipe then log("pipe not found") end
    pipe.name = pipe_name
    pipe.minable.result = pipe_name
    for _, filename in pairs(pipe_filenames) do
        local property_name = replace_dash_with_underscore(filename)
        if color then
            local original_picture = table.deepcopy(pipe.pictures[property_name])
            local tinted_mask = table.deepcopy(pipe.pictures[property_name])
            tinted_mask.tint = color
            tinted_mask.blend_mode = "overwrite"
            tinted_mask.filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe//hr-pipe-" .. filename .. "@0.5x.png"
            tinted_mask.hr_version.filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe//hr-pipe-" .. filename .. ".png"
            pipe.pictures[property_name].layers = {
                tinted_mask,
                original_picture
            }
            pipe.icon = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe//pipe-icon.png"
        else
            pipe.pictures[property_name].filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe/" .. color_mode .. "/hr-pipe-" .. filename .. "@0.5x.png"
            pipe.pictures[property_name].hr_version.filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe/" .. color_mode .. "/hr-pipe-" .. filename .. ".png"
            pipe.icon = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe/" .. color_mode .. "/pipe-icon.png"
        end
    end
    pipe.corpse = color_name .. "-pipe-remnants"
    return pipe
end

---@param color_name string
---@param pipe_to_ground_name string
---@param color Color?
---@return data.PipeToGroundPrototype
local function make_pipe_to_ground_entity(color_name, pipe_to_ground_name, color)
    local pipe_to_ground = table.deepcopy(data.raw["pipe-to-ground"]["pipe-to-ground"])
    if not pipe_to_ground then log("pipe-to-ground not found") end
    pipe_to_ground.name = pipe_to_ground_name
    pipe_to_ground.minable.result = pipe_to_ground_name
    for _, filename in pairs(pipe_to_ground_filenames) do
        local property_name = replace_dash_with_underscore(filename)
        if color then
            local original_picture = table.deepcopy(pipe_to_ground.pictures[property_name])
            local tinted_mask = table.deepcopy(pipe_to_ground.pictures[property_name])
            tinted_mask.tint = color
            tinted_mask.blend_mode = "overwrite"
            tinted_mask.filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe_to_ground//hr-pipe-to-ground-" .. filename .. "@0.5x.png"
            tinted_mask.hr_version.filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe_to_ground//hr-pipe-to-ground-" .. filename .. ".png"
            pipe_to_ground.pictures[property_name].layers = {
                tinted_mask,
                original_picture
            }
            pipe_to_ground.icon = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe_to_ground//pipe-to-ground-icon.png"
        else
            pipe_to_ground.pictures[property_name].filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe_to_ground/" .. color_mode .. "/hr-pipe-to-ground-" .. filename .. "@0.5x.png"
            pipe_to_ground.pictures[property_name].hr_version.filename = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe_to_ground/" .. color_mode .. "/hr-pipe-to-ground-" .. filename .. ".png"
            pipe_to_ground.icon = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe_to_ground/" .. color_mode .. "/pipe-to-ground-icon.png"
        end
    end
    pipe_to_ground.corpse = color_name .. "-pipe-remnants"
    return pipe_to_ground
end

---@param pipe_name string
---@param color_name string
---@param color Color?
---@return data.ItemPrototype
local function make_pipe_item(pipe_name, color_name, color)
    local pipe_item = table.deepcopy(data.raw["item"]["pipe"])
    if not pipe_item then log("item not found") end
    pipe_item.name = pipe_name
    pipe_item.place_result = pipe_name
    if color then
        local original_icon = {
            icon = pipe_item.icon,
            icon_size = pipe_item.icon_size,
            icon_mipmaps = pipe_item.icon_mipmaps
        }
        local tinted_icon = {
            icon = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe/pipe-icon.png",
            icon_size = pipe_item.icon_size,
            icon_mipmaps = pipe_item.icon_mipmaps,
            tint = color,
        }
        pipe_item.icons = {
            tinted_icon,
            original_icon
        }
    else
        pipe_item.icon = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe/" .. color_mode .. "/pipe-icon.png"
    end
    pipe_item.order = pipe_item.order .. (recipe_order[color_name] or "")
    pipe_item.subgroup = "color-coded-pipe"
    return pipe_item
end

---@param pipe_to_ground_name string
---@param color_name string
---@param color Color?
---@return data.ItemPrototype
local function make_pipe_to_ground_item(pipe_to_ground_name, color_name, color)
    local pipe_to_ground_item = table.deepcopy(data.raw["item"]["pipe-to-ground"])
    if not pipe_to_ground_item then log("item not found") end
    pipe_to_ground_item.name = pipe_to_ground_name
    pipe_to_ground_item.place_result = pipe_to_ground_name
    if color then
        local original_icon = {
            icon = pipe_to_ground_item.icon,
            icon_size = pipe_to_ground_item.icon_size,
            icon_mipmaps = pipe_to_ground_item.icon_mipmaps
        }
        local tinted_icon = {
            icon = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe_to_ground/pipe-to-ground-icon.png",
            icon_size = pipe_to_ground_item.icon_size,
            icon_mipmaps = pipe_to_ground_item.icon_mipmaps,
            tint = color,
        }
        pipe_to_ground_item.icons = {
            tinted_icon,
            original_icon
        }
    else
        pipe_to_ground_item.icon = "__color-coded-pipes__/graphics/" .. color_name .. "_pipe_to_ground/" .. color_mode .. "/pipe-to-ground-icon.png"
    end
    pipe_to_ground_item.order = pipe_to_ground_item.order .. (recipe_order[color_name] or "")
    pipe_to_ground_item.subgroup = "color-coded-pipe-to-ground"
    return pipe_to_ground_item
end

---@param pipe_name string
---@return data.RecipePrototype
local function make_pipe_recipe(pipe_name)
    local pipe_recipe = table.deepcopy(data.raw["recipe"]["pipe"])
    if not pipe_recipe then log("recipe not found") end
    pipe_recipe.name = pipe_name
    pipe_recipe.result = pipe_recipe.result and pipe_name or nil
    pipe_recipe.results = pipe_recipe.results and { { type = "item", name = pipe_name, amount = 1 } } or nil
    if pipe_recipe.normal then
        pipe_recipe.normal.result = pipe_recipe.normal.result and pipe_name or nil
        pipe_recipe.normal.results = pipe_recipe.normal.results and { { type = "item", name = pipe_name, amount = 1 } } or nil
    end
    if pipe_recipe.expensive then
        pipe_recipe.expensive.result = pipe_recipe.expensive.result and pipe_name or nil
        pipe_recipe.expensive.results = pipe_recipe.expensive.results and { { type = "item", name = pipe_name, amount = 1 } } or nil
    end
    return pipe_recipe
end

---@param pipe_to_ground_name string
---@return data.RecipePrototype
local function make_pipe_to_ground_recipe(pipe_to_ground_name)
    local pipe_to_ground_recipe = table.deepcopy(data.raw["recipe"]["pipe-to-ground"])
    if not pipe_to_ground_recipe then log("recipe not found") end
    pipe_to_ground_recipe.name = pipe_to_ground_name
    pipe_to_ground_recipe.result = pipe_to_ground_recipe.result and pipe_to_ground_name or nil
    pipe_to_ground_recipe.results = pipe_to_ground_recipe.results and { { type = "item", name = pipe_to_ground_name, amount = 1 } } or nil
    if pipe_to_ground_recipe.normal then
        pipe_to_ground_recipe.normal.result = pipe_to_ground_recipe.normal.result and pipe_to_ground_name or nil
        pipe_to_ground_recipe.normal.results = pipe_to_ground_recipe.normal.results and { { type = "item", name = pipe_to_ground_name, amount = 1 } } or nil
    end
    if pipe_to_ground_recipe.expensive then
        pipe_to_ground_recipe.expensive.result = pipe_to_ground_recipe.expensive.result and pipe_to_ground_name or nil
        pipe_to_ground_recipe.expensive.results = pipe_to_ground_recipe.expensive.results and { { type = "item", name = pipe_to_ground_name, amount = 1 } } or nil
    end
    return pipe_to_ground_recipe
end

---@param color_id string
---@param color_name string
---@param hidden boolean
---@param localised_names table<string, LocalisedString>
---@param color Color?
---@return table<data.CorpsePrototype, data.PipePrototype, data.ItemPrototype, data.RecipePrototype, data.PipeToGroundPrototype, data.ItemPrototype, data.RecipePrototype>
local function make_pipeset(color_id, color_name, hidden, localised_names, color)
    local pipe_name = color_id .. "-" .. data.raw["pipe"]["pipe"].name
    local pipe_to_ground_name = color_id .. "-" .. data.raw["pipe-to-ground"]["pipe-to-ground"].name

    local pipe_remnants = make_pipe_remnants(color_id, color_name, color)
    pipe_remnants.localised_name = localised_names.remnants

    local pipe_entity = make_pipe_entity(color_name, pipe_name, color)
    pipe_entity.localised_name = localised_names.pipe

    local pipe_to_ground_entity = make_pipe_to_ground_entity(color_name, pipe_to_ground_name, color)
    pipe_to_ground_entity.localised_name = localised_names.pipe_to_ground

    local pipe_item = make_pipe_item(pipe_name, color_name, color)
    pipe_item.localised_name = localised_names.pipe

    local pipe_to_ground_item = make_pipe_to_ground_item(pipe_to_ground_name, color_name, color)
    pipe_to_ground_item.localised_name = localised_names.pipe_to_ground

    local pipe_recipe = make_pipe_recipe(pipe_name)
    pipe_recipe.localised_name = localised_names.pipe
    pipe_recipe.hidden = hidden
    pipe_recipe.normal.hidden = hidden
    pipe_recipe.expensive.hidden = hidden

    local pipe_to_ground_recipe = make_pipe_to_ground_recipe(pipe_to_ground_name)
    pipe_to_ground_recipe.localised_name = localised_names.pipe_to_ground
    pipe_to_ground_recipe.hidden = hidden
    -- pipe_to_ground_recipe.normal.hidden = hidden
    -- pipe_to_ground_recipe.expensive.hidden = hidden

    return { pipe_remnants, pipe_entity, pipe_item, pipe_recipe, pipe_to_ground_entity, pipe_to_ground_item, pipe_to_ground_recipe }
end

for color_id, color_name in pairs(rainbow_colors) do

    local hidden = not not restrict_to_fluids
    local localised_names = {
        remnants = { "", { "color-name." .. color_name }, " ", { "entity-name.pipe-remnants" } },
        pipe = { "", { "color-name." .. color_name }, " ", { "entity-name.pipe" } },
        pipe_to_ground = { "", { "color-name." .. color_name }, " ", { "entity-name.pipe-to-ground" } }
    }

    local pipe_set = make_pipeset(color_id, color_name, hidden, localised_names)

    data:extend(pipe_set)

end

-- for color_id, color in pairs(fluid_colors) do

--     local hidden = not restrict_to_fluids
--     local localised_names = {
--         remnants = { "", { "fluid-name." .. color_id }, " ", { "entity-name.pipe-remnants" } },
--         pipe = { "", { "fluid-name." .. color_id }, " ", { "entity-name.pipe" } },
--         pipe_to_ground = { "", { "fluid-name." .. color_id }, " ", { "entity-name.pipe-to-ground" } }
--     }

--     local pipe_set = make_pipeset(color_id, color, hidden, localised_names)

--     data:extend(pipe_set)
-- end

for _, fluid in pairs(data.raw["fluid"]) do

    local color = fluid.base_color
    local hidden = not restrict_to_fluids
    local localised_names = {
        remnants = { "", { "fluid-name." .. fluid.name }, " ", { "entity-name.pipe-remnants" } },
        pipe = { "", { "fluid-name." .. fluid.name }, " ", { "entity-name.pipe" } },
        pipe_to_ground = { "", { "fluid-name." .. fluid.name }, " ", { "entity-name.pipe-to-ground" } }
    }

    local pipe_set = make_pipeset(fluid.name, "mask", hidden, localised_names, color)

    data:extend(pipe_set)

end