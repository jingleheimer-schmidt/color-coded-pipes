
local function replace_dash_with_underscore(str)
    return string.gsub(str, "-", "_")
end

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

--- Returns the Color (RGBA) value for a given setting name
---@param setting string
---@return Color
local function get_color(setting)
    local value = settings.startup[setting].value --[[@as Color]]
    return value
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

-- Standard RGB to HSV conversion
---@param r number Red [0–1 or 0–255]
---@param g number Green [0–1 or 0–255]
---@param b number Blue [0–1 or 0–255]
---@return number h Hue in degrees [0–360)
---@return number s Saturation [0–1]
---@return number v Value [0–1]
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

--- Standard HSV to RGB conversion
--- @param h number Hue in degrees [0–360)
--- @param s number Saturation [0–1]
--- @param v number Value [0–1]
--- @return number r Red [0–1]
--- @return number g Green [0–1]
--- @return number b Blue [0–1]
local function hsv_to_rgb(h, s, v)
    h = ((h % 360) + 360) % 360
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c

    local r1, g1, b1
    if h < 60 then
        r1, g1, b1 = c, x, 0
    elseif h < 120 then
        r1, g1, b1 = x, c, 0
    elseif h < 180 then
        r1, g1, b1 = 0, c, x
    elseif h < 240 then
        r1, g1, b1 = 0, x, c
    elseif h < 300 then
        r1, g1, b1 = x, 0, c
    else
        r1, g1, b1 = c, 0, x
    end

    return r1 + m, g1 + m, b1 + m
end

-- Cache for pre-calculated HSV values of named colors.
local hsv_rgb_colors = {}
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

-- gets the name of the closest matching rainbow color for a given Color
---@param color Color
---@return string
local function get_closest_named_color(color)
    local cR = color.r or color[1] or 0
    local cG = color.g or color[2] or 0
    local cB = color.b or color[3] or 0
    local cA = color.a or color[4] or 1
    local cH, cS, cV = rgb_to_hsv(cR, cG, cB)
    local MATCH_S, MATCH_V = 0.90, 0.80
    local W_H, W_S, W_V, W_A = 3.0, 0.5, 0.3, 0.0
    local GRAY_S_THRESH, GRAY_V_SPLIT = 0.18, 0.50

    if cS < GRAY_S_THRESH then
        local name = (cV >= GRAY_V_SPLIT) and "white" or "black"
        return name, 0
    end

    local closest_name = "black"
    local min_d2 = math.huge

    for name, ref in pairs(rgb_colors) do
        if not hsv_rgb_colors[name] then
            local rR = ref.r or ref[1] or 0
            local rG = ref.g or ref[2] or 0
            local rB = ref.b or ref[3] or 0
            local h, s, v = rgb_to_hsv(rR, rG, rB)
            if name ~= "white" and name ~= "black" then
                s = MATCH_S
                v = MATCH_V
            end
            hsv_rgb_colors[name] = { h = h, s = s, v = v, a = ref.a or ref[4] or 1 }
        end

        local r = hsv_rgb_colors[name]
        local dH = math.min(math.abs(r.h - cH), 360 - math.abs(r.h - cH)) / 360
        local dS = r.s - cS
        local dV = r.v - cV
        local dA = r.a - cA
        local d2 = W_V * (dV * dV) + W_S * (dS * dS) + W_H * (dH * dH) + W_A * (dA * dA)

        if d2 < min_d2 then
            min_d2 = d2
            closest_name = name
        end
    end

    return closest_name
end

-- Color to use for visualization. This color should be vibrant and easily distinguished.
-- If not specified, this will be auto-generated from base_color by converting to HSV, decreasing saturation by 10% and setting value to 80%.
---@param fluid data.FluidPrototype
---@return Color
local function get_fluid_visualization_color(fluid)
    local base_color = fluid.base_color
    local r, g, b = base_color.r or base_color[1], base_color.g or base_color[2], base_color.b or base_color[3]
    local h, s, v = rgb_to_hsv(r, g, b)
    s = s * 0.9
    v = 0.8
    r, g, b = hsv_to_rgb(h, s, v)
    return { r = r, g = g, b = b, a = 1 }
end

return {
    replace_dash_with_underscore = replace_dash_with_underscore,
    append = append,
    get_color = get_color,
    get_closest_named_color = get_closest_named_color,
    mix_color = mix_color,
    get_fluid_visualisation_color = get_fluid_visualization_color,
    rgb_to_hsv = rgb_to_hsv,
    hsv_to_rgb = hsv_to_rgb,
}
