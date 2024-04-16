
data:extend{
    {
        type = "bool-setting",
        name = "color-coded-pipes-restrict-to-fluids",
        setting_type = "startup",
        default_value = false,
        order = "a",
    },
    {
        type = "string-setting",
        name = "color-coded-pipes-color-mode",
        setting_type = "startup",
        default_value = "neon",
        allowed_values = { "weathered", "neon", "fluid" },
        order = "b",
    },
    
}