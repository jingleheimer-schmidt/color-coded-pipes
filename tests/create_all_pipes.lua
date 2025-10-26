
local function get_color(setting)
    local value = settings.startup[setting].value --[[@as Color]]
    return value
end

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

local function get_base_fluid_visualization_color(fluid)
    if data and fluid.visualization_color then
        return fluid.visualization_color
    else
        local base_color = fluid.base_color
        local r, g, b = base_color.r or base_color[1], base_color.g or base_color[2], base_color.b or base_color[3]
        local h, s, v = rgb_to_hsv(r, g, b)
        s = s * 0.9
        v = 0.8
        r, g, b = hsv_to_rgb(h, s, v)
        return { r = r, g = g, b = b, a = 1 }
    end
end

local function get_fluid_visualization_color(fluid)
    if data and fluid.visualization_color then
        return fluid.visualization_color
    else
        local base_color = fluid.base_color
        local r, g, b = base_color.r or base_color[1], base_color.g or base_color[2], base_color.b or base_color[3]
        local h, s, v = rgb_to_hsv(r, g, b)
        s = s * 0.9
        v = math.min(0.8, v * 2)
        r, g, b = hsv_to_rgb(h, s, v)
        return { r = r, g = g, b = b, a = 1 }
    end
end

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

rendering.clear()
local pipes = game.player.surface.find_entities_filtered { type = "pipe" }
for _, pipe in pairs(pipes) do
    pipe.destroy()
end

local color_overrides = {}
color_overrides["heavy-oil"] = "red"
color_overrides["holmium-solution"] = "pink"

local position = { x = -50, y = 10 }
local function draw_labels()
    local labels = {
        { text = "Fluid base_color", offset = -3.25 },
        { text = "Fluid visualization_color", offset = -2.25 },
        { text = "Modified visualization_color", offset = -1.25 },
        { text = "Fluid Color Pipes", offset = -0.25 },
        { text = "Closest Named Color", offset = 5.75 },
        { text = "Named Color Pipes", offset = 7.25 },
    }

    for _, label in ipairs(labels) do
        rendering.draw_text {
            text = label.text,
            color = { r = 1, g = 1, b = 1, a = 1 },
            scale = 1,
            target = { position.x - 5.5, position.y + label.offset },
            surface = game.player.surface,
        }
    end
end
draw_labels()

for _, fluid in pairs(prototypes.fluid) do
    if (not fluid.parameter) and (not fluid.hidden) then
        local fluid_name = fluid.name
        local visualization_color = get_fluid_visualization_color(fluid)
        local base_fluid_visualization_color = get_base_fluid_visualization_color(fluid)
        local closest_named_color = color_overrides[fluid_name] or get_closest_named_color(visualization_color)
        rendering.draw_circle {
            color = fluid.base_color,
            radius = 0.4,
            filled = true,
            target = { position.x + 0.5, position.y - 3 },
            surface = game.player.surface,
        }
        rendering.draw_circle {
            color = base_fluid_visualization_color,
            radius = 0.4,
            filled = true,
            target = { position.x + 0.5, position.y - 2 },
            surface = game.player.surface,
        }
        rendering.draw_circle {
            color = visualization_color,
            radius = 0.5,
            filled = true,
            target = { position.x + 0.5, position.y - 1 },
            surface = game.player.surface,
        }
        rendering.draw_circle {
            color = rgb_colors[closest_named_color],
            radius = 0.6,
            filled = true,
            target = { position.x + 0.5, position.y + 6 },
            surface = game.player.surface,
        }
        for i = 0, 4 do
            local pipe = game.player.surface.create_entity {
                name = fluid_name .. "-color-coded-pipe",
                position = { position.x, position.y + i },
                force = game.player.force,
            } or {}
            pipe.insert_fluid { name = fluid.name, amount = 1000 }
        end
        for i = 0, 4 do
            local pipe = game.player.surface.create_entity {
                name = closest_named_color .. "-color-coded-pipe",
                position = { position.x, position.y + 7 + i },
                force = game.player.force,
            } or {}
            pipe.insert_fluid { name = fluid.name, amount = 1000 }
        end
        position.x = position.x + 2
        if position.x > 50 then
            position.x = -50
            position.y = position.y + 17
            draw_labels()
        end
    end
end
