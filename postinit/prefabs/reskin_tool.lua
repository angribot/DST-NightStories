local AddPrefabPostInit = AddPrefabPostInit
local AddComponentAction = AddComponentAction
GLOBAL.setfenv(1, GLOBAL)

local Bluefish = require("nightstories/bluefish")

AddPrefabPostInit("reskin_tool", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	local spellcaster = inst.components.spellcaster
	local cancast = spellcaster.can_cast_fn
	spellcaster:SetCanCastFn(function(doer, target, ...)
		if Bluefish.IsSupported(target) then
			return Bluefish.CanSweep(doer, target) and cancast(doer, target, ...)
		end
		return cancast(doer, target, ...)
	end)
	local spell = spellcaster.spell
	spellcaster:SetSpellFn(function(tool, target, pos, doer)
		if not Bluefish.IsSupported(target) then
			return spell(tool, target, pos, doer)
		end
		if not Bluefish.CanSweep(doer, target) then
			return
		end

		-- Keep vanilla skin selection, caching and FX, but guard the task it
		-- queues: the employer or tool owner can change before it executes.
		local previous_task = rawget(tool, "DoTaskInTime")
		local dotask = tool.DoTaskInTime
		tool.DoTaskInTime = function(self, delay, fn, ...)
			return dotask(self, delay, function(inst, ...)
				if tool:IsValid() and tool.parent == doer and doer:IsValid() and Bluefish.CanSweep(doer, target) then
					return fn(inst, ...)
				end
			end, ...)
		end
		local ok, result = pcall(spell, tool, target, pos, doer)
		tool.DoTaskInTime = previous_task
		if not ok then
			error(result)
		end
		return result
	end)
end)

local function filter_action(inst, doer, target, actions)
	if inst.prefab == "reskin_tool" and Bluefish.IsSupported(target) and not Bluefish.CanSweep(doer, target) then
		for i = #actions, 1, -1 do
			if actions[i] == ACTIONS.CASTSPELL then
				table.remove(actions, i)
			end
		end
	end
end
AddComponentAction("USEITEM", "spellcaster", filter_action)
AddComponentAction("EQUIPPED", "spellcaster", filter_action)
