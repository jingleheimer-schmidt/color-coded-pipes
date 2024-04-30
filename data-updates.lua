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


---------------------------------
-- create color-coded entities --
---------------------------------

---@param color any
local function create_color_pipe_entity(color)
    local pipe = table.deepcopy(data.raw["pipe"]["pipe"])
    if not pipe then log("pipe entity not found") return end
    local pipe_name = color .. "-" .. pipe.name
    local pipe_localised_name = { "", { "color-name." .. color }, " ", { "entity-name.pipe" } }
    pipe.name = pipe_name
    pipe.minable.result = pipe_name
    for _, filename in pairs(pipe_filenames) do
        local property_name = replace_dash_with_underscore(filename)
        pipe.pictures[property_name].filename = "__color-coded-pipes__/graphics/pipe-" .. filename .. "/" .. color_mode .. "_" .. color .. "-hr-pipe-" .. filename .. "@0.5x.png"
        pipe.pictures[property_name].hr_version.filename = "__color-coded-pipes__/graphics/pipe-" .. filename .. "/" .. color_mode .. "_" .. color .. "-hr-pipe-" .. filename .. ".png"
    end
    pipe.localised_name = pipe_localised_name
    pipe.corpse = color .. "-pipe-remnants"
    pipe.icon = "__color-coded-pipes__/graphics/pipe-icon/" .. color_mode .. "_" .. color .. "-pipe-icon.png"
    data:extend{ pipe }
end

---@param color string
local function create_color_pipe_item(color)
    local pipe = table.deepcopy(data.raw["item"]["pipe"])
    if not pipe then log("pipe item not found") return end
    local pipe_name = color .. "-" .. pipe.name
    local pipe_localised_name = { "", { "color-name." .. color }, " ", { "entity-name.pipe" } }
    pipe.name = pipe_name
    pipe.place_result = pipe_name
    pipe.localised_name = pipe_localised_name
    pipe.icon = "__color-coded-pipes__/graphics/pipe-icon/" .. color_mode .. "_" .. color .. "-pipe-icon.png"
    pipe.order = pipe.order .. recipe_order[color]
    pipe.subgroup = "color-coded-pipe"
    data:extend{ pipe }
end

---@param color string
local function create_color_pipe_recipe(color)
    local pipe = table.deepcopy(data.raw["recipe"]["pipe"])
    if not pipe then log("pipe recipe not found") return end
    local pipe_name = color .. "-" .. pipe.name
    local pipe_localised_name = { "", { "color-name." .. color }, " ", { "entity-name.pipe" } }
    pipe.name = pipe_name
    pipe.result = pipe.result and pipe_name or nil
    pipe.results = pipe.results and { { type = "item", name = pipe_name, amount = 1 } } or nil
    if pipe.normal then
        pipe.normal.result = pipe.normal.result and pipe_name or nil
        pipe.normal.results = pipe.normal.results and { { type = "item", name = pipe_name, amount = 1 } } or nil
    end
    if pipe.expensive then
        pipe.expensive.result = pipe.expensive.result and pipe_name or nil
        pipe.expensive.results = pipe.expensive.results and { { type = "item", name = pipe_name, amount = 1 } } or nil
    end
    pipe.localised_name = pipe_localised_name
    data:extend{ pipe }
end

