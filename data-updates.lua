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


-- Converts HSL to RGB
function hsl_to_rgb(h, s, l)
	if s == 0 then return l,l,l end
	h, s, l = h/256*6, s/255, l/255
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end
	return math.ceil((r+m)*256),math.ceil((g+m)*256),math.ceil((b+m)*256)
end

-- Converts RGB to HSL
function rgb_to_hsl(r, g, b)
    r, g, b = r/256, g/256, b/256
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, l = 0, 0, (max+min)/2
    if max == min then return 0, 0, l*255 end
    local d = max-min
    s = l > .5 and d/(2-max-min) or d/(max+min)
    if max == r then h = (g-b)/d+(g < b and 6 or 0)
    elseif max == g then h = (b-r)/d+2
    else h = (r-g)/d+4
    end
    return math.ceil(h*256/6), math.ceil(s*255), math.ceil(l*255)
end



local function create_fluid_color_pipe_entity(fluid_name, fluid_color)

    local pipe = table.deepcopy(data.raw["pipe"]["pipe"])
    if not pipe then log("pipe entity not found") return end
    local pipe_name = fluid_name .. "-pipe"
    local pipe_localised_name = { "", { "fluid-name." .. fluid_name }, " ", { "entity-name.pipe" } }
    pipe.name = pipe_name
    pipe.minable.result = pipe_name
    for _, filename in pairs(pipe_filenames) do
        local property_name = replace_dash_with_underscore(filename)
        local original_layer = table.deepcopy(pipe.pictures[property_name]) ---@type data.Sprite
        local overlay_layer = table.deepcopy(pipe.pictures[property_name]) ---@type data.Sprite
        overlay_layer.filename = "__color-coded-pipes__/graphics/overlay-pipe-" .. filename .. "/overlay-hr-pipe-" .. filename .. "@0.5x.png"
        overlay_layer.hr_version.filename = "__color-coded-pipes__/graphics/overlay-pipe-" .. filename .. "/overlay-hr-pipe-" .. filename .. ".png"
        overlay_layer.tint = fluid_color
        overlay_layer.hr_version.tint = fluid_color
        pipe.pictures[property_name] = {}
        pipe.pictures[property_name].layers = { original_layer, overlay_layer }
    end
    pipe.localised_name = pipe_localised_name
    -- pipe.corpse = name .. "-pipe-remnants"
    local icon_base = {
        icon = pipe.icon,
        icon_size = pipe.icon_size,
        icon_mipmaps = pipe.icon_mipmaps
    }
    local icon_overlay = table.deepcopy(icon_base)
    icon_overlay.tint = fluid_color
    icon_overlay.icon = "__color-coded-pipes__/graphics/overlay-pipe-icon/overlay-pipe-icon.png"
    pipe.icons = { icon_base, icon_overlay }

    data:extend{ pipe }
end

