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
local Utils = require("ns_utils")
local do_attack = Combat.DoAttack
local do_area_attack = Combat.DoAreaAttack
local get_attacked = Combat.GetAttacked

function Combat:GetAttacked(...)
	return Utils.WithAttackSource(nil, get_attacked, self, ...)
end

local function do_attack_with_context(self, ...)
	return Utils.WithAttackSource(self.inst, do_attack, self, ...)
end

function Combat:DoAreaAttack(...)
	return Utils.WithAttackSource(self.inst, do_area_attack, self, ...)
end

local function ranged_weapon_testfn(weapon, projectile)
	return weapon ~= nil and projectile == nil and (weapon.components.projectile ~= nil or weapon.components.complexprojectile ~= nil or weapon.components.weapon:CanRangedAttack())
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

	do_attack_with_context(self, target, weapon, projectile, ...)

	if weapon == nil and ranged_weapon_testfn(self:GetWeapon(), projectile) then
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
