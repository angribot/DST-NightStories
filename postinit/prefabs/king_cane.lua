local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("king_cane", function(inst)
	inst:AddTag("flyingbroom")
end)
