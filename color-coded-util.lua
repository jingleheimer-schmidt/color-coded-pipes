
local util = require("util")

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
    "north",
    "east",
    "south",
    "west",
}

local recipe_order = {
    ["red"] = "a[red]",
    ["orange"] = "b[orange]",
    ["yellow"] = "c[yellow]",
    ["green"] = "d[green]",
    ["blue"] = "e[blue]",
    ["purple"] = "f[purple]",
    ["pink"] = "g[pink]",
    ["black"] = "h[black]",
    ["white"] = "i[white]",
}

---@param setting string
---@return Color
local function get_color(setting)
    local value = settings.startup[setting].value --[[@as Color]]
    return value
end

---@type table<string, Color>
local rgb_colors = {
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
    if fluid.base_color and not fluid.hidden and not fluid.parameter then
        local base_color = util.get_color_with_alpha(fluid.base_color, 0.6, true)
        rgb_colors[fluid.name] = table.deepcopy(base_color)
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


--- Appends the contents of table_2 to table_1.
--- @generic T
--- @param table_1 T[] The first table to append to.
--- @param table_2 T[] The second table whose elements will be appended.
--- @return T[] - The combined table with elements from both input tables.
local function append(table_1, table_2)
    for _, value in pairs(table_2) do
        table.insert(table_1, value)
    end
    return table_1
end


------------------------------------------------------------
--- list of base pipes to create color-coded variants of ---
------------------------------------------------------------

local base_entities = {
    { type = "storage-tank",   name = "storage-tank",   order = "-a[1]" },
    { type = "pipe",           name = "pipe",           order = "-b[1]" },
    { type = "pipe-to-ground", name = "pipe-to-ground", order = "-c[1]" },
    { type = "pump",           name = "pump",           order = "-d[1]" },
}
local pipe_plus_entities = {
    { type = "pipe-to-ground", name = "pipe-to-ground-2", order = "-c[2]" },
    { type = "pipe-to-ground", name = "pipe-to-ground-3", order = "-c[3]" },
}
local flow_control_entities = {
    { type = "storage-tank", name = "pipe-elbow",    order = "-c[5]" },
    { type = "storage-tank", name = "pipe-junction", order = "-c[4]" },
    { type = "storage-tank", name = "pipe-straight", order = "-c[6]" },
}
local storage_tank_2_2_0_entities = {
    { type = "storage-tank", name = "storage-tank2", order = "-a[2]" },
}
local zithorian_extra_storage_tanks_entities = {
    { type = "storage-tank", name = "fluid-tank-1x1", order = "-a[3]" },
    { type = "storage-tank", name = "fluid-tank-2x2", order = "-a[4]" },
    { type = "storage-tank", name = "fluid-tank-3x4", order = "-a[5]" },
    { type = "storage-tank", name = "fluid-tank-5x5", order = "-a[6]" },
}

if mods["pipe_plus"] then append(base_entities, pipe_plus_entities) end
if mods["Flow Control"] then append(base_entities, flow_control_entities) end
if mods["StorageTank2_2_0"] then append(base_entities, storage_tank_2_2_0_entities) end
if mods["zithorian-extra-storage-tanks-port"] then append(base_entities, zithorian_extra_storage_tanks_entities) end

return {
    pipe_filenames = pipe_filenames,
    pipe_to_ground_filenames = pipe_to_ground_filenames,
    recipe_order = recipe_order,
    rgb_colors = rgb_colors,
    replace_dash_with_underscore = replace_dash_with_underscore,
    pipe_patch_filenames = pipe_patch_filenames,
    pipe_to_ground_patch_filenames = pipe_to_ground_patch_filenames,
    append = append,
    base_entities = base_entities,
}
