local function get_color(setting)
    local value = settings.startup[setting].value
    return value
end
local function rgb_to_hsv(r, g, b)
    if (r > 1) or (g > 1) or (b > 1) then
        r = r / 255
        g = g / 255
        b = b / 255
    end
    local mn = math.min(r, g, b)
    local mx = math.max(r, g, b)
    local d = mx - mn
    local h, s, v = 0, 0, mx
    if mx ~= 0 then s = d / mx end
    if d ~= 0 then
        if r == mx then h = (g - b) / d elseif g == mx then h = 2 + (b - r) / d else h = 4 + (r - g) / d end
        h = h * 60
        if h < 0 then h = h + 360 end
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
        r1, g1, b1 =
            0, x, c
    elseif h < 300 then
        r1, g1, b1 = x, 0, c
    else
        r1, g1, b1 = c, 0, x
    end
    return r1 + m, g1 + m, b1 + m
end
local function get_fluid_visualization_color(fluid)
    if data and fluid.visualization_color then
        return fluid
            .visualization_color
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
    white = get_color("color-coded-pipes-white")
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
        return name
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

    return closest_name, math.sqrt(min_d2)
end

local start_pos = { x = -60, y = -80 }
local hue_steps = 36
local sat_steps = 11
local val_steps = 11
local cell_size = 0.35
local hue_span_tiles = (hue_steps - 1) * cell_size
local row_step = cell_size
local col_step = cell_size
local slice_gap = cell_size * 3.5
local left_margin = 4.0
local dot_radius = cell_size * 0.25
local hue_tick_deg = 60
local label_scale = 0.8
local label_color = { r = 1, g = 1, b = 1, a = 1 }
local USE_FLUID_VIZ = true
local SHOW_HUE_BOUNDARIES = false
local HUE_BOUNDARY_WIDTH = 1.0
local HUE_BOUNDARY_ALPHA = 0.25
local SHOW_DISTANCE_OVERLAY = false
local UNDERLAY_SCALE = 1.6
local UNDERLAY_ALPHA = 0.6
local BACKGROUND_HSV = true
local STRENGTH_TEXT = false
local STRENGTH_MAX_DIST = 0.125
local STRENGTH_DECIMALS = 2
local STRENGTH_SCALE = 0.65
local surface = game.player.surface
local CELL_PAD_X = math.min(col_step * 0.10, dot_radius * 0.6)
local CELL_PAD_Y = math.min(row_step * 0.10, dot_radius * 0.6)
local INNER_GAP   = math.min(col_step, row_step) * 0.05
local BORDER_A    = 0.2
local BORDER_W    = 0.02
local CIRCLE_OUTLINE_A = 0.45

local function draw_text(txt, x, y, align, scale, color) rendering.draw_text { text = txt, surface = surface, target = { x, y }, color = color or label_color, scale = scale or label_scale, alignment = align or "left", scale_with_zoom = false } end
local function hsv_color(h, s, v)
    local r, g, b = hsv_to_rgb(h, s, v)
    local c = { r = r, g = g, b = b, a = 1 }
    return c
