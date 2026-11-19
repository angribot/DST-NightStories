local TUNING = GLOBAL.TUNING

AddPrefabPostInit("dreadstone", function(inst)
	if GLOBAL.TheWorld.ismastersim then
		inst.components.repairer.finiteusesrepairvalue = TUNING.SALTLICK_DREADSTONE_MAX_LICKS / TUNING.SALTLICK_DREADSTONE_RECIPE_COST
	end
end)
