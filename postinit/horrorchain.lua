local AddPrefabPostInit = AddPrefabPostInit
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

local HorrorChainUtil = require("nightstories/horrorchainutil")

local function wrap_field(t, name, scope)
	local fn = t[name]
	t[name] = function(...)
		return scope(fn, ...)
	end
end

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

wrap_field(require("components/aura"), "OnTick", HorrorChainUtil.Suppress)

-- Vanilla prefabs/wortox_soul_spawn.lua:SoulSpearTick (762172): hits on Wortox's behalf without a weapon
AddPrefabPostInit("wortox_soul_spawn", function(inst)
	if TheWorld.ismastersim then
		wrap_field(inst, "SoulSpearTick", HorrorChainUtil.RunBoundary)
	end
end)

-- Vanilla prefabs/wortox.lua:DoThorns_decoy (762172): hits on Wortox's behalf without a weapon, also for DoExplosion_decoy
AddPrefabPostInit("wortox_decoy", function(inst)
	if TheWorld.ismastersim then
		wrap_field(inst, "DoThorns", HorrorChainUtil.RunBoundary)
		wrap_field(inst, "DoExplosion", HorrorChainUtil.RunBoundary)
	end
end)

AddStategraphPostInit("wilson", function(sg)
	local state = sg.states.attack
	if state == nil or state.timeline == nil then
		return
	end
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