end
rendering.clear()
draw_text("HSV space — slices by Value (V).  Each slice: Hue (→) × Saturation (↓).", start_pos.x, start_pos.y - 2, "left")
for v_i = 0, val_steps - 1 do
    local v = (val_steps > 1) and (1 - (v_i / (val_steps - 1))) or 1
    local slice_top_y = start_pos.y + v_i * (sat_steps * row_step + slice_gap)
    local origin_x = start_pos.x + left_margin
    local origin_y = slice_top_y
    draw_text(string.format("V = %.2f", v), start_pos.x, origin_y - row_step * 0.6, "left")
    if SHOW_HUE_BOUNDARIES then
        local top_y = origin_y - row_step * 0.25
        local bot_y = origin_y + sat_steps * row_step + row_step * 0.25
        for deg = 0, 360, hue_tick_deg do
            local x = origin_x + (deg / 360) * hue_span_tiles
            rendering.draw_line { color = { r = 1, g = 1, b = 1, a = HUE_BOUNDARY_ALPHA }, width = HUE_BOUNDARY_WIDTH, from = { x, top_y }, to = { x, bot_y }, surface = surface }
        end
    end
    for s_i = 0, sat_steps - 1 do
        local s = (sat_steps > 1) and (1 - (s_i / (sat_steps - 1))) or 1
        local row_y = origin_y + s_i * row_step
        draw_text(string.format("S=%.2f", s), start_pos.x, row_y, "left")
        for h_i = 0, hue_steps - 1 do
            local h      = (h_i / hue_steps) * 360.0
            local raw    = hsv_color(h, s, v)
            local viz    = get_fluid_visualization_color({ base_color = raw })

            local cx     = origin_x + h_i * col_step
            local left   = cx - col_step * 0.5 + CELL_PAD_X
            local right  = cx + col_step * 0.5 - CELL_PAD_X
            local top    = row_y - row_step * 0.5 + CELL_PAD_Y
            local bottom = row_y + row_step * 0.5 - CELL_PAD_Y

            local mid_x  = (left + right) * 0.5
            local mid_y  = (top + bottom) * 0.5

            local tl     = { x1 = left, y1 = top, x2 = mid_x - INNER_GAP * 0.5, y2 = mid_y - INNER_GAP * 0.5 }
            local tr     = { x1 = mid_x + INNER_GAP * 0.5, y1 = top, x2 = right, y2 = mid_y - INNER_GAP * 0.5 }
            local bl     = { x1 = left, y1 = mid_y + INNER_GAP * 0.5, x2 = mid_x - INNER_GAP * 0.5, y2 = bottom }
            local br     = { x1 = mid_x + INNER_GAP * 0.5, y1 = mid_y + INNER_GAP * 0.5, x2 = right, y2 = bottom }

            local function fill_rect(r, col)
                rendering.draw_rectangle { color = col, left_top = { r.x1, r.y1 }, right_bottom = { r.x2, r.y2 }, filled = true, surface = surface }
            end
            local function center(r) return (r.x1 + r.x2) * 0.5, (r.y1 + r.y2) * 0.5 end
            local function draw_dividers()
                rendering.draw_line { color = { r = 1, g = 1, b = 1, a = BORDER_A }, width = BORDER_W, from = { mid_x, top }, to = { mid_x, bottom }, surface = surface }
                rendering.draw_line { color = { r = 1, g = 1, b = 1, a = BORDER_A }, width = BORDER_W, from = { left, mid_y }, to = { right, mid_y }, surface = surface }
            end
            local function circle_radius(rect)
                return math.min(rect.x2 - rect.x1, rect.y2 - rect.y1) * 0.30
            end
            local function draw_circle_with_outline(col, x, y, r)
                rendering.draw_circle { color = { r = 0, g = 0, b = 0, a = CIRCLE_OUTLINE_A }, radius = r * 1.12, filled = false, target = { x, y }, surface = surface }
                rendering.draw_circle { color = { r = col.r or col[1], g = col.g or col[2], b = col.b or col[3], a = 1 }, radius = r, filled = true, target = { x, y }, surface = surface }
            end
            local function draw_circle(col, x, y, r)
                rendering.draw_circle { color = { r = col.r or col[1], g = col.g or col[2], b = col.b or col[3], a = 1 }, radius = r, filled = true, target = { x, y }, surface = surface }
            end

            fill_rect(tl, raw)
            fill_rect(bl, viz)
            draw_dividers()

            local name_raw, dist_raw = get_closest_named_color(raw)
            local name_viz, dist_viz = get_closest_named_color(viz)
            local nraw = rgb_colors[name_raw]
            local nviz = rgb_colors[name_viz]

            local cx_tr, cy_tr = center(tr)
            local cx_br, cy_br = center(br)
            local r_tr = circle_radius(tr)
            local r_br = circle_radius(br)

            fill_rect(tr, nraw)
            fill_rect(br, nviz)
        end
    end
    local tick_y = origin_y + sat_steps * row_step + 0.2
    for deg = 0, 360, hue_tick_deg do
        local h_frac = deg / 360
        local x = origin_x + h_frac * hue_span_tiles
        draw_text(string.format("%d°", deg % 360), x, tick_y, "center")
    end
end
local legend_y = start_pos.y + val_steps * (sat_steps * row_step + slice_gap) + 1.5
draw_text("Left→Right: Hue 0–360°.  Top→Bottom in each slice: Saturation 1→0.  Slices top→bottom: Value 1→0.",
    start_pos.x, legend_y, "left")
if USE_FLUID_VIZ then
    draw_text("(Colors shown after get_fluid_visualization_color).", start_pos.x, legend_y + 0.6,
        "left")
end
