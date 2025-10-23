
local util = require("util")
local functions = require("__color-coded-pipes__.scripts.functions")
local append = functions.append
local get_color = functions.get_color

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

-- Helper function to convert an RGB color to HSV
---@param r number
---@param g number
---@param b number
---@return number h 0-360
---@return number s 0-1
---@return number v 0-1
local function rgb_to_hsv(r, g, b)
    if (r > 1) or (g > 1) or (b > 1) then
        r = r / 255
        g = g / 255
        b = b / 255
    end
    local min = math.min(r, g, b)
    local max = math.max(r, g, b)
    local delta = max - min
    local h, s, v = 0, 0, max

    if max ~= 0 then
        s = delta / max
    end

    if delta ~= 0 then
        if r == max then
            h = (g - b) / delta
        elseif g == max then
            h = 2 + (b - r) / delta
        else
            h = 4 + (r - g) / delta
        end
        h = h * 60
        if h < 0 then
            h = h + 360
        end
    end

    return h, s, v
end

-- Cache for pre-calculated HSV values of named colors.
local hsv_rgb_colors = {}

-- gets the name of the closest matching rainbow color for a given Color
---@param color Color
---@return string
local function get_closest_named_color(color)
    local cR = color.r or color[1] or 0
    local cG = color.g or color[2] or 0
    local cB = color.b or color[3] or 0
    local cA = color.a or color[4] or 1

    -- Convert the input color to HSV
    local cH, cS, cV = rgb_to_hsv(cR, cG, cB)

    local closest_name = "black"
    local min_distance_sq = math.huge

    for name, ref in pairs(rgb_colors) do
        local rH, rS, rV, rA

        -- Only calculate and store HSV once per named color
        if not hsv_rgb_colors[name] then
            -- Convert RGB reference to HSV (0-1 range)
            local rR = ref.r or ref[1] or 0
            local rG = ref.g or ref[2] or 0
            local rB = ref.b or ref[3] or 0

            rH, rS, rV = rgb_to_hsv(rR, rG, rB)
            rA = ref.a or ref[4] or 1

            -- Store the calculated values in the cache
            hsv_rgb_colors[name] = { h = rH, s = rS, v = rV, a = rA }
        end

        rH = hsv_rgb_colors[name].h
        rS = hsv_rgb_colors[name].s
        rV = hsv_rgb_colors[name].v
        rA = hsv_rgb_colors[name].a

        -- Hue difference (must be cyclical: distance between 10 and 350 is 20, not 340)
        local hDiff = math.abs(rH - cH)
        local dH = math.min(hDiff, 360 - hDiff)

        local dS = rS - cS
        local dV = rV - cV
        local dA = rA - cA

        -- 3. Calculate Weighted HSV Distance
        -- Weights tuned to match ... arbitrary magic! jk i just kept adjusting until it looked good
        local h_weight = 9 -- Highest importance; gets the color family (red, blue, etc.).
        local s_weight = 5  -- Medium importance; considers saturation/dullness.
        local v_weight = 2  -- Lowest importance; brightness differences.
        local a_weight = 1  -- Transparency difference.

        -- H is normalized to 0-1 range before squaring to match S and V magnitude.
        local h_normalized = dH / 360

        local distance_sq = (v_weight * dV * dV) + (h_weight * h_normalized * h_normalized) + (s_weight * dS * dS) + (a_weight * dA * dA)

        if distance_sq < min_distance_sq then
            min_distance_sq = distance_sq
            closest_name = name
        end
    end

    return closest_name
end

-- Mixes two colors by a given percentage (0 - 1)
---@param c1 Color
---@param c2 Color
---@param percent number
---@return Color
local function mix_color(c1, c2, percent)
    percent = percent or 0.5
    local r1 = c1.r or c1[1] or 0
    local g1 = c1.g or c1[2] or 0
    local b1 = c1.b or c1[3] or 0
    local a1 = c1.a or c1[4] or 1
    local r2 = c2.r or c2[1] or 0
    local g2 = c2.g or c2[2] or 0
    local b2 = c2.b or c2[3] or 0
    local a2 = c2.a or c2[4] or 1
    return {
        r = (r1 * (1 - percent) + r2 * percent),
        g = (g1 * (1 - percent) + g2 * percent),
        b = (b1 * (1 - percent) + b2 * percent),
        a = (a1 * (1 - percent) + a2 * percent),
    }
end

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
            local base_color = util.get_color_with_alpha(fluid.base_color, 0.6, true)
            pipe_colors[fluid.name] = table.deepcopy(base_color)
            local mixed_base_flow_color = mix_color(base_color, fluid.flow_color, 1 / 8)
            local closest_color_name = get_closest_named_color(mixed_base_flow_color)
            fluid_to_color_map[fluid.name] = closest_color_name
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
