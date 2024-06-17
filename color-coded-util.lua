
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

local rgb_colors = { ---@type table<string, Color>
    -- red = { r = 0.5, g = 0, b = 0 },
    -- orange = { r = 0.5, g = 0.25, b = 0 },
    -- yellow = { r = 0.5, g = 0.5, b = 0 },
    -- green = { r = 0, g = 0.5, b = 0 },
    -- blue = { r = 0, g = 0, b = 0.5 },
    -- purple = { r = 0.25, g = 0, b = 0.5 },
    -- pink = { r = 0.5, g = 0, b = 0.5 },
    -- white = { r = 0.5, g = 0.5, b = 0.5 },
    -- black = { r = 0, g = 0, b = 0 },
    red = settings.startup["color-coded-pipes-red"].value, ---@type Color
    orange = settings.startup["color-coded-pipes-orange"].value, ---@type Color
    yellow = settings.startup["color-coded-pipes-yellow"].value, ---@type Color
    green = settings.startup["color-coded-pipes-green"].value, ---@type Color
    blue = settings.startup["color-coded-pipes-blue"].value, ---@type Color
    purple = settings.startup["color-coded-pipes-purple"].value, ---@type Color
    pink = settings.startup["color-coded-pipes-pink"].value, ---@type Color
    white = settings.startup["color-coded-pipes-white"].value, ---@type Color
    black = settings.startup["color-coded-pipes-black"].value, ---@type Color
}

for _, fluid in pairs(data.raw["fluid"]) do
    local has_base_color = fluid.base_color and fluid.base_color.r and fluid.base_color.g and fluid.base_color.b
    local is_hidden = fluid.hidden
    if has_base_color and not is_hidden then
        rgb_colors[fluid.name] = fluid.base_color
        rgb_colors[fluid.name].a = 0.6
    end
end

local function replace_dash_with_underscore(str)
    return string.gsub(str, "-", "_")
end

return {
    pipe_filenames = pipe_filenames,
    pipe_to_ground_filenames = pipe_to_ground_filenames,
    recipe_order = recipe_order,
    rgb_colors = rgb_colors,
    replace_dash_with_underscore = replace_dash_with_underscore,
}