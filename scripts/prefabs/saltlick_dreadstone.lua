require("prefabutil")

local BUILD = "salt_lick_dreadstone_build"

local assets = {
	Asset("ANIM", "anim/salt_lick.zip"),
	Asset("ANIM", "anim/" .. BUILD .. ".zip"),
}

local prefabs = { "saltlick_improved", "collapse_small" }

local function OnHammered(inst)
	inst.components.lootdropper:DropLoot()

	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("stone")

	inst:Remove()
end

local function Repair(self, doer, item)
	local inst = self.inst
	local uses = inst.components.finiteuses
	local repairer = item.components.repairer
	if repairer.repairmaterial ~= self.repairmaterial or repairer.finiteusesrepairvalue <= 0 or uses:GetPercent() >= 1 then
		return false
	end

	-- Vanilla components/repairable.lua:address_repair_amount (762172): stops at full work before finite uses, rejecting dreadstone
	local depleted = uses:GetUses() == 0
	uses:Repair(repairer.finiteusesrepairvalue)
	item.components.stackable:Get():Remove()
	self.onrepaired(inst, doer, item)
	if depleted then
		inst:AlertNearbyCritters()
	end
	return true
end

local function fn()
	local inst = Prefabs.saltlick_improved.fn()
	inst.AnimState:SetBuild(BUILD)
	inst.MiniMapEntity:SetIcon("saltlick_dreadstone.tex")

	if not TheWorld.ismastersim then
		return inst
	end

	local uses = inst.components.finiteuses
	uses:SetMaxUses(TUNING.SALTLICK_DREADSTONE_MAX_LICKS)
	uses:SetUses(TUNING.SALTLICK_DREADSTONE_MAX_LICKS)

	inst.components.repairable.repairmaterial = MATERIALS.DREADSTONE
	inst.components.repairable.Repair = Repair
	inst.components.workable:SetOnFinishCallback(OnHammered)

	return inst
end

return Prefab("saltlick_dreadstone", fn, assets, prefabs), MakePlacer("saltlick_dreadstone_placer", "salt_lick", BUILD, "idle1")
