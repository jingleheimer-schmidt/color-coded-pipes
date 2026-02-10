
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


----------------------------------------------------
-- force k2-fluid-storage to use it's hr graphics --
----------------------------------------------------

if mods["k2-fluid-storage"] then
    local tank_1 = data.raw["storage-tank"]["kr-fluid-storage-1"]
    if tank_1 and tank_1.pictures and tank_1.pictures.picture and tank_1.pictures.picture.sheets then
        for id, sheet in pairs(tank_1.pictures.picture.sheets) do
            if sheet.hr_version then
                data.raw["storage-tank"]["kr-fluid-storage-1"].pictures.picture.sheets[id] = sheet.hr_version
            end
        end
    end
    local tank_2 = data.raw["storage-tank"]["kr-fluid-storage-2"]
    if tank_2 and tank_2.pictures and tank_2.pictures.picture and tank_2.pictures.picture.sheets then
        for id, sheet in pairs(tank_2.pictures.picture.sheets) do
            if sheet.hr_version then
                data.raw["storage-tank"]["kr-fluid-storage-2"].pictures.picture.sheets[id] = sheet.hr_version
            end
        end
    end
end
