local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("queen_torch", function(inst)
	inst:AddTag("rangedweapon")
	inst.projectiledelay = FRAMES

	if not TheWorld.ismastersim then
		return
	end

	inst.components.weapon:SetRange(8, 10)
	inst.components.weapon:SetProjectile("ns_queen_torch_projectile")
end)
