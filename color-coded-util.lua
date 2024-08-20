
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

---@param setting string
---@return Color
local function get_color(setting)
    local value = settings.startup[setting].value ---@as Color
    return value
end

local rgb_colors = { ---@type table<string, Color>
    red = get_color("color-coded-pipes-red"),
    orange = get_color("color-coded-pipes-orange"),
    yellow = get_color("color-coded-pipes-yellow"),
    green = get_color("color-coded-pipes-green"),
    blue = get_color("color-coded-pipes-blue"),
    purple = get_color("color-coded-pipes-purple"),
    pink = get_color("color-coded-pipes-pink"),
    black = get_color("color-coded-pipes-black"),
    white = get_color("color-coded-pipes-white"),
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

local pipe_patch_filenames = {
    ["corner-up-left"] = "corner-up-left",
    ["corner-up-right"] = "corner-up-right",
    ["cross"] = "cross",
    ["ending-up"] = "ending-up",
    ["straight-vertical"] = "straight-vertical",
    ["straight-vertical-window"] = "straight-vertical-window",
    ["t-left"] = "t-left",
    ["t-right"] = "t-right",
    ["t-up"] = "t-up",
}

local pipe_to_ground_patch_filenames = {
    ["down"] = "down",
    ["up"] = "up",
}

return {
    pipe_filenames = pipe_filenames,
    pipe_to_ground_filenames = pipe_to_ground_filenames,
    recipe_order = recipe_order,
    rgb_colors = rgb_colors,
    replace_dash_with_underscore = replace_dash_with_underscore,
    pipe_patch_filenames = pipe_patch_filenames,
    pipe_to_ground_patch_filenames = pipe_to_ground_patch_filenames,
}
