local AddPrefabPostInit = AddPrefabPostInit
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

-- Groups each vanilla area attack into one Horror Chain attack, so a chain
-- member takes at most one hit from it, directly or propagated.

local HorrorChainUtil = require("nightstories/horrorchainutil")
local run = HorrorChainUtil.Run

local NO_OPTS = {}
local ATTACKED = { attacked = true }
local RESIST_ATTACKED = { attacked = true, resist = true }
local SUPPRESS = { suppress = true }

local function no_opts()
	return NO_OPTS
end

local function wrap_method(class, name, get_opts)
	local fn = class[name]
	class[name] = function(self, ...)
		return run(get_opts(self, ...), fn, self, ...)
	end
end

local function wrap_field(t, name, opts)
	local fn = t[name]
	t[name] = function(...)
		return run(opts, fn, ...)
	end
end

-------------------------------------------------------------------------
-- Components
-------------------------------------------------------------------------

local ExplosiveResist = require("components/explosiveresist")
local get_resistance = ExplosiveResist.GetResistance
function ExplosiveResist:GetResistance(...)
	local resistance = get_resistance(self, ...)
	HorrorChainUtil.NoteResistance(self.inst, resistance)
	return resistance
end

-- Projectile hits, including on-hit splash such as slingshot ammo, catapults and dumbbells.
local function projectile_opts(self)
	return { attacked = true, flush_on_remove = self.inst }
end
wrap_method(require("components/projectile"), "Hit", projectile_opts)
wrap_method(require("components/complexprojectile"), "Hit", projectile_opts)

wrap_method(require("components/explosive"), "OnBurnt", function(self)
	return { explosive = self.inst, flush_on_remove = self.inst }
end)

local GroundPounder = require("components/groundpounder")
local destroy_ring = GroundPounder.DestroyRing
-- Rings share ents_hit across delayed calls; share one attack with them.
function GroundPounder:DestroyRing(pt, radius, points, breakobjects, dodamage, pushplatforms, pushinventoryitems, spawnfx, ents_hit, ...)
	ents_hit = ents_hit or {}
	local opts = {
		key = ents_hit,
		on_propagated = function(member)
			ents_hit[member] = true
		end,
	}
	return run(opts, destroy_ring, self, pt, radius, points, breakobjects, dodamage, pushplatforms, pushinventoryitems, spawnfx, ents_hit, ...)
end
wrap_method(GroundPounder, "DestroyPoints", no_opts)
wrap_method(GroundPounder, "GroundPound_Offscreen", no_opts)

-- Charges reuse one ignore table across frames.
wrap_method(require("components/tackler"), "CheckCollision", function(_, ignores)
	if ignores == nil then
		return NO_OPTS
	end
	return {
		key = ignores,
		on_propagated = function(member)
			ignores[member] = true
		end,
	}
end)

wrap_method(require("components/joustsource"), "CheckCollision", function(_, _, targets)
	return {
		key = targets,
		on_propagated = function(member)
			targets[member] = GetTime()
		end,
	}
end)

wrap_method(require("components/aoeweapon_lunge"), "DoLunge", no_opts)

-- Periodic aura damage is excluded.
wrap_method(require("components/aura"), "OnTick", function()
	return SUPPRESS
end)

-------------------------------------------------------------------------
-- Prefabs
-------------------------------------------------------------------------

AddPrefabPostInit("wortox_soul_spawn", function(inst)
	if TheWorld.ismastersim then
		wrap_field(inst, "SoulSpearTick", RESIST_ATTACKED)
	end
end)

AddPrefabPostInit("wortox_decoy", function(inst)
	if TheWorld.ismastersim then
		-- Thorns retaliate against one attacker and are excluded.
		wrap_field(inst, "DoThorns", SUPPRESS)
		wrap_field(inst, "DoExplosion", RESIST_ATTACKED)
	end
end)

AddPrefabPostInit("trident", function(inst)
	if TheWorld.ismastersim then
		wrap_field(inst.components.spellcaster, "spell", ATTACKED)
	end
end)

-- Drone zaps expand over several frames and hit each target once.
local function wrap_drone_zap(inst)
	if not TheWorld.ismastersim then
		return
	end
	local updatelooper = inst.components.updatelooper
	local on_update = updatelooper.OnUpdate
	local opts = {
		key = inst,
		on_propagated = function(member)
			if inst.targets ~= nil then
				inst.targets[member] = true
			end
		end,
	}
	updatelooper.OnUpdate = function(...)
		return run(opts, on_update, ...)
	end
end
AddPrefabPostInit("wagdrone_projectile_fx", wrap_drone_zap)
AddPrefabPostInit("wx78_drone_zap_projectile_fx", wrap_drone_zap)

-------------------------------------------------------------------------
-- Stategraphs
-------------------------------------------------------------------------

-- Weremoose smash attacks every target in front from an attack timeline event.
AddStategraphPostInit("wilson", function(sg)
	local state = sg.states.attack
	if state == nil or state.timeline == nil then
		return
	end
	for _, event in ipairs(state.timeline) do
		wrap_field(event, "fn", NO_OPTS)
	end
end)
