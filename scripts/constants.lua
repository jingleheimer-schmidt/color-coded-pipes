
local util = require("util")
local functions = require("__color-coded-pipes__.scripts.functions")
local append = functions.append
local get_color = functions.get_color
local mix_color = functions.mix_color
local get_closest_named_color = functions.get_closest_named_color
local get_fluid_visualisation_color = functions.get_fluid_visualisation_color

-------------------------------------
--- list of pipe sprite filenames ---
-------------------------------------

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

local color_order = {
    ["red"] = "a[red]",
    ["orange"] = "b[orange]",
    ["yellow"] = "c[yellow]",
    ["green"] = "d[green]",
    ["blue"] = "e[blue]",
    ["purple"] = "f[purple]",
    ["pink"] = "g[pink]",
    ["black"] = "h[black]",
    ["white"] = "i[white]",
    ["pride_lesbian_dark_orange"] = "a[pride_lesbian_dark_orange]",
    ["pride_lesbian_orange"] = "b[pride_lesbian_orange]",
    ["pride_lesbian_light_orange"] = "c[pride_lesbian_light_orange]",
    ["pride_lesbian_white"] = "d[pride_lesbian_white]",
    ["pride_lesbian_pink"] = "e[pride_lesbian_pink]",
    ["pride_lesbian_dusty_pink"] = "f[pride_lesbian_dusty_pink]",
    ["pride_lesbian_dark_rose"] = "g[pride_lesbian_dark_rose]",
    ["pride_gay_dark_green"] = "h[pride_gay_dark_green]",
    ["pride_gay_green"] = "i[pride_gay_green]",
    ["pride_gay_light_green"] = "j[pride_gay_light_green]",
    ["pride_gay_white"] = "k[pride_gay_white]",
    ["pride_gay_light_blue"] = "l[pride_gay_light_blue]",
    ["pride_gay_indigo"] = "m[pride_gay_indigo]",
    ["pride_gay_blue"] = "n[pride_gay_blue]",
    ["pride_bi_pink"] = "o[pride_bi_pink]",
    ["pride_bi_purple"] = "p[pride_bi_purple]",
    ["pride_bi_blue"] = "q[pride_bi_blue]",
    ["pride_trans_blue"] = "r[pride_trans_blue]",
    ["pride_trans_pink"] = "s[pride_trans_pink]",
    ["pride_trans_white"] = "t[pride_trans_white]",
    ["pride_ace_black"] = "a[pride_ace_black]",
    ["pride_ace_gray"] = "b[pride_ace_gray]",
    ["pride_ace_white"] = "c[pride_ace_white]",
    ["pride_ace_purple"] = "d[pride_ace_purple]",
    ["pride_pan_magenta"] = "e[pride_pan_magenta]",
    ["pride_pan_yellow"] = "f[pride_pan_yellow]",
    ["pride_pan_cyan"] = "g[pride_pan_cyan]",
    ["pride_nonbinary_yellow"] = "h[pride_nonbinary_yellow]",
    ["pride_nonbinary_white"] = "i[pride_nonbinary_white]",
    ["pride_nonbinary_purple"] = "j[pride_nonbinary_purple]",
    ["pride_nonbinary_black"] = "k[pride_nonbinary_black]",
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

-------------------------
--- color definitions ---
-------------------------

local alpha = 255 * 0.8

---@type table<string, Color>
local pipe_colors = {
    red = get_color("color-coded-pipes-red"),
    orange = get_color("color-coded-pipes-orange"),
    yellow = get_color("color-coded-pipes-yellow"),
    green = get_color("color-coded-pipes-green"),
    blue = get_color("color-coded-pipes-blue"),
    purple = get_color("color-coded-pipes-purple"),
    pink = get_color("color-coded-pipes-pink"),
    black = get_color("color-coded-pipes-black"),
    white = get_color("color-coded-pipes-white"),
    pride_lesbian_dark_orange = { r = 213, g = 045, b = 000, a = alpha },
    pride_lesbian_orange = { r = 239, g = 118, b = 039, a = alpha },
    pride_lesbian_light_orange = { r = 255, g = 154, b = 086, a = alpha },
    pride_lesbian_white = { r = 255, g = 255, b = 255, a = alpha },
    pride_lesbian_pink = { r = 209, g = 098, b = 164, a = alpha },
    pride_lesbian_dusty_pink = { r = 181, g = 086, b = 144, a = alpha },
    pride_lesbian_dark_rose = { r = 163, g = 002, b = 098, a = alpha },
    pride_gay_dark_green = { r = 007, g = 141, b = 112, a = alpha },
    pride_gay_green = { r = 038, g = 206, b = 170, a = alpha },
    pride_gay_light_green = { r = 152, g = 232, b = 193, a = alpha },
    pride_gay_white = { r = 255, g = 255, b = 255, a = alpha },
    pride_gay_light_blue = { r = 123, g = 173, b = 226, a = alpha },
    pride_gay_indigo = { r = 080, g = 073, b = 204, a = alpha },
    pride_gay_blue = { r = 061, g = 026, b = 120, a = alpha },
    pride_trans_blue = { r = 091, g = 206, b = 250, a = alpha },
    pride_trans_pink = { r = 245, g = 169, b = 184, a = alpha },
    pride_trans_white = { r = 255, g = 255, b = 255, a = alpha },
    pride_bi_pink = { r = 214, g = 002, b = 112, a = alpha },
    pride_bi_purple = { r = 155, g = 079, b = 150, a = alpha },
    pride_bi_blue = { r = 000, g = 056, b = 168, a = alpha },
    pride_ace_black = { r = 000, g = 000, b = 000, a = alpha },
    pride_ace_gray = { r = 163, g = 163, b = 163, a = alpha },
    pride_ace_white = { r = 255, g = 255, b = 255, a = alpha },
    pride_ace_purple = { r = 128, g = 000, b = 128, a = alpha },
    pride_pan_magenta = { r = 255, g = 033, b = 140, a = alpha },
    pride_pan_yellow = { r = 255, g = 216, b = 000, a = alpha },
    pride_pan_cyan = { r = 033, g = 177, b = 255, a = alpha },
    pride_nonbinary_yellow = { r = 252, g = 244, b = 052, a = alpha },
    pride_nonbinary_white = { r = 255, g = 255, b = 255, a = alpha },
    pride_nonbinary_purple = { r = 156, g = 089, b = 209, a = alpha },
    pride_nonbinary_black = { r = 044, g = 044, b = 044, a = alpha },
}

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

----------------------------------------------
--- Build the fluid to color mapping table ---
----------------------------------------------

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

local fluids = data and data.raw and data.raw["fluid"] or prototypes and prototypes.fluid
if fluids then
    for _, fluid in pairs(fluids) do
        if fluid.base_color and not fluid.hidden and not fluid.parameter then
            local visualisation_color = get_fluid_visualisation_color(fluid)
            fluid_to_color_map[fluid.name] = get_closest_named_color(visualisation_color)
            visualisation_color.a = 0.6
            pipe_colors[fluid.name] = visualisation_color
        end
    end
end

-- overrides for specific fluids that don't map well
fluid_to_color_map["petroleum-gas"] = "purple"
fluid_to_color_map["heavy-oil"] = "red"
fluid_to_color_map["holmium-solution"] = "pink"
fluid_to_color_map["molten-copper"] = "red"
fluid_to_color_map["thruster-fuel"] = "red"

return {
    rgb_colors = rgb_colors,
    pipe_filenames = pipe_filenames,
    pipe_to_ground_filenames = pipe_to_ground_filenames,
    color_order = color_order,
    pipe_patch_filenames = pipe_patch_filenames,
    pipe_to_ground_patch_filenames = pipe_to_ground_patch_filenames,
    base_entities = base_entities,
    pipe_colors = pipe_colors,
    fluid_to_color_map = fluid_to_color_map,
}
