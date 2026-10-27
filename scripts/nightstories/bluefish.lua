local M = {}

M.builds = {
	merm = "merm_bluefish",
	merm_lunar = "merm_lunar_bluefish",
	merm_shadow = "merm_shadow_bluefish",
}

M.skins = {
	merm = "merm_bluefish",
	merm_lunar = "merm_lunar_bluefish",
	merm_shadow = "merm_shadow_bluefish",
}

M.defaults = {
	merm = "merm_build",
	merm_lunar = "merm_lunar_build",
	merm_shadow = "merm_shadow_build",
}

local symbols = { "pig_head", "pig_torso", "pig_arm", "pig_leg", "pig_ear", "pig_cheeks", "merm_mutation_parts" }

function M.IsSupported(inst)
	return inst ~= nil and M.builds[inst.prefab] ~= nil
end

function M.CanSweep(doer, target)
	if not M.IsSupported(target) or not target:IsValid() or doer == nil or not doer:HasTag("player") then
		return false
	end
	if target:HasTag("INLIMBO") or target:HasTag("NOCLICK") or target:HasTag("corpse") or target.reskin_tool_cannot_target_this then
		return false
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return false
	end
	local follower = target.components.follower or (target.replica and target.replica.follower)
	return follower ~= nil and follower:GetLeader() == doer
end

function M.Apply(inst, prefab, active)
	local build = M.builds[prefab]
	if build == nil then
		return
	end
	for _, symbol in ipairs(symbols) do
		if active then
			inst.AnimState:OverrideSymbol(symbol, build, symbol)
		else
			inst.AnimState:ClearOverrideSymbol(symbol)
		end
	end
	if prefab == "merm_shadow" then
		if active then
			inst.AnimState:SetMultColour(1, 1, 1, 0.85)
			inst.AnimState:UsePointFiltering(false)
		else
			inst.AnimState:SetMultColour(0, 0, 0, 0.5)
			inst.AnimState:UsePointFiltering(true)
		end
	end
end

function M.PlayFX(inst, tool)
	local skinfx = tool ~= nil and SKIN_FX_PREFAB[tool:GetSkinName()] or nil
	local fx = SpawnPrefab(skinfx ~= nil and skinfx[1] or "explode_reskin")
	if fx ~= nil then
		local x, y, z = inst.Transform:GetWorldPosition()
		fx.Transform:SetPosition(x, y + 0.8, z)
		fx.Transform:SetScale(1.3, 1.3, 1.3)
	end
end

return M
