local AddPrefabPostInit = AddPrefabPostInit
local devassert = devassert
local UpvalueUtil = GlassicAPI.UpvalueUtil
GLOBAL.setfenv(1, GLOBAL)

local patched = false

AddPrefabPostInit("charlie_boss", function(inst)
	if not TheWorld.ismastersim or patched then
		return
	end

	local path = "SetReflectingProjectiles.OnBlocked"
	local onblocked = devassert(UpvalueUtil.GetUpvalue(inst.ToggleReflectingProjectiles, path), "Could not find Charlie's projectile reflection callback")
	local tryaggro = onblocked and devassert(UpvalueUtil.GetUpvalue(onblocked, "TryAggro"), "Could not find Charlie's reflection aggro callback")
	if not tryaggro then
		patched = true
		return
	end

	local function OnBlocked(boss, data)
		if data and data.weapon and data.weapon.prefab == "queen_torch" then
			-- Vanilla prefabs/charlie_boss.lua:OnBlocked (762172): copy of its aggro, without reflecting the projectile
			local attacker = data.attacker
			if attacker and attacker:IsValid() then
				tryaggro(boss, attacker)
			end
			return
		end
		return onblocked(boss, data)
	end

	UpvalueUtil.SetUpvalue(inst.ToggleReflectingProjectiles, path, OnBlocked)
	-- Vanilla prefabs/charlie_boss.lua:SetReflectingProjectiles (762172): adds and removes the one file-level OnBlocked for every instance
	if inst.isreflectingprojectiles then
		inst:RemoveEventCallback("blocked", onblocked)
		inst:ListenForEvent("blocked", OnBlocked)
	end
	patched = true
end)
