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

-- Vanilla entityscript.lua:EntityScript:SetPersistData (762172): re-adds a saved add_component_if_missing component, which fails once this mod is disabled
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

function HorrorChain:SetMinDuration(duration)
	if self.task == nil or GetTaskRemaining(self.task) < duration then
		if self.task ~= nil then
			self.task:Cancel()
		end
		self.task = self.inst:DoTaskInTime(duration, expire)
	end
end

return HorrorChain