---@param color string
local function create_color_pipe_to_ground_entity(color)
    local pipe_to_ground = table.deepcopy(data.raw["pipe-to-ground"]["pipe-to-ground"])
    if not pipe_to_ground then log("pipe-to-ground entity not found") return end
    local pipe_to_ground_name = color .. "-" .. pipe_to_ground.name
    local pipe_to_ground_localised_name = { "", { "color-name." .. color }, " ", { "entity-name.pipe-to-ground" } }
    pipe_to_ground.name = pipe_to_ground_name
    pipe_to_ground.minable.result = pipe_to_ground_name
    for _, filename in pairs(pipe_to_ground_filenames) do
        local property_name = replace_dash_with_underscore(filename)
        pipe_to_ground.pictures[property_name].filename = "__color-coded-pipes__/graphics/pipe-to-ground-" .. filename .. "/" .. color_mode .. "_" .. color .. "-hr-pipe-to-ground-" .. filename .. "@0.5x.png"
        pipe_to_ground.pictures[property_name].hr_version.filename = "__color-coded-pipes__/graphics/pipe-to-ground-" .. filename .. "/" .. color_mode .. "_" .. color .. "-hr-pipe-to-ground-" .. filename .. ".png"
    end
    pipe_to_ground.localised_name = pipe_to_ground_localised_name
    -- pipe_to_ground.corpse = color .. "-pipe-to-ground-remnants"
    pipe_to_ground.icon = "__color-coded-pipes__/graphics/pipe-to-ground-icon/" .. color_mode .. "_" .. color .. "-pipe-to-ground-icon.png"
    data:extend{ pipe_to_ground }
end

---@param color string
local function create_color_pipe_to_ground_item(color)
    local pipe_to_ground = table.deepcopy(data.raw["item"]["pipe-to-ground"])
    if not pipe_to_ground then log("pipe-to-ground item not found") return end
    local pipe_to_ground_name = color .. "-" .. pipe_to_ground.name
    local pipe_to_ground_localised_name = { "", { "color-name." .. color }, " ", { "entity-name.pipe-to-ground" } }
    pipe_to_ground.name = pipe_to_ground_name
    pipe_to_ground.place_result = pipe_to_ground_name
    pipe_to_ground.localised_name = pipe_to_ground_localised_name
    pipe_to_ground.icon = "__color-coded-pipes__/graphics/pipe-to-ground-icon/" .. color_mode .. "_" .. color .. "-pipe-to-ground-icon.png"
    pipe_to_ground.order = pipe_to_ground.order .. recipe_order[color]
    pipe_to_ground.subgroup = "color-coded-pipe-to-ground"
    data:extend{ pipe_to_ground }
end

---@param color string
local function create_color_pipe_to_ground_recipe(color)
    local pipe_to_ground = table.deepcopy(data.raw["recipe"]["pipe-to-ground"])
    if not pipe_to_ground then log("pipe-to-ground recipe not found") return end
    local pipe_to_ground_name = color .. "-" .. pipe_to_ground.name
    local pipe_to_ground_localised_name = { "", { "color-name." .. color }, " ", { "entity-name.pipe-to-ground" } }
    pipe_to_ground.name = pipe_to_ground_name
    pipe_to_ground.result = pipe_to_ground.result and pipe_to_ground_name or nil
    pipe_to_ground.results = pipe_to_ground.results and { { type = "item", name = pipe_to_ground_name, amount = 1 } } or nil
    if pipe_to_ground.normal then
        pipe_to_ground.normal.result = pipe_to_ground.normal.result and pipe_to_ground_name or nil
        pipe_to_ground.normal.results = pipe_to_ground.normal.results and { { type = "item", name = pipe_to_ground_name, amount = 1 } } or nil
    end
    if pipe_to_ground.expensive then
        pipe_to_ground.expensive.result = pipe_to_ground.expensive.result and pipe_to_ground_name or nil
        pipe_to_ground.expensive.results = pipe_to_ground.expensive.results and { { type = "item", name = pipe_to_ground_name, amount = 1 } } or nil
    end
    pipe_to_ground.localised_name = pipe_to_ground_localised_name
    data:extend{ pipe_to_ground }
end

---@param color string
local function create_color_storage_tank_entity(color)
    local storage_tank = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
    if not storage_tank then log("storage-tank entity not found") return end
    local storage_tank_name = color .. "-" .. storage_tank.name
    local storage_tank_localised_name = { "", { "color-name." .. color }, " ", { "entity-name.storage-tank" } }
    storage_tank.name = storage_tank_name
    storage_tank.minable.result = storage_tank_name
    storage_tank.pictures.picture.sheets[1].filename = "__color-coded-pipes__/graphics/storage-tank/" .. color_mode .. "_" .. color .. "-storage-tank.png"
    storage_tank.pictures.picture.sheets[1].hr_version.filename = "__color-coded-pipes__/graphics/storage-tank/" .. color_mode .. "_" .. color .. "-hr-storage-tank.png"
    storage_tank.localised_name = storage_tank_localised_name
    -- storage_tank.corpse = color .. "-storage-tank-remnants"
    storage_tank.icon = "__color-coded-pipes__/graphics/storage-tank-icon/" .. color_mode .. "_" .. color .. "-storage-tank-icon.png"
    data:extend{ storage_tank }
