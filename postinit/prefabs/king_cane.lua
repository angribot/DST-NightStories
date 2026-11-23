local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

-- Vanilla entityscript.lua:EntityScript:AddTag (762172): replicates tags through the engine without a client event
local function WrapCorruptionFn(fn, corrupted)
	return function(inst)
		inst._corrupted:set(corrupted)
		return fn(inst)
	end
end

AddPrefabPostInit("king_cane", function(inst)
	inst._corrupted = net_bool(inst.GUID, "king_cane.corrupted", "king_cane.corrupteddirty")

	if not TheWorld.ismastersim then
		return
	end

	local corruption = inst.components.corruption
	corruption:SetOnCorruptedFn(WrapCorruptionFn(corruption.oncorruptedfn, true))
	corruption:SetOnUncorruptedFn(WrapCorruptionFn(corruption.onuncorruptedfn, false))
end)
