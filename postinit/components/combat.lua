GLOBAL.setfenv(1, GLOBAL)

local Combat = require("components/combat")
local Utils = require("nightstories/utils")
local HorrorChainUtil = require("nightstories/horrorchainutil")
local do_attack = Combat.DoAttack
local do_area_attack = Combat.DoAreaAttack
local get_attacked = Combat.GetAttacked
local get_attacked_internal = Combat.GetAttacked_Internal

local function do_attack_with_source(self, ...)
	return Utils.WithAttackSource(self.inst, do_attack, self, ...)
end

local function do_area_attack_with_source(self, ...)
	return Utils.WithAttackSource(self.inst, do_area_attack, self, ...)
end

local function get_attacked_with_source(self, ...)
	return Utils.WithAttackSource(nil, get_attacked, self, ...)
end

function Combat:DoAttack(target, weapon, projectile, stimuli, instancemult, ...)
	if target == nil then
		target = self.target
	end
	return HorrorChainUtil.DoAttack(self, target, weapon, projectile, instancemult, do_attack_with_source, self, target, weapon, projectile, stimuli, instancemult, ...)
end

function Combat:DoAreaAttack(target, range, weapon, validfn, stimuli, excludetags, ...)
	return HorrorChainUtil.DoAreaAttack(self, range, validfn, excludetags, do_area_attack_with_source, self, target, range, weapon, validfn, stimuli, excludetags, ...)
end

function Combat:GetAttacked(attacker, ...)
	return HorrorChainUtil.GetAttacked(self, attacker, get_attacked_with_source, self, attacker, ...)
end

function Combat:GetAttacked_Internal(attacker, damage, weapon, stimuli, spdamage, ...)
	return HorrorChainUtil.GetAttackedInternal(self, attacker, damage, weapon, stimuli, spdamage, get_attacked_internal, self, attacker, damage, weapon, stimuli, spdamage, ...)
end
