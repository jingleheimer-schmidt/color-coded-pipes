
data:extend{
    {
        type = "string-setting",
        name = "color-coded-pipes-color-mode",
        setting_type = "startup",
        default_value = "colorized",
        allowed_values = { "weathered", "colorized" },
        hidden = true,
    },
    {
        type = "bool-setting",
        name = "color-coded-main-menu-simulations",
        setting_type = "startup",
        default_value = true,
    }
}

local a = 0.6
local rgb_colors = {
    red =    { r = 0.9, g = 0.2, b = 0.2, a = a },
    orange = { r = 0.9, g = 0.5, b = 0.2, a = a },
    yellow = { r = 0.9, g = 0.9, b = 0.2, a = a },
    green =  { r = 0.2, g = 0.9, b = 0.2, a = a },
    blue =   { r = 0.2, g = 0.2, b = 0.9, a = a },
    purple = { r = 0.5, g = 0.2, b = 0.9, a = a },
    pink =   { r = 0.9, g = 0.2, b = 0.9, a = a },
    black =  { r = 0.2, g = 0.2, b = 0.2, a = a },
    white =  { r = 0.9, g = 0.9, b = 0.9, a = a },
}

for _, color in pairs(rgb_colors) do
    color.r = color.r * 0.75
    color.g = color.g * 0.75
    color.b = color.b * 0.75
end

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

for name, color in pairs(rgb_colors) do
    local color_setting = {
        type = "color-setting",
        name = "color-coded-pipes-" .. name,
        setting_type = "startup",
        default_value = color,
        order = recipe_order[name],
    }
    data:extend{color_setting}
end
