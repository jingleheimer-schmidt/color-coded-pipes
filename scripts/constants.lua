
local util = require("util")
local functions = require("scripts.functions")
local append = functions.append
local get_color = functions.get_color

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

------------------------------------------------------------
--- list of base pipes to create color-coded variants of ---
------------------------------------------------------------

---@type { type: string, name: string, order: string }[]
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

local active_mods = mods or script and script.active_mods
if active_mods["pipe_plus"] then append(base_entities, pipe_plus_entities) end
if active_mods["Flow Control"] then append(base_entities, flow_control_entities) end
if active_mods["StorageTank2_2_0"] then append(base_entities, storage_tank_2_2_0_entities) end
if active_mods["zithorian-extra-storage-tanks-port"] then append(base_entities, zithorian_extra_storage_tanks_entities) end

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

local fluids = data and data.raw and data.raw["fluid"] or prototypes and prototypes.fluid
if fluids then
    for _, fluid in pairs(fluids) do
        if fluid.base_color and not fluid.hidden and not fluid.parameter then
            local base_color = util.get_color_with_alpha(fluid.base_color, 0.6, true)
            rgb_colors[fluid.name] = table.deepcopy(base_color)
        end
    end
end

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

return {
    pipe_filenames = pipe_filenames,
    pipe_to_ground_filenames = pipe_to_ground_filenames,
    recipe_order = recipe_order,
    pipe_patch_filenames = pipe_patch_filenames,
    pipe_to_ground_patch_filenames = pipe_to_ground_patch_filenames,
    base_entities = base_entities,
    rgb_colors = rgb_colors,
    fluid_to_color_map = fluid_to_color_map,
}
