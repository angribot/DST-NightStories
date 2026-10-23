GLOBAL.setfenv(1, GLOBAL)

local DISABLED_WEAPONS = {
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

function Combat:DoAttack(target, weapon, projectile, ...)
	if target == nil then
		target = self.target
	end

	local source_weapon = weapon or self:GetWeapon()
	local launching = ranged_weapon_testfn(source_weapon, projectile)
	do_attack_with_context(self, target, weapon, projectile, ...)

	if launching then
		return
	elseif source_weapon and (source_weapon:HasTag("glash") or DISABLED_WEAPONS[source_weapon.prefab]) then
		return
	elseif DISABLED_ENTITIES[self.inst.prefab] then
		return
	end

	local manager = TheWorld.components.horrorchainmanager
	if manager:HasMember(target) and self:CanHitTarget(target, source_weapon) then
		for _, ent in ipairs(manager:GetNearbyMembers(target)) do
			if ent ~= target then
				manager:QueueAttack(self, ent, source_weapon, projectile, ...)
			end
		end
	end

	return
end
