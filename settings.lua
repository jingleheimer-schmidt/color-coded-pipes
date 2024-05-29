
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

local rgb_colors = {
    red = { r = 0.5, g = 0, b = 0 },
    orange = { r = 0.5, g = 0.25, b = 0 },
    yellow = { r = 0.5, g = 0.5, b = 0 },
    green = { r = 0, g = 0.5, b = 0 },
    blue = { r = 0, g = 0, b = 0.5 },
    purple = { r = 0.25, g = 0, b = 0.5 },
    pink = { r = 0.5, g = 0, b = 0.5 },
    white = { r = 0.5, g = 0.5, b = 0.5 },
    black = { r = 0, g = 0, b = 0 },
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
