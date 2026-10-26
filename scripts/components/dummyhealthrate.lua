local UPDATE_PERIOD = 0.25
local SAMPLE_WINDOW = 1

local function FinishCapture(self, previous, capture, ok, ...)
	self.capture = previous
	if ok and capture.period ~= nil then
		self.rates[capture.source] = {
			rate = capture.amount / capture.period,
			expires = GetTime() + math.max(0.5, capture.period * 1.5),
		}
	end
	if not ok then
		error((...), 0)
	end
	return ...
end

local function Capture(self, source, period, fn, ...)
	local previous = self.capture
	local capture = { source = source, period = period, amount = 0 }
	self.capture = capture
	-- Periodic callbacks are synchronous. Restore observation state on errors
	-- without changing the callback's arguments, results, or damage handling.
	return FinishCapture(self, previous, capture, pcall(fn, ...))
end

local function OnHealthDelta(inst, data)
	local self = inst.components.dummyhealthrate
	if data == nil or data.amount == nil or inst:HasTag("playerghost") or inst.components.health:IsDead() then
		return
	end
	if self.capture ~= nil and self.capture.period ~= nil then
		self.capture.amount = self.capture.amount + data.amount
	elseif
		self.capture ~= nil
		or (data.overtime and data.cause ~= "lose_sanity")
		or (data.afflicter ~= nil and inst.components.health.lunarburns ~= nil and inst.components.health.lunarburns[data.afflicter] ~= nil)
	then
		-- Fire and externally scheduled damage have no local periodic task to
		-- observe. Smooth their actual, post-modifier deltas over one second.
		if data.amount ~= 0 then
			self.samples[#self.samples + 1] = { time = GetTime(), amount = data.amount }
		end
	end
end

local function OnEffectStarted(inst, effect)
	if effect ~= nil then
		inst.components.dummyhealthrate.effects[effect] = true
	end
end

local DummyHealthRate = Class(function(self, inst)
	self.inst = inst
	self.rates = {}
	self.samples = {}
	self.effects = {}
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
		return Capture(self, nil, nil, do_fire_damage, component, amount, doer, instant, ...)
	end
	health.DoFireDamage = wrapper
	self.methods[#self.methods + 1] = { object = health, name = "DoFireDamage", original = do_fire_damage, wrapper = wrapper }

	inst:ListenForEvent("healthdelta", OnHealthDelta)
	inst:ListenForEvent("starthealthregen", OnEffectStarted)
	inst:ListenForEvent("startsmallhealthregen", OnEffectStarted)
	inst:ListenForEvent("startcorrosivedebuff", OnEffectStarted)
	self:ObserveTasks()
	inst:StartUpdatingComponent(self)
end)

function DummyHealthRate:ObserveMethod(object, name)
	if object == nil or object[name] == nil then
		return
	end
	local original = object[name]
	local source = {}
	local wrapper = function(component, dt, ...)
		if dt == nil or dt <= 0 then
			return original(component, dt, ...)
		end
		return Capture(self, source, dt, original, component, dt, ...)
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
		return Capture(self, source, task.period, original, ...)
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

	local debuffable = inst.components.debuffable
	for _, debuff in pairs(debuffable ~= nil and debuffable.debuffs or {}) do
		self:ObserveTask(debuff.inst.task)
	end
	for effect in pairs(self.effects) do
		if effect:IsValid() then
			self:ObserveTask(effect.task)
		else
			self.effects[effect] = nil
		end
	end
	local inventory = inst.components.inventory
	for _, item in pairs(inventory ~= nil and inventory.equipslots or {}) do
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
	self.inst:RemoveEventCallback("starthealthregen", OnEffectStarted)
	self.inst:RemoveEventCallback("startsmallhealthregen", OnEffectStarted)
	self.inst:RemoveEventCallback("startcorrosivedebuff", OnEffectStarted)
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
