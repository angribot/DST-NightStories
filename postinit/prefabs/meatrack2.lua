local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)
local UpvalueUtil = GlassicAPI.UpvalueUtil

local function OnEntityReplicated(inst)
	if inst.replica.container then
		inst.replica.container.acceptsstacks = true
	end
end

local function AcceptStacks(inst)
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
end

AddPrefabPostInit("meatrack", AcceptStacks)

--------------------------------------------------------------------------
-- Large Drying Rack: release a slot's whole salt count (see postinit/components/dryingracksaltcollector.lua)

local function SpawnSalt(count)
	local salt = SpawnPrefab("saltrock")
	salt.components.stackable:SetStackSize(count)
	return salt
end

-- Vanilla hermit_DoItemTaken, spawning the slot's whole salt count instead of a single salt.
local function DoItemTaken(inst, slot)
	if inst.components.container and inst.components.dryingracksaltcollector then
		local other = inst.components.container:GetItemInSlot(slot)
		if other then
			if other.components.driedsalticon == nil then
				local count = inst.components.dryingracksaltcollector:RemoveSalt(slot)
				if count then
					local salt = SpawnSalt(count)
					salt.Transform:SetPosition(inst.Transform:GetWorldPosition())
					salt.components.inventoryitem:OnDropped(true)
				end
			end
		else
			local count = inst.components.dryingracksaltcollector:RemoveSalt(slot)
			if count then
				inst.components.container:GiveItem(SpawnSalt(count), slot)
			end
		end
	end
end

-- Vanilla hermit_OnLoadPostPass, which runs the hermit_DoItemTaken check on every salted slot.
local function OnLoadPostPass(inst)
	if inst.components.container and inst.components.dryingracksaltcollector and inst.components.dryingracksaltcollector:HasSalt() then
		for i = 1, inst.components.container:GetNumSlots() do
			if inst.components.dryingracksaltcollector:HasSalt(i) then
				DoItemTaken(inst, i)
			end
		end
	end
end

-- Vanilla hermit_DumpAndRemoveSaltCollector, splitting the salt into full stacks.
local function DumpAndRemoveSaltCollector(inst)
	if inst.components.dryingracksaltcollector then
		local num = inst.components.dryingracksaltcollector:GetNumSalts()
		while num > 0 do
			local salt = inst.components.lootdropper:SpawnLootPrefab("saltrock")
			salt.components.stackable:SetStackSize(math.min(num, salt.components.stackable.maxsize))
			num = num - salt.components.stackable:StackSize()
		end
		inst:RemoveComponent("dryingracksaltcollector")
	end
end

AddPrefabPostInit("meatrack_hermit_multi", function(inst)
	AcceptStacks(inst)
	if not TheWorld.ismastersim then
		return
	end

	local fn = Prefabs.meatrack_hermit_multi.fn
	UpvalueUtil.SetUpvalue(fn, "master_postinit.hermit_OnItemLose.hermit_DoItemTaken", DoItemTaken)
	-- Shared by the hammer, deconstruction, burnt, and abandoned callbacks.
	UpvalueUtil.SetUpvalue(fn, "master_postinit.hermit_OnHammered.hermit_DumpAndRemoveSaltCollector", DumpAndRemoveSaltCollector)
	inst.OnLoadPostPass = OnLoadPostPass
end)
