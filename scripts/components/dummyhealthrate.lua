local Feedback = require("dummyhealthfeedback")

local UPDATE_PERIOD = 0.25
local SAMPLE_WINDOW = 1

local function FinishPeriodicCapture(self, previous, capture, ok, ...)
	self.capture = previous
	if not ok then
		error((...), 0)
	end
	self.rates[capture.source] = {
		rate = capture.amount / capture.period,
		expires = GetTime() + math.max(0.5, capture.period * 1.5),
	}
	return ...
end

local function CapturePeriodic(self, source, period, fn, ...)
	local previous = self.capture
	local capture = { kind = "periodic", source = source, period = period, amount = 0 }
	self.capture = capture
	-- Periodic callbacks are synchronous. Restore observation state on errors
	-- without changing the callback's arguments, results, or damage handling.
	return FinishPeriodicCapture(self, previous, capture, pcall(fn, ...))
end

local function FinishFireCapture(self, previous, ok, ...)
	self.capture = previous
	if not ok then
		error((...), 0)
	end
	return ...
end

local function OnForceHealthPulse(inst, data)
	if data.up or data.down then
		Feedback.Push(inst, data.up == true, false)
	end
end

local function OnHealthDelta(inst, data)
	local self = inst.components.dummyhealthrate
	if data.amount == 0 or inst:HasTag("playerghost") then
		return
	end
	local health = inst.components.health
	local lunarburn = data.afflicter ~= nil and health.lunarburns ~= nil and health.lunarburns[data.afflicter] ~= nil
	-- Rate capture describes scheduling, not feedback intent. Preserve the
	-- source's overtime contract except for natural sanity drift.
	local sanitydrift = data.cause == "lose_sanity" and data.overtime
	if not sanitydrift then
		if data.newpercent > data.oldpercent then
			Feedback.Push(inst, true, data.overtime == true)
		elseif data.newpercent < data.oldpercent and not data.overtime then
			Feedback.Push(inst, false, false)
		end
	end
	if health:IsDead() then
		return
	end
	if self.capture ~= nil and self.capture.kind == "periodic" then
		self.capture.amount = self.capture.amount + data.amount
	elseif (self.capture ~= nil and self.capture.kind == "fire") or (data.overtime and data.cause ~= "lose_sanity") or lunarburn then
		-- Fire and externally scheduled effects use a one-second window of
		-- post-modifier amounts before health clamping, not realized gains.
		self.samples[#self.samples + 1] = { time = GetTime(), amount = data.amount }
	end
end

local DummyHealthRate = Class(function(self, inst)
	self.inst = inst
	self.rates = {}
	self.samples = {}
	self.tasks = {}
	self.methods = {}
	self.elapsed = 0

	self:ObserveMethod(inst.components.sanity, "Recalc")
	self:ObserveMethod(inst.components.hunger, "OnUpdate")
	self:ObserveMethod(inst.components.temperature, "OnUpdate")

	local health = inst.components.health
	local do_fire_damage = health.DoFireDamage
	local wrapper = function(component, amount, doer, instant, ...)
		if instant then
			return do_fire_damage(component, amount, doer, instant, ...)
		end
		local previous = self.capture
		self.capture = { kind = "fire" }
		return FinishFireCapture(self, previous, pcall(do_fire_damage, component, amount, doer, instant, ...))
	end
	health.DoFireDamage = wrapper
	self.methods[#self.methods + 1] = { object = health, name = "DoFireDamage", original = do_fire_damage, wrapper = wrapper }

	inst:ListenForEvent("healthdelta", OnHealthDelta)
	inst:ListenForEvent("forcehealthpulse", OnForceHealthPulse)
	self:ObserveTasks()
	inst:StartUpdatingComponent(self)
end)

function DummyHealthRate:ObserveMethod(object, name)
	local original = object[name]
	local source = {}
	local wrapper = function(component, dt, ...)
		if dt <= 0 then
			return original(component, dt, ...)
		end
		return CapturePeriodic(self, source, dt, original, component, dt, ...)
	end
	object[name] = wrapper
	self.methods[#self.methods + 1] = { object = object, name = name, original = original, wrapper = wrapper }
end

function DummyHealthRate:ObserveTask(task)
	if task == nil or task.fn == nil or task.period == nil or task.period <= 0 or task.limit == 1 or self.tasks[task] ~= nil then
		return
	end
	local original = task.fn
	local source = { task = task }
	local wrapper = function(...)
		return CapturePeriodic(self, source, task.period, original, ...)
	end
	self.tasks[task] = { original = original, wrapper = wrapper }
	task.fn = wrapper
end

function DummyHealthRate:ObserveTasks()
	local inst = self.inst
	local health = inst.components.health
	self:ObserveTask(health.regen ~= nil and health.regen.task or nil)
	for _, source in pairs(health.regensources or {}) do
		for _, data in pairs(source.tasks) do
			self:ObserveTask(data.task)
		end
	end
	self:ObserveTask(inst.acidlevel_acid_task)

	for _, debuff in pairs(inst.components.debuffable.debuffs) do
		self:ObserveTask(debuff.inst.task)
	end
	for _, item in pairs(inst.components.inventory.equipslots) do
		if item.prefab == "amulet" or item:HasTag("regen") then
			self:ObserveTask(item.task)
		end
	end
end

function DummyHealthRate:OnUpdate(dt)
	self.elapsed = self.elapsed + dt
	if self.elapsed < UPDATE_PERIOD then
		return
	end
	self.elapsed = 0
	self:ObserveTasks()

	local inst = self.inst
	local time = GetTime()
	local rate = 0
	local inactive = inst:HasTag("playerghost") or inst.components.health:IsDead()
	for source, sample in pairs(self.rates) do
		if inactive or time > sample.expires or (source.task ~= nil and source.task.fn == nil) then
			self.rates[source] = nil
		else
			rate = rate + sample.rate
		end
	end
	local samples = {}
	for _, sample in ipairs(self.samples) do
		if not inactive and sample.time > time - SAMPLE_WINDOW then
			samples[#samples + 1] = sample
			rate = rate + sample.amount / SAMPLE_WINDOW
		end
	end
	self.samples = samples
	for task in pairs(self.tasks) do
		if task.fn == nil then
			self.tasks[task] = nil
		end
	end
	inst._resource_rate:set(rate)
end

function DummyHealthRate:OnRemoveFromEntity()
	self.inst:StopUpdatingComponent(self)
	self.inst:RemoveEventCallback("healthdelta", OnHealthDelta)
	self.inst:RemoveEventCallback("forcehealthpulse", OnForceHealthPulse)
	for _, method in ipairs(self.methods) do
		if method.object[method.name] == method.wrapper then
			method.object[method.name] = method.original
		end
	end
	for task, method in pairs(self.tasks) do
		if task.fn == method.wrapper then
			task.fn = method.original
		end
	end
	self.inst._resource_rate:set(0)
end

DummyHealthRate.OnRemoveEntity = DummyHealthRate.OnRemoveFromEntity

return DummyHealthRate
