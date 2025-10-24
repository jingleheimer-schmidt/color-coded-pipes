
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

        -- Calculate Weighted HSV Distance
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

return {
    replace_dash_with_underscore = replace_dash_with_underscore,
    append = append,
    get_color = get_color,
    get_closest_named_color = get_closest_named_color,
    mix_color = mix_color,
}
