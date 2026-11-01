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
-- Chains are not saved: saved component data would break loading the world
-- once this mod is disabled, and a chain lasts only seconds.
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

-- Only lengthens the chain; a shorter duration never cuts it.
function HorrorChain:SetMinDuration(duration)
	if self.task == nil or GetTaskRemaining(self.task) < duration then
		if self.task ~= nil then
			self.task:Cancel()
		end
		self.task = self.inst:DoTaskInTime(duration, expire)
	end
end

return HorrorChain
