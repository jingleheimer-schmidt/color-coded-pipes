
---@type data.ModBoolSettingPrototype
local menu_simulations = {
    type = "bool-setting",
    name = "color-coded-main-menu-simulations",
    setting_type = "startup",
    default_value = true,
    hidden = true,
    order = "0",
}
---@type data.ModBoolSettingPrototype
local rainbow_recipes = {
    type = "bool-setting",
    name = "color-coded-pipes-show-rainbow-recipes",
    setting_type = "startup",
    default_value = true,
    hidden = false,
    order = "10",
}
---@type data.ModBoolSettingPrototype
local fluid_recipes = {
    type = "bool-setting",
    name = "color-coded-pipes-show-fluid-recipes",
    setting_type = "startup",
    default_value = false,
    hidden = false,
    order = "20",
}
---@type data.ModBoolSettingPrototype
local pride_recipes = {
    type = "bool-setting",
    name = "color-coded-pipes-show-pride-recipes",
    setting_type = "startup",
    default_value = false,
    hidden = false,
    order = "22",
}
---@type data.ModBoolSettingPrototype
local regroup_recipes = {
    type = "bool-setting",
    name = "color-coded-pipes-regroup-recipes",
    setting_type = "startup",
    default_value = false,
    hidden = false,
    order = "25",
}
---@type data.ModStringSettingPrototype
local recipe_ingredients = {
    type = "string-setting",
    name = "color-coded-pipes-recipe-ingredients",
    setting_type = "startup",
    default_value = "base-ingredients",
    allowed_values = { "base-ingredients", "base-item" },
    hidden = false,
    order = "30",
}

data:extend { menu_simulations, rainbow_recipes, pride_recipes, fluid_recipes, regroup_recipes, recipe_ingredients }

local a = 0.6
local rgb_colors = {
    red = { r = 0.9, g = 0.2, b = 0.2, a = a },
    orange = { r = 0.9, g = 0.5, b = 0.2, a = a },
    yellow = { r = 0.9, g = 0.9, b = 0.2, a = a },
    green = { r = 0.2, g = 0.8, b = 0.2, a = a },
    blue = { r = 0.1, g = 0.3, b = 0.7, a = a },
    purple = { r = 0.6, g = 0.2, b = 0.9, a = a },
    pink = { r = 0.8, g = 0.2, b = 0.6, a = a },
    black = { r = 0.2, g = 0.2, b = 0.2, a = a },
    white = { r = 0.9, g = 0.9, b = 0.9, a = a },
}

local order = {
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

for name, color in pairs(rgb_colors) do
    ---@type data.ModColorSettingPrototype
    local color_setting = {
        type = "color-setting",
        name = "color-coded-pipes-" .. name,
        setting_type = "startup",
        default_value = color,
        order = order[name],
        hidden = true,
    }
    data:extend { color_setting }
end