end

---@param color string
local function create_color_storage_tank_item(color)
    local storage_tank = table.deepcopy(data.raw["item"]["storage-tank"])
    if not storage_tank then log("storage-tank item not found") return end
    local storage_tank_name = color .. "-" .. storage_tank.name
    local storage_tank_localised_name = { "", { "color-name." .. color }, " ", { "entity-name.storage-tank" } }
    storage_tank.name = storage_tank_name
    storage_tank.place_result = storage_tank_name
    storage_tank.localised_name = storage_tank_localised_name
    storage_tank.icon = "__color-coded-pipes__/graphics/storage-tank-icon/" .. color_mode .. "_" .. color .. "-storage-tank-icon.png"
    storage_tank.order = storage_tank.order .. recipe_order[color]
    storage_tank.subgroup = "color-coded-storage-tank"
    data:extend{ storage_tank }
end

---@param color string
local function create_color_storage_tank_recipe(color)
    local storage_tank = table.deepcopy(data.raw["recipe"]["storage-tank"])
    if not storage_tank then log("storage-tank recipe not found") return end
    local storage_tank_name = color .. "-" .. storage_tank.name
    local storage_tank_localised_name = { "", { "color-name." .. color }, " ", { "entity-name.storage-tank" } }
    storage_tank.name = storage_tank_name
    storage_tank.result = storage_tank.result and storage_tank_name or nil
    storage_tank.results = storage_tank.results and { { type = "item", name = storage_tank_name, amount = 1 } } or nil
    if storage_tank.normal then
        storage_tank.normal.result = storage_tank.normal.result and storage_tank_name or nil
        storage_tank.normal.results = storage_tank.normal.results and { { type = "item", name = storage_tank_name, amount = 1 } } or nil
    end
    if storage_tank.expensive then
        storage_tank.expensive.result = storage_tank.expensive.result and storage_tank_name or nil
        storage_tank.expensive.results = storage_tank.expensive.results and { { type = "item", name = storage_tank_name, amount = 1 } } or nil
    end
    storage_tank.localised_name = storage_tank_localised_name
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

---@param color string
local function create_color_pipe_remnants(color)
    local pipe_remnants = table.deepcopy(data.raw["corpse"]["pipe-remnants"])
    if not pipe_remnants then log("remnants not found") end
    pipe_remnants.name = color .. "-pipe-remnants"
    for _, animation in pairs(pipe_remnants.animation) do
        animation.filename = "__color-coded-pipes__/graphics/pipe-remnants/" .. color_mode .. "_" .. color .. "-pipe-remnants.png"
        animation.hr_version.filename = "__color-coded-pipes__/graphics/pipe-remnants/" .. color_mode .. "_" .. color .. "-hr-pipe-remnants.png"
    end
    pipe_remnants.order = pipe_remnants.order .. recipe_order[color]
    data:extend{ pipe_remnants }
end


------------------------------------
-- create variants for each color --
------------------------------------

for _, color in pairs(colors) do

    data.raw["storage-tank"]["storage-tank"].fast_replaceable_group = "storage-tank"

    create_color_pipe_remnants(color)

    create_color_pipe_entity(color)
    create_color_pipe_item(color)
    create_color_pipe_recipe(color)

    create_color_pipe_to_ground_entity(color)
    create_color_pipe_to_ground_item(color)
    create_color_pipe_to_ground_recipe(color)

    create_color_storage_tank_entity(color)
    create_color_storage_tank_item(color)
    create_color_storage_tank_recipe(color)

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
