local AddPrefabPostInit = AddPrefabPostInit
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

-- Source hooks for Horror Chain spreading. Combat calls are hooked in
-- postinit/components/combat.lua.

local HorrorChainUtil = require("nightstories/horrorchainutil")

local function wrap_field(t, name, scope)
	local fn = t[name]
	t[name] = function(...)
		return scope(fn, ...)
	end
end

-------------------------------------------------------------------------
-- Components
-------------------------------------------------------------------------

-- Let spread hits restore the damage before the anchor's explosive resistance.
local ExplosiveResist = require("components/explosiveresist")
local get_resistance = ExplosiveResist.GetResistance
local on_explosive_damage = ExplosiveResist.OnExplosiveDamage

function ExplosiveResist:GetResistance(...)
	local resistance = get_resistance(self, ...)
	HorrorChainUtil.NoteResistance(self.inst, resistance)
	return resistance
end

function ExplosiveResist:OnExplosiveDamage(damage, src, ...)
	HorrorChainUtil.NoteExplosiveDamage(self.inst, src)
	return on_explosive_damage(self, damage, src, ...)
end

-- Periodic aura damage never spreads.
wrap_field(require("components/aura"), "OnTick", HorrorChainUtil.Suppress)

-------------------------------------------------------------------------
-- Prefabs
-------------------------------------------------------------------------

-- Soul spears and decoy thorns and explosions all hit on Wortox's behalf
-- without a weapon, so each call is its own attack.
AddPrefabPostInit("wortox_soul_spawn", function(inst)
	if TheWorld.ismastersim then
		wrap_field(inst, "SoulSpearTick", HorrorChainUtil.RunBoundary)
	end
end)

AddPrefabPostInit("wortox_decoy", function(inst)
	if TheWorld.ismastersim then
		wrap_field(inst, "DoThorns", HorrorChainUtil.RunBoundary)
		wrap_field(inst, "DoExplosion", HorrorChainUtil.RunBoundary)
	end
end)

-------------------------------------------------------------------------
-- Stategraphs
-------------------------------------------------------------------------

-- Weremoose smash adds its planar bonus per target; mark the smash so spread
-- hits apply that rule to each member.
AddStategraphPostInit("wilson", function(sg)
	local state = sg.states.attack
	if state == nil or state.timeline == nil then
		return
	end
	-- Other attacks, including events added by other mods, keep their behavior.
	for _, event in ipairs(state.timeline) do
		local fn = event.fn
		event.fn = function(inst, ...)
			if inst.sg.statemem.ismoosesmash then
				return HorrorChainUtil.RunMooseSmash(inst, fn, ...)
			end
			return fn(inst, ...)
		end
	end
end)
