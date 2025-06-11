
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

return {
    replace_dash_with_underscore = replace_dash_with_underscore,
    append = append,
    get_color = get_color,
}
