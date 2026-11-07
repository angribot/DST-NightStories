local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function push_event(inst)
	inst:PushEvent("dragonflychest_upgraded")
end

AddPrefabPostInit("dragonflychest", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	local upgradeable = inst.components.upgradeable
	local _OnUpgrade = upgradeable.onupgradefn

	local function OnUpgrade(inst, performer, upgraded_from_item)
		if not upgraded_from_item then
			_OnUpgrade(inst, performer, upgraded_from_item)
			push_event(inst)
			return
		end

		-- An item upgrade delays the official visuals with DoTaskInTime. Tasks due on
		-- the same tick run in no fixed order, so a separate task could run before
		-- the official one and have its visuals overwritten. Push the event from
		-- inside the official task instead.
		local instance_do_task_in_time = rawget(inst, "DoTaskInTime")
		local do_task_in_time = inst.DoTaskInTime
		inst.DoTaskInTime = function(self, time, fn, ...)
			return do_task_in_time(self, time, function(...)
				fn(...)
				push_event(inst)
			end, ...)
		end
		_OnUpgrade(inst, performer, upgraded_from_item)
		inst.DoTaskInTime = instance_do_task_in_time
	end
	upgradeable:SetOnUpgradeFn(OnUpgrade)

	local _OnLoad = inst.OnLoad
	inst.OnLoad = function(inst, data, newents)
		if inst.components.upgradeable ~= nil and inst.components.upgradeable.numupgrades > 0 then
			OnUpgrade(inst)
		end
	end
end)
