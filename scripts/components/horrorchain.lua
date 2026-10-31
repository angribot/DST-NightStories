local CHAIN_TAG = "horrorchain"

local function spawn_fx(inst)
	local SCALE = 1.1
	local fx = SpawnPrefab("shadow_teleport_out")
	fx.Transform:SetScale(SCALE, SCALE, SCALE)
	inst:AddChild(fx)
end

local function expire(inst)
	inst:RemoveComponent("horrorchain")
end

-- Marks a chain member. Server only; removing the component ends the chain.
local HorrorChain = Class(function(self, inst)
	self.inst = inst
	self.task = nil
	self.fx_task = inst:DoPeriodicTask(20 * FRAMES, spawn_fx, 0)

	inst:AddTag(CHAIN_TAG)
	inst:ListenForEvent("death", expire)
end)

function HorrorChain:OnRemoveFromEntity()
	self.inst:RemoveTag(CHAIN_TAG)
	self.inst:RemoveEventCallback("death", expire)
	self.fx_task:Cancel()
	if self.task ~= nil then
		self.task:Cancel()
	end
end

function HorrorChain:SetDuration(duration)
	if self.task ~= nil then
		self.task:Cancel()
	end
	self.task = self.inst:DoTaskInTime(duration, expire)
end

-- Only lengthens the chain; a shorter duration never cuts it.
function HorrorChain:SetMinDuration(duration)
	if self.task == nil or GetTaskRemaining(self.task) < duration then
		self:SetDuration(duration)
	end
end

function HorrorChain:OnSave()
	local remaining = self.task ~= nil and GetTaskRemaining(self.task) or 0
	if remaining > 0 then
		return { remaining = remaining, add_component_if_missing = true }
	end
end

function HorrorChain:OnLoad(data)
	if data ~= nil and data.remaining ~= nil and data.remaining > 0 then
		self:SetDuration(data.remaining)
	else
		self.inst:RemoveComponent("horrorchain")
	end
end

return HorrorChain
