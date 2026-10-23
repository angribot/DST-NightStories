local Utils = require("ns_utils")

local function IsAlive(inst)
	return inst ~= nil and inst:IsValid() and not inst:IsInLimbo() and not (inst.components.health ~= nil and inst.components.health:IsDead())
end

local function Capture(combat, target, weapon, projectile, stimuli, instancemult)
	local wc = weapon and weapon.components.weapon
	if not IsAlive(target) or target.components.combat == nil or (weapon and (not weapon:IsValid() or wc == nil)) then
		return
	end
	if stimuli == nil then
		if wc and wc.overridestimulifn then
			stimuli = wc.overridestimulifn(weapon, combat.inst, target)
		end
		if stimuli == nil and ((wc and wc.stimuli == "electric") or combat.inst.components.electricattacks ~= nil) then
			stimuli = "electric"
		end
	end
	local mult = 1
	if (stimuli == "electric" or (wc and wc.stimuli == "electric")) and not IsEntityElectricImmune(target) then
		mult = (wc and wc.electric_damage_mult or TUNING.ELECTRIC_DAMAGE_MULT) + (wc and wc.electric_wet_damage_mult or TUNING.ELECTRIC_WET_DAMAGE_MULT) * target:GetWetMultiplier()
	end
	local damage, spdamage = combat:CalcDamage(target, weapon, mult)
	local special
	if spdamage then
		special = {}
		for kind, amount in pairs(spdamage) do
			special[kind] = amount
		end
	end
	return {
		attacker = combat.inst,
		weapon = weapon,
		target = target,
		projectile = projectile,
		ranged = projectile ~= nil,
		stimuli = stimuli,
		damage = damage * (instancemult or 1),
		spdamage = special,
	}
end

local function ApplyHit(entry)
	local attacker, target, weapon = entry.attacker, entry.target, entry.weapon
	if not IsAlive(attacker) or not IsAlive(target) then
		return
	end
	local combat = attacker.components.combat
	if
		combat == nil
		or target.components.combat == nil
		or not target.components.combat:CanBeAttacked(attacker)
		or (weapon and (not weapon:IsValid() or weapon.components.weapon == nil))
	then
		return
	end

	-- The original projectile may have disappeared since collection. Never relaunch
	-- the weapon, or pass a removed entity to presentation callbacks.
	local projectile = entry.projectile
	if projectile and not projectile:IsValid() then
		projectile = nil
	end
	attacker:PushEvent("onattackother", { target = target, weapon = weapon, projectile = projectile, stimuli = entry.stimuli })
	local reflected, reflected_special = 0, nil
	local reflect_list = {}
	if not entry.ranged then
		reflected, reflected_special = combat:CalcReflectedDamage(target, entry.damage, weapon, entry.stimuli, reflect_list, entry.spdamage)
	end
	target.components.combat:GetAttacked_Internal(attacker, entry.damage, weapon, entry.stimuli, entry.spdamage, true)
	if weapon and weapon:IsValid() and weapon.components.weapon then
		local uses = weapon.components.finiteuses
		local ignore = uses and uses.ignorecombatdurabilityloss
		if uses and entry.ranged then
			uses.ignorecombatdurabilityloss = true
		end
		local ok, err = pcall(weapon.components.weapon.OnAttack, weapon.components.weapon, attacker, target, projectile)
		if uses then
			uses.ignorecombatdurabilityloss = ignore
		end
		if not ok then
			error(err, 0)
		end
	end
	if (reflected > 0 or reflected_special ~= nil) and IsAlive(attacker) and attacker.components.health then
		combat:GetAttacked_Internal(target, reflected, nil, nil, reflected_special, true)
		for _, hit in ipairs(reflect_list) do
			if hit.inst:IsValid() then
				hit.inst:PushEvent("onreflectdamage", hit)
			end
		end
	end
end

local function Apply(entry)
	-- One consolidated hit may proc glash once, but never propagates another chain.
	return Utils.WithAttackSource(entry.attacker, ApplyHit, entry)
end

return { Capture = Capture, Apply = Apply }
