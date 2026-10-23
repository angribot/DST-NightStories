local AddPrefabPostInit = AddPrefabPostInit
local UpvalueUtil = GlassicAPI.UpvalueUtil
GLOBAL.setfenv(1, GLOBAL)

local patched = false

AddPrefabPostInit("charlie_boss", function(inst)
	if not TheWorld.ismastersim or patched then
		return
	end

	local path = "SetReflectingProjectiles.OnBlocked"
	local onblocked = UpvalueUtil.GetUpvalue(inst.ToggleReflectingProjectiles, path)
	assert(onblocked, "Could not find Charlie's projectile reflection callback")
	local tryaggro = UpvalueUtil.GetUpvalue(onblocked, "TryAggro")
	assert(tryaggro, "Could not find Charlie's reflection aggro callback")

	local function OnBlocked(boss, data)
		if data and data.weapon and data.weapon.prefab == "queen_torch" then
			-- Keep aggro and ranged resistance, but do not register the callback
			-- that destroys the incoming projectile and spawns a countershot.
			local attacker = data.attacker
			if attacker and attacker:IsValid() then
				tryaggro(boss, attacker)
			end
			return
		end
		return onblocked(boss, data)
	end

	UpvalueUtil.SetUpvalue(inst.ToggleReflectingProjectiles, path, OnBlocked)
	-- The upvalue is shared by all instances and by enable/disable paths.
	if inst.isreflectingprojectiles then
		inst:RemoveEventCallback("blocked", onblocked)
		inst:ListenForEvent("blocked", OnBlocked)
	end
	patched = true
end)
