local assets = {
	Asset("ANIM", "anim/ns_queen_torch_projectile.zip"),
	Asset("ANIM", "anim/ns_queen_torch_burst.zip"),
}

local MUST_TAGS = { "_combat" }
local NO_TAGS = { "INLIMBO", "wall", "notarget", "player", "companion", "flight", "invisible", "noattack", "hiding" }

local function IsAlive(target)
	return target ~= nil and target:IsValid() and not target:IsInLimbo() and not (target.components.health ~= nil and target.components.health:IsDead())
end

local function OnThrown(inst, weapon, target, attacker)
	inst.weapon = weapon
	inst.attacker = attacker
	inst.initial_hostile = target:HasTag("hostile")
end

local function CanSplash(inst, target, attacker)
	return IsAlive(target)
		and target.entity:IsVisible()
		and attacker.components.combat:CanTarget(target)
		and not attacker.components.combat:IsAlly(target)
		-- Vanilla prefabs/brilliance_projectile_fx.lua:TryBounce (762172): skips new neutral targets without a locomotor after a hostile first target
		and not (inst.initial_hostile and not target:HasTag("hostile") and target.components.locomotor == nil)
end

-- Vanilla components/projectile.lua:Projectile:Hit (763928): copied, crediting the thrower instead of the torch's direct holder and adding the splash
local function Hit(self, target)
	local inst = self.inst
	local attacker = inst.attacker
	local weapon = inst.weapon
	if
		not IsAlive(attacker)
		or attacker.components.combat == nil
		or weapon == nil
		or not weapon:IsValid()
		or weapon.components.weapon == nil
		or weapon.components.inventoryitem == nil
		or weapon.components.inventoryitem:GetGrandOwner() ~= attacker
		or not IsAlive(target)
		or not target.entity:IsVisible()
		or not attacker.components.combat:CanTarget(target)
	then
		self:Miss(target)
		return
	end

	local pos = target:GetPosition()
	self:Stop()
	inst.Physics:Stop()
	local combat = attacker.components.combat
	local ignorehitrange = combat.ignorehitrange
	combat.ignorehitrange = true
	combat:DoAttack(target, weapon, inst, self.stimuli)
	if inst:IsValid() then
		local fx = SpawnPrefab("ns_queen_torch_burst")
		fx.Transform:SetPosition(pos:Get())
		for _, ent in ipairs(TheSim:FindEntities(pos.x, pos.y, pos.z, TUNING.QUEEN_TORCH_AOE_RADIUS + TUNING.QUEEN_TORCH_AOE_RANGE_PADDING, MUST_TAGS, NO_TAGS)) do
			if not IsAlive(attacker) or not weapon:IsValid() or weapon.components.weapon == nil then
				break
			end
			if ent ~= target and ent ~= attacker and CanSplash(inst, ent, attacker) then
				local radius = TUNING.QUEEN_TORCH_AOE_RADIUS + ent:GetPhysicsRadius(0)
				if ent:GetDistanceSqToPoint(pos.x, pos.y, pos.z) < radius * radius then
					combat:DoAttack(ent, weapon, inst)
				end
			end
		end
		inst:Remove()
	end
	combat.ignorehitrange = ignorehitrange
end

local function ProjectileFn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	RemovePhysicsColliders(inst)
	inst.AnimState:SetBank("projectile")
	inst.AnimState:SetBuild("ns_queen_torch_projectile")
	inst.AnimState:PlayAnimation("fire_spin_loop", true)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetLightOverride(1)
	inst:AddTag("projectile")
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false
	inst:AddComponent("projectile")
	local projectile = inst.components.projectile
	projectile:SetSpeed(50)
	projectile:SetOnThrownFn(OnThrown)
	projectile:SetOnMissFn(inst.Remove)

	projectile.Hit = Hit

	return inst
end

local function BurstFn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst.AnimState:SetBank("fire_fail_fx")
	inst.AnimState:SetBuild("ns_queen_torch_burst")
	inst.AnimState:PlayAnimation("fx")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetLightOverride(1)
	inst.Transform:SetScale(1.5, 1.5, 1.5)
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false
	inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
	inst:ListenForEvent("animover", inst.Remove)
	return inst
end

return Prefab("ns_queen_torch_projectile", ProjectileFn, assets, { "ns_queen_torch_burst" }), Prefab("ns_queen_torch_burst", BurstFn, assets)
