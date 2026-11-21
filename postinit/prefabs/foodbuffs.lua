local AddPrefabPostInitAny = AddPrefabPostInitAny
GLOBAL.setfenv(1, GLOBAL)

-- do return end
local Timer = require("components/timer")

local on_save = Timer.OnSave
function Timer:OnSave(...)
	local data = on_save(self, ...)
	if data and data.timers then
		for k, v in pairs(data.timers) do
			if self.timers[k] then
				v.civi_buffed = self.timers[k].civi_buffed
			end
		end
	end
	return data
end

local on_load = Timer.OnLoad
function Timer:OnLoad(data, ...)
	on_load(self, data, ...)
	if data and data.timers then
		for k, v in pairs(data.timers) do
			if self.timers[k] then
				self.timers[k].civi_buffed = v.civi_buffed
			end
		end
	end
end

local function timer_fn(base_fn, buff_timer)
	return function(inst, target, ...)
		FunctionOrValue(base_fn, inst, target, ...)

		local duration = inst.components.timer:GetTimeLeft(buff_timer)

		if target and target.prefab == "civi" and not inst.components.timer.timers[buff_timer].civi_buffed then
			inst.components.timer:StopTimer(buff_timer)
			inst.components.timer:StartTimer(buff_timer, duration * target.buff_duration_mult)
			if inst.components.timer.timers[buff_timer] then
				inst.components.timer.timers[buff_timer].civi_buffed = true
			end
		end
	end
end

local known_buff_timers = { "buffover", "regenover" }

AddPrefabPostInitAny(function(inst)
	if TUNING.CIVI_EXCLUDE_DEBUFFS[inst.prefab] then
		return
	end
	if not TheWorld.ismastersim then
		return
	end

	local debuff = inst.components.debuff
	if debuff and inst.components.timer then
		for _, buff_timer in ipairs(known_buff_timers) do
			if inst.components.timer.timers[buff_timer] then
				local onattachedfn = debuff.onattachedfn
				if onattachedfn then
					debuff:SetAttachedFn(timer_fn(onattachedfn, buff_timer))
				end
				local onextendedfn = debuff.onextendedfn
				if onextendedfn then
					debuff:SetExtendedFn(timer_fn(onextendedfn, buff_timer))
				end
			end
		end
	end
end)
