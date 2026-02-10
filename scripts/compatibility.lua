
-----------------------------------------------------------------------------------------------------
-- deploy the nulls-k2so-tweaks compatibility script in data-updates to pre-generate compat fluids --
-----------------------------------------------------------------------------------------------------

if mods["nulls-k2so-tweaks"] then
    local function replace_k2_fluid(k2_id, common_id)
        local fluid = data.raw["fluid"][common_id]
        if (fluid == nil) then
            fluid = table.deepcopy(data.raw["fluid"][k2_id])
            fluid.name = common_id
            fluid.localised_name = { "fluid-name." .. k2_id }
            fluid.localised_description = { "fluid-description." .. k2_id }
            data:extend({ fluid })
        end
    end

    replace_k2_fluid("kr-oxygen", "oxygen")
    replace_k2_fluid("kr-hydrogen", "hydrogen")
    replace_k2_fluid("kr-nitrogen", "nitrogen")
    replace_k2_fluid("kr-nitric-acid", "nitric-acid")
end

