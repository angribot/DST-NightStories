local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function OnEntityReplicated(inst)
	if inst.replica.container then
		inst.replica.container.acceptsstacks = true
	end
end

AddPrefabPostInit("meatrack", function(inst)
	if not TheWorld.ismastersim then
		inst.OnEntityReplicated = OnEntityReplicated
		return
	end

	local container = inst.components.container
	removesetter(container, "acceptsstacks")
	inst.components.container.acceptsstacks = true
	if inst.replica.container then
		inst.replica.container.acceptsstacks = true
	end
	makereadonly(container, "acceptsstacks")
end)
