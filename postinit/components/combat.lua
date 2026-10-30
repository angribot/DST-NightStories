GLOBAL.setfenv(1, GLOBAL)

local DISABLED_WEAPONS = {
	glash = true,
	shadowglash = true,
	alterguardianhat = true,
}

local DISABLED_ENTITIES = {
	alterguardianhat_projectile = true,
}

local Combat = require("components/combat")
local Utils = require("nightstories/utils")
local SpDamageUtil = require("components/spdamageutil")
local do_attack = Combat.DoAttack
local do_area_attack = Combat.DoAreaAttack
local get_attacked = Combat.GetAttacked

local function get_attacked_with_context(self, attacker, ...)
	return Utils.WithAttackSource(nil, get_attacked, self, attacker, ...)
end

local function can_hit_explosion_target(bomb, target)
	local explosive = bomb.components.explosive
	return target ~= bomb
		and target:IsValid()
		and not target:IsInLimbo()
		and not target:HasTag("notarget")
		and not (target.components.health ~= nil and target.components.health:IsDead())
		and target.components.combat ~= nil
		and target.components.combat:CanBeAttacked()
		and (explosive.pvpattacker == nil or target == explosive.pvpattacker or not target.isplayer)
end

local function chain_explosion_hit(bomb, target)
	local explosive = bomb.components.explosive
	-- Calculate fresh damage for each target's alignment bonus and defenses.
	local stacksize = bomb.components.stackable ~= nil and bomb.components.stackable:StackSize() or 1
	local mult = bomb.components.damagetypebonus ~= nil and bomb.components.damagetypebonus:GetBonus(target) or 1
	local damage = explosive.explosivedamage * stacksize * mult
	if target.components.explosiveresist ~= nil then
		damage = damage * (1 - target.components.explosiveresist:GetResistance())
		target.components.explosiveresist:OnExplosiveDamage(damage, bomb)
	end
	local spdamage = SpDamageUtil.ApplyMult(SpDamageUtil.CollectSpDamage(bomb), mult * stacksize)
	-- The native receiver bypasses chain propagation, preventing recursive hops.
	get_attacked_with_context(target.components.combat, bomb, damage, nil, nil, spdamage)

	local attacker = explosive.attacker or explosive.pvpattacker
	if
		attacker ~= nil
		and attacker:IsValid()
		and target:IsValid()
		and target.components.combat ~= nil
		and not (target.components.health ~= nil and target.components.health:IsDead())
	then
		target.components.combat:SuggestTarget(attacker)
	end
end

local function chain_explosion(combat, bomb, ...)
	bomb._ns_attack_hits = bomb._ns_attack_hits or {}
	-- Capture before a lethal hit removes the anchor's chain membership.
	local members = TheWorld.components.horrorchainmanager:GetNearbyMembers(combat.inst)
	local result = Utils.WithAttackHit(bomb, combat.inst, nil, get_attacked_with_context, combat, bomb, ...)
	-- Direct anchors still propagate after another anchor has already hit them.
	for _, target in ipairs(members) do
		if target ~= combat.inst and can_hit_explosion_target(bomb, target) then
			Utils.WithAttackHit(bomb, target, nil, chain_explosion_hit, bomb, target)
		end
	end
	return result
end

function Combat:GetAttacked(attacker, ...)
	if attacker ~= nil and attacker.prefab == "bomb_lunarplant" and attacker.components.explosive ~= nil then
		return chain_explosion(self, attacker, ...)
	end
	return get_attacked_with_context(self, attacker, ...)
end

local function do_attack_with_source(self, ...)
	return Utils.WithAttackSource(self.inst, do_attack, self, ...)
end

local function do_attack_with_context(self, target, weapon, projectile, ...)
	return Utils.WithAttackHit(projectile, target, self.CanHitTarget, do_attack_with_source, self, target, weapon, projectile, ...)
end

function Combat:DoAreaAttack(...)
	return Utils.WithAttackSource(self.inst, do_area_attack, self, ...)
end

local function is_projectile_launch(weapon, projectile)
	if weapon == nil or projectile ~= nil then
		return false
	end
	local components = weapon.components
	-- Match the native DoAttack launch branches, including melee projectiles.
	return components.projectile ~= nil
		or (components.complexprojectile ~= nil and not components.complexprojectile.ismeleeweapon)
		or (components.weapon ~= nil and components.weapon:CanRangedAttack())
end

local function is_invalid_weapon(weapon)
	return weapon and not weapon.components.weapon
end

local function do_attack_with_check(self, target, weapon, projectile, ...)
	if not is_invalid_weapon(weapon) then
		if projectile and weapon and weapon.components.finiteuses then
			local prev = weapon.components.finiteuses.ignorecombatdurabilityloss
			weapon.components.finiteuses.ignorecombatdurabilityloss = true
			local result = do_attack_with_context(self, target, weapon, projectile, ...)
			weapon.components.finiteuses.ignorecombatdurabilityloss = prev
			return result
		end
		return do_attack_with_context(self, target, weapon, projectile, ...)
	end
end

function Combat:DoAttack(target, weapon, projectile, ...)
	if target == nil then
		target = self.target
	end

	-- Resolve before native attacks can drop the weapon or change equipment.
	local launching_projectile = is_projectile_launch(weapon or self:GetWeapon(), projectile)
	do_attack_with_context(self, target, weapon, projectile, ...)

	if launching_projectile then
		return
	elseif weapon and DISABLED_WEAPONS[weapon.prefab] then
		return
	elseif DISABLED_ENTITIES[self.inst.prefab] then
		return
	end

	if TheWorld.components.horrorchainmanager:HasMember(target) then
		local ents = TheWorld.components.horrorchainmanager:GetNearbyMembers(target)
		for _, ent in ipairs(ents) do
			if ent ~= target then
				local can_hit_target = self.CanHitTarget
				self.CanHitTarget = function()
					return can_hit_target(self, target, weapon)
				end
				do_attack_with_check(self, ent, weapon, projectile, ...)
				self.CanHitTarget = can_hit_target
			end
		end
	end

	return
end
