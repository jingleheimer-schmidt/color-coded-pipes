
data:extend{
    {
        type = "string-setting",
        name = "color-coded-pipes-color-mode",
        setting_type = "startup",
        default_value = "colorized",
        allowed_values = { "weathered", "colorized" },
        hidden = true,
        order = "a",
    },
    {
        type = "bool-setting",
        name = "color-coded-main-menu-simulations",
        setting_type = "startup",
        default_value = true,
        order = "a",
    }
}

local a = 0.45
local rgb_colors = {
    red =    { r = 0.9, g = 0.2, b = 0.2, a = a },
    orange = { r = 0.9, g = 0.5, b = 0.2, a = a },
    yellow = { r = 0.9, g = 0.9, b = 0.2, a = a },
    green =  { r = 0.2, g = 0.8, b = 0.2, a = a },
    blue =   { r = 0.1, g = 0.3, b = 0.7, a = a },
    purple = { r = 0.6, g = 0.2, b = 0.9, a = a },
    pink =   { r = 0.8, g = 0.2, b = 0.6, a = a },
    black =  { r = 0.2, g = 0.2, b = 0.2, a = a },
    white =  { r = 0.9, g = 0.9, b = 0.9, a = a },
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
        hidden = true,
    }
    data:extend{color_setting}
end

-- data:extend{
--     {
--         type = "bool-setting",
--         name = "color-coded-pipes-planner-tooltip",
--         setting_type = "runtime-per-user",
--         default_value = false,
--         order = "a",
--         hidden = true,
--     }
-- }

data:extend{
    {
        type = "bool-setting",
        name = "color-coded-pipes-bots-required",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "a",
    }
}

data:extend{
    {
        type = "bool-setting",
        name = "color-coded-pipes-show-rainbow-recipes",
        setting_type = "startup",
        default_value = true,
        order = "10",
    }
}

data:extend{
    {
        type = "bool-setting",
        name = "color-coded-pipes-show-fluid-recipes",
        setting_type = "startup",
        default_value = false,
        order = "20",
    }
}