local fluids = data.raw["fluid"]
for _, fluid in pairs(fluids) do
    local fluid_color = fluid.base_color
    local fluid_name = fluid.name

    if not (fluid_color.r and fluid_color.g and fluid_color.b) then
        log("fluid " .. fluid_name .. " has no color")
        goto next_fluid
    end

    -- local h, s, l = rgb_to_hsl(color.r, color.g, color.b)
    -- -- -- l = 75
    -- color.r, color.g, color.b = hsl_to_rgb(h, s, l)

    fluid_color.a = 0.75

    create_fluid_color_pipe_entity(fluid_name, fluid_color)

    -- local pipe = table.deepcopy(data.raw["pipe"]["pipe"])
    -- if not pipe then log("pipe entity not found") return end
    -- local pipe_name = fluid_name .. "-pipe"
    -- local pipe_localised_name = { "", { "fluid-name." .. fluid_name }, " ", { "entity-name.pipe" } }
    -- pipe.name = pipe_name
    -- pipe.minable.result = pipe_name
    -- for _, filename in pairs(pipe_filenames) do
    --     local property_name = replace_dash_with_underscore(filename)
    --     local original_layer = table.deepcopy(pipe.pictures[property_name]) ---@type data.Sprite
    --     local overlay_layer = table.deepcopy(pipe.pictures[property_name]) ---@type data.Sprite
    --     -- overlay_layer.filename = "__color-coded-pipes__/graphics/overlay-pipe-" .. filename .. "/overlay-hr-pipe-" .. filename .. "@0.5x.png"
    --     -- overlay_layer.hr_version.filename = "__color-coded-pipes__/graphics/overlay-pipe-" .. filename .. "/overlay-hr-pipe-" .. filename .. ".png"
    --     -- overlay_layer.tint = color
    --     -- overlay_layer.hr_version.tint = color
    --     -- -- pipe.pictures[property_name].layers = { overlay_layer, original_layer }
    --     -- pipe.pictures[property_name].layers = { overlay_layer }

    --     local layers = {
    --         [2] = {
    --             filename = "__color-coded-pipes__/graphics/overlay-pipe-" .. filename .. "/overlay-hr-pipe-" .. filename .. "@0.5x.png",
    --             hr_version = {
    --                 filename = "__color-coded-pipes__/graphics/overlay-pipe-" .. filename .. "/overlay-hr-pipe-" .. filename .. ".png",
    --                 tint = fluid_color,
    --                 size = original_layer.hr_version.size,
    --                 shift = original_layer.hr_version.shift,
    --                 scale = original_layer.hr_version.scale,
    --                 x = original_layer.hr_version.x,
    --                 y = original_layer.hr_version.y,
    --                 position = original_layer.hr_version.position,
    --                 width = original_layer.hr_version.width,
    --                 height = original_layer.hr_version.height,
    --                 blend_mode = "normal",
    --                 -- draw_as_glow = true,
    --             },
    --             tint = fluid_color,
    --             size = original_layer.size,
    --             shift = original_layer.shift,
    --             scale = original_layer.scale,
    --             x = original_layer.x,
    --             y = original_layer.y,
    --             position = original_layer.position,
    --             width = original_layer.width,
    --             height = original_layer.height,
    --             blend_mode = "normal",
    --             -- draw_as_glow = true,
    --         },
    --         [1] = {
    --             filename = original_layer.filename,
    --             hr_version = {
    --                 filename = original_layer.hr_version.filename,
    --                 tint = original_layer.hr_version.tint,
    --                 size = original_layer.hr_version.size,
    --                 shift = original_layer.hr_version.shift,
    --                 scale = original_layer.hr_version.scale,
    --                 x = original_layer.hr_version.x,
    --                 y = original_layer.hr_version.y,
    --                 position = original_layer.hr_version.position,
    --                 width = original_layer.hr_version.width,
    --                 height = original_layer.hr_version.height,
    --             },
    --             tint = original_layer.tint,
    --             size = original_layer.size,
    --             shift = original_layer.shift,
    --             scale = original_layer.scale,
    --             x = original_layer.x,
    --             y = original_layer.y,
    --             position = original_layer.position,
    --             width = original_layer.width,
    --             height = original_layer.height,
    --         }
    --     }
    --     pipe.pictures[property_name] = nil
    --     pipe.pictures[property_name] = { layers = layers }
    -- end
    -- pipe.localised_name = pipe_localised_name
    -- -- pipe.corpse = name .. "-pipe-remnants"
    -- local icon_base = {
    --     icon = pipe.icon,
    --     icon_size = pipe.icon_size,
    --     icon_mipmaps = pipe.icon_mipmaps
    -- }
    -- local icon_overlay = table.deepcopy(icon_base)
    -- icon_overlay.tint = fluid_color
    -- icon_overlay.icon = "__color-coded-pipes__/graphics/overlay-pipe-icon/overlay-pipe-icon.png"
    -- pipe.icons = { icon_base, icon_overlay }

    -- data:extend{ pipe }

    local pipe_item = table.deepcopy(data.raw["item"]["pipe"])
    if not pipe_item then log("pipe item not found") return end
    local pipe_item_name = fluid_name .. "-pipe"
    local pipe_item_localised_name = { "", { "fluid-name." .. fluid_name }, " ", { "entity-name.pipe" } }
    pipe_item.name = pipe_item_name
    pipe_item.place_result = pipe_item_name
    pipe_item.localised_name = pipe_item_localised_name
    local item_icon_base = {
        icon = pipe_item.icon,
        icon_size = pipe_item.icon_size,
        icon_mipmaps = pipe_item.icon_mipmaps
    }
    local item_icon_overlay = table.deepcopy(item_icon_base)
    item_icon_overlay.tint = fluid_color
    item_icon_overlay.icon = "__color-coded-pipes__/graphics/overlay-pipe-icon/overlay-pipe-icon.png"
    pipe_item.icons = { item_icon_base, item_icon_overlay }
    -- pipe_item.order = pipe_item.order .. recipe_order[color]
    pipe_item.subgroup = "color-coded-pipe"
    data:extend{ pipe_item }

    local pipe_recipe = table.deepcopy(data.raw["recipe"]["pipe"])
    if not pipe_recipe then log("pipe recipe not found") return end
    local pipe_recipe_name = fluid_name .. "-pipe"
    local pipe_recipe_localised_name = { "", { "fluid-name." .. fluid_name }, " ", { "entity-name.pipe" } }
    pipe_recipe.name = pipe_recipe_name
    pipe_recipe.result = pipe_recipe.result and pipe_recipe_name or nil
    pipe_recipe.results = pipe_recipe.results and { { type = "item", name = pipe_recipe_name, amount = 1 } } or nil
    if pipe_recipe.normal then
        pipe_recipe.normal.result = pipe_recipe.normal.result and pipe_recipe_name or nil
        pipe_recipe.normal.results = pipe_recipe.normal.results and { { type = "item", name = pipe_recipe_name, amount = 1 } } or nil
    end
    if pipe_recipe.expensive then
        pipe_recipe.expensive.result = pipe_recipe.expensive.result and pipe_recipe_name or nil
        pipe_recipe.expensive.results = pipe_recipe.expensive.results and { { type = "item", name = pipe_recipe_name, amount = 1 } } or nil
    end
    pipe_recipe.localised_name = pipe_recipe_localised_name
    data:extend{ pipe_recipe }

    -- local pipe_to_ground = table.deepcopy(data.raw["pipe-to-ground"]["pipe-to-ground"])
    -- if not pipe_to_ground then log("pipe-to-ground entity not found") return end
    -- local pipe_to_ground_name = fluid_name .. "-pipe-to-ground"
    -- local pipe_to_ground_localised_name = { "", { "fluid-name." .. fluid_name }, " ", { "entity-name.pipe-to-ground" } }
    -- pipe_to_ground.name = pipe_to_ground_name
    -- pipe_to_ground.minable.result = pipe_to_ground_name
    -- for _, filename in pairs(pipe_to_ground_filenames) do
    --     local property_name = replace_dash_with_underscore(filename)
    --     local original_layer = table.deepcopy(pipe_to_ground.pictures[property_name]) ---@type data.Sprite

    --     local layers = {
    --         [2] = {
    --             filename = "__color-coded-pipes__/graphics/overlay-pipe-to-ground-" .. filename .. "/overlay-hr-pipe-to-ground-" .. filename .. "@0.5x.png",
    --             hr_version = {
    --                 filename = "__color-coded-pipes__/graphics/overlay-pipe-to-ground-" .. filename .. "/overlay-hr-pipe-to-ground-" .. filename .. ".png",
    --                 tint = fluid_color,
    --                 size = original_layer.hr_version.size,
    --                 shift = original_layer.hr_version.shift,
    --                 scale = original_layer.hr_version.scale,
    --                 x = original_layer.hr_version.x,
    --                 y = original_layer.hr_version.y,
    --                 position = original_layer.hr_version.position,
    --                 width = original_layer.hr_version.width,
    --                 height = original_layer.hr_version.height,
    --                 blend_mode = "normal",
    --                 -- draw_as_glow = true,
    --             },
    --             tint = fluid_color,
    --             size = original_layer.size,
    --             shift = original_layer.shift,
    --             scale = original_layer.scale,
    --             x = original_layer.x,
    --             y = original_layer.y,
    --             position = original_layer.position,
    --             width = original_layer.width,
    --             height = original_layer.height,
    --             blend_mode = "normal",
    --             -- draw_as_glow = true,
    --         },
    --         [1] = {
    --             filename = original_layer.filename,
    --             hr_version = {
    --                 filename = original_layer.hr_version.filename,
    --                 tint = original_layer.hr_version.tint,
    --                 size = original_layer.hr_version.size,
    --                 shift = original_layer.hr_version.shift,
    --                 scale = original_layer.hr_version.scale,
    --                 x = original_layer.hr_version.x,
    --                 y = original_layer.hr_version.y,
    --                 position = original_layer.hr_version.position,
    --                 width = original_layer.hr_version.width,
    --                 height = original_layer.hr_version.height,
    --             },
    --             tint = original_layer.tint,
    --             size = original_layer.size,
    --             shift = original_layer.shift,
    --             scale = original_layer.scale,
    --             x = original_layer.x,
    --             y = original_layer.y,
    --             position = original_layer.position,
    --             width = original_layer.width,
    --             height = original_layer.height,
    --         }
    --     }
    --     pipe_to_ground.pictures[property_name] = nil
    --     pipe_to_ground.pictures[property_name] = { layers }
    -- end
    -- pipe_to_ground.localised_name = pipe_to_ground_localised_name
    -- -- pipe_to_ground.corpse = name .. "-pipe-to-ground-remnants"
    -- local icon_base = {
    --     icon = pipe_to_ground.icon,
    --     icon_size = pipe_to_ground.icon_size,
    --     icon_mipmaps = pipe_to_ground.icon_mipmaps
    -- }
    -- local icon_overlay = table.deepcopy(icon_base)
    -- icon_overlay.tint = fluid_color
    -- icon_overlay.icon = "__color-coded-pipes__/graphics/overlay-pipe-to-ground-icon/overlay-pipe-to-ground-icon.png"
    -- pipe_to_ground.icons = { icon_base, icon_overlay }
    -- data:extend{ pipe_to_ground }

    -- local pipe_to_ground_item = table.deepcopy(data.raw["item"]["pipe-to-ground"])
    -- if not pipe_to_ground_item then log("pipe-to-ground item not found") return end
    -- local pipe_to_ground_item_name = fluid_name .. "-pipe-to-ground"
    -- local pipe_to_ground_item_localised_name = { "", { "fluid-name." .. fluid_name }, " ", { "entity-name.pipe-to-ground" } }
    -- pipe_to_ground_item.name = pipe_to_ground_item_name
    -- pipe_to_ground_item.place_result = pipe_to_ground_item_name
    -- pipe_to_ground_item.localised_name = pipe_to_ground_item_localised_name
    -- local item_icon_base = {
    --     icon = pipe_to_ground_item.icon,
    --     icon_size = pipe_to_ground_item.icon_size,
    --     icon_mipmaps = pipe_to_ground_item.icon_mipmaps
    -- }
    -- local item_icon_overlay = table.deepcopy(item_icon_base)
    -- item_icon_overlay.tint = fluid_color
    -- item_icon_overlay.icon = "__color-coded-pipes__/graphics/overlay-pipe-to-ground-icon/overlay-pipe-to-ground-icon.png"
    -- pipe_to_ground_item.icons = { item_icon_base, item_icon_overlay }
    -- -- pipe_to_ground_item.order = pipe_to_ground_item.order .. recipe_order[color]
    -- pipe_to_ground_item.subgroup = "color-coded-pipe-to-ground"
    -- data:extend{ pipe_to_ground_item }

    -- local pipe_to_ground_recipe = table.deepcopy(data.raw["recipe"]["pipe-to-ground"])
    -- if not pipe_to_ground_recipe then log("pipe-to-ground recipe not found") return end
    -- local pipe_to_ground_recipe_name = fluid_name .. "-pipe-to-ground"
    -- local pipe_to_ground_recipe_localised_name = { "", { "fluid-name." .. fluid_name }, " ", { "entity-name.pipe-to-ground" } }
    -- pipe_to_ground_recipe.name = pipe_to_ground_recipe_name
    -- pipe_to_ground_recipe.result = pipe_to_ground_recipe.result and pipe_to_ground_recipe_name or nil
    -- pipe_to_ground_recipe.results = pipe_to_ground_recipe.results and { { type = "item", name = pipe_to_ground_recipe_name, amount = 1 } } or nil
    -- if pipe_to_ground_recipe.normal then
    --     pipe_to_ground_recipe.normal.result = pipe_to_ground_recipe.normal.result and pipe_to_ground_recipe_name or nil
    --     pipe_to_ground_recipe.normal.results = pipe_to_ground_recipe.normal.results and { { type = "item", name = pipe_to_ground_recipe_name, amount = 1 } } or nil
    -- end
    -- if pipe_to_ground_recipe.expensive then
    --     pipe_to_ground_recipe.expensive.result = pipe_to_ground_recipe.expensive.result and pipe_to_ground_recipe_name or nil
    --     pipe_to_ground_recipe.expensive.results = pipe_to_ground_recipe.expensive.results and { { type = "item", name = pipe_to_ground_recipe_name, amount = 1 } } or nil
    -- end
    -- pipe_to_ground_recipe.localised_name = pipe_to_ground_recipe_localised_name
    -- data:extend{ pipe_to_ground_recipe }

    -- local storage_tank = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
    -- if not storage_tank then log("storage-tank entity not found") return end
    -- local storage_tank_name = fluid_name .. "-storage-tank"
    -- local storage_tank_localised_name = { "", { "fluid-name." .. fluid_name }, " ", { "entity-name.storage-tank" } }
    -- storage_tank.name = storage_tank_name
    -- storage_tank.minable.result = storage_tank_name
    -- storage_tank.pictures.picture.sheets[1].filename = "__color-coded-pipes__/graphics/overlay-storage-tank/overlay-storage-tank.png"
    -- storage_tank.pictures.picture.sheets[1].hr_version.filename = "__color-coded-pipes__/graphics/overlay-storage-tank/overlay-hr-storage-tank.png"
    -- storage_tank.localised_name = storage_tank_localised_name
    -- -- storage_tank.corpse = name .. "-storage-tank-remnants"
    -- local icon_base = {
    --     icon = storage_tank.icon,
    --     icon_size = storage_tank.icon_size,
    --     icon_mipmaps = storage_tank.icon_mipmaps
    -- }
    -- local icon_overlay = table.deepcopy(icon_base)
    -- icon_overlay.tint = fluid_color
    -- icon_overlay.icon = "__color-coded-pipes__/graphics/overlay-storage-tank-icon/overlay-storage-tank-icon.png"
    -- storage_tank.icons = { icon_base, icon_overlay }
    -- data:extend{ storage_tank }

    -- local storage_tank_item = table.deepcopy(data.raw["item"]["storage-tank"])
    -- if not storage_tank_item then log("storage-tank item not found") return end
    -- local storage_tank_item_name = fluid_name .. "-storage-tank"
    -- local storage_tank_item_localised_name = { "", { "fluid-name." .. fluid_name }, " ", { "entity-name.storage-tank" } }
    -- storage_tank_item.name = storage_tank_item_name
    -- storage_tank_item.place_result = storage_tank_item_name
    -- storage_tank_item.localised_name = storage_tank_item_localised_name
    -- local item_icon_base = {
    --     icon = storage_tank_item.icon,
    --     icon_size = storage_tank_item.icon_size,
    --     icon_mipmaps = storage_tank_item.icon_mipmaps
    -- }   
    -- local item_icon_overlay = table.deepcopy(item_icon_base)
    -- item_icon_overlay.tint = fluid_color
    -- item_icon_overlay.icon = "__color-coded-pipes__/graphics/overlay-storage-tank-icon/overlay-storage-tank-icon.png"
    -- storage_tank_item.icons = { item_icon_base, item_icon_overlay }
    -- -- storage_tank_item.order = storage_tank_item.order .. recipe_order[color]
    -- storage_tank_item.subgroup = "color-coded-storage-tank"
    -- data:extend{ storage_tank_item }

    -- local storage_tank_recipe = table.deepcopy(data.raw["recipe"]["storage-tank"])
    -- if not storage_tank_recipe then log("storage-tank recipe not found") return end
    -- local storage_tank_recipe_name = fluid_name .. "-storage-tank"
    -- local storage_tank_recipe_localised_name = { "", { "fluid-name." .. fluid_name }, " ", { "entity-name.storage-tank" } }
    -- storage_tank_recipe.name = storage_tank_recipe_name
    -- storage_tank_recipe.result = storage_tank_recipe.result and storage_tank_recipe_name or nil
    -- storage_tank_recipe.results = storage_tank_recipe.results and { { type = "item", name = storage_tank_recipe_name, amount = 1 } } or nil

    -- if storage_tank_recipe.normal then
    --     storage_tank_recipe.normal.result = storage_tank_recipe.normal.result and storage_tank_recipe_name or nil
    --     storage_tank_recipe.normal.results = storage_tank_recipe.normal.results and { { type = "item", name = storage_tank_recipe_name, amount = 1 } } or nil
    -- end
    -- if storage_tank_recipe.expensive then
    --     storage_tank_recipe.expensive.result = storage_tank_recipe.expensive.result and storage_tank_recipe_name or nil
    --     storage_tank_recipe.expensive.results = storage_tank_recipe.expensive.results and { { type = "item", name = storage_tank_recipe_name, amount = 1 } } or nil
    -- end
    -- storage_tank_recipe.localised_name = storage_tank_recipe_localised_name
    -- data:extend{ storage_tank_recipe }

    ::next_fluid::

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
