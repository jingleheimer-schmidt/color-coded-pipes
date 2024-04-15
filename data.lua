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

local color_mode = settings.startup["color-coded-pipes-color-mode"].value

local function replace_dash_with_underscore(str)
    return string.gsub(str, "-", "_")
end

for _, color in pairs(colors) do

    local pipe_remnants = table.deepcopy(data.raw["corpse"]["pipe-remnants"])
    if not pipe_remnants then log("remnants not found") end
    pipe_remnants.name = color .. "-pipe-remnants"
    for _, animation in pairs(pipe_remnants.animation) do
        animation.filename = "__color-coded-pipes__/graphics/" .. color .. "_pipe/" .. color_mode .. "/hr-pipe-remnants@0.5x.png"
        animation.hr_version.filename = "__color-coded-pipes__/graphics/" .. color .. "_pipe/" .. color_mode .. "/hr-pipe-remnants.png"
    end
    pipe_remnants.order = pipe_remnants.order .. recipe_order[color]

    local pipe = table.deepcopy(data.raw["pipe"]["pipe"])
    if not pipe then log("pipe not found") end
    local pipe_name = color .. "-" .. pipe.name
    pipe.name = pipe_name
    pipe.minable.result = pipe_name
    for _, filename in pairs(pipe_filenames) do
        local property_name = replace_dash_with_underscore(filename)
        pipe.pictures[property_name].filename = "__color-coded-pipes__/graphics/" .. color .. "_pipe/" .. color_mode .. "/hr-pipe-" .. filename .. "@0.5x.png"
        pipe.pictures[property_name].hr_version.filename = "__color-coded-pipes__/graphics/" .. color .. "_pipe/" .. color_mode .. "/hr-pipe-" .. filename .. ".png"
    end
    local pipe_localised_name = { "", { "color-name." .. color }, " ", { "entity-name.pipe" } }
    pipe.localised_name = pipe_localised_name
    pipe.corpse = color .. "-pipe-remnants"
    pipe.icon = "__color-coded-pipes__/graphics/" .. color .. "_pipe/" .. color_mode .. "/pipe-icon.png"

    local pipe_to_ground = table.deepcopy(data.raw["pipe-to-ground"]["pipe-to-ground"])
    if not pipe_to_ground then log("pipe-to-ground not found") end
    local pipe_to_ground_name = color .. "-" .. pipe_to_ground.name
    pipe_to_ground.name = pipe_to_ground_name
    pipe_to_ground.minable.result = pipe_to_ground_name 
    for _, filename in pairs(pipe_to_ground_filenames) do
        local property_name = replace_dash_with_underscore(filename)
        pipe_to_ground.pictures[property_name].filename = "__color-coded-pipes__/graphics/" .. color .. "_pipe_to_ground/" .. color_mode .. "/hr-pipe-to-ground-" .. filename .. "@0.5x.png"
        pipe_to_ground.pictures[property_name].hr_version.filename = "__color-coded-pipes__/graphics/" .. color .. "_pipe_to_ground/" .. color_mode .. "/hr-pipe-to-ground-" .. filename .. ".png"
    end
    local pipe_to_ground_localised_name = { "", { "color-name." .. color }, " ", { "entity-name.pipe-to-ground" } }
    pipe_to_ground.localised_name = pipe_to_ground_localised_name
    pipe_to_ground.corpse = color .. "-pipe-remnants"
    pipe_to_ground.icon = "__color-coded-pipes__/graphics/" .. color .. "_pipe_to_ground/" .. color_mode .. "/pipe-to-ground-icon.png"

    local pipe_subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
    if not pipe_subgroup then log("subgroup not found") end
    pipe_subgroup.name = "color-coded-pipe"
    pipe_subgroup.order = pipe_subgroup.order .. "a"

    local pipe_to_ground_subgroup = table.deepcopy(data.raw["item-subgroup"]["energy-pipe-distribution"])
    if not pipe_to_ground_subgroup then log("subgroup not found") end
    pipe_to_ground_subgroup.name = "color-coded-pipe-to-ground"
    pipe_to_ground_subgroup.order = pipe_to_ground_subgroup.order .. "b"

    local pipe_item = table.deepcopy(data.raw["item"]["pipe"])
    if not pipe_item then log("item not found") end
    pipe_item.name = pipe_name
    pipe_item.place_result = pipe_name
    pipe_item.localised_name = pipe_localised_name
    pipe_item.icon = "__color-coded-pipes__/graphics/" .. color .. "_pipe/" .. color_mode .. "/pipe-icon.png"
    pipe_item.order = pipe_item.order .. recipe_order[color]
    pipe_item.subgroup = "color-coded-pipe"

    local pipe_to_ground_item = table.deepcopy(data.raw["item"]["pipe-to-ground"])
    if not pipe_to_ground_item then log("item not found") end
    pipe_to_ground_item.name = pipe_to_ground_name
    pipe_to_ground_item.place_result = pipe_to_ground_name
    pipe_to_ground_item.localised_name = pipe_to_ground_localised_name
    pipe_to_ground_item.icon = "__color-coded-pipes__/graphics/" .. color .. "_pipe_to_ground/" .. color_mode .. "/pipe-to-ground-icon.png"
    pipe_to_ground_item.order = pipe_to_ground_item.order .. recipe_order[color]
    pipe_to_ground_item.subgroup = "color-coded-pipe-to-ground"

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
    pipe_recipe.localised_name = pipe_localised_name

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
    pipe_to_ground_recipe.localised_name = pipe_to_ground_localised_name

    data:extend({ pipe, pipe_remnants, pipe_item, pipe_recipe, pipe_to_ground, pipe_to_ground_item, pipe_to_ground_recipe, pipe_subgroup, pipe_to_ground_subgroup})

end