local CHAIN_TAG = "horrorchain"
local Utils = require("ns_utils")

local HorrorChainManager = Class(function(self, inst)
	self.inst = inst
	-- [member: EntityScript]: Periodic
	self.members = {}
	-- [member: EntityScript]: Periodic
	self.fx_tasks = {}

	self._remove_member = function(target)
		self:RemoveMember(target)
	end
end)

local function spawn_fx(target)
	local SCALE = 1.1
	local fx = SpawnPrefab("shadow_teleport_out")
	fx.Transform:SetScale(SCALE, SCALE, SCALE)
	target:AddChild(fx)
end

local function setup_fx(self, target)
	if not self.fx_tasks[target] then
		self.fx_tasks[target] = target:DoPeriodicTask(20 * FRAMES, spawn_fx, 0)
	end
end

local function remove_fx(self, target)
	if self.fx_tasks[target] then
		self.fx_tasks[target]:Cancel()
		self.fx_tasks[target] = nil
	end
end

local function cancel_existing_timer(self, target)
	self.members[target]:Cancel()
end

function HorrorChainManager:AddMember(target, duration, force_override_timer)
	-- Refresh timer only on existing member
	if not Utils.TargetTestFn(target) then
		return
	end
	if self:HasMember(target) then
		if force_override_timer or self:GetMemberTimeRemaining(target) < duration then
			cancel_existing_timer(self, target)
			self.members[target] = target:DoTaskInTime(duration, self._remove_member)
		end
	else
		target:AddTag(CHAIN_TAG)
		setup_fx(self, target)
		self.members[target] = target:DoTaskInTime(duration, self._remove_member)
		target:ListenForEvent("death", self._remove_member)
		target:ListenForEvent("remove", self._remove_member)
	end
end

function HorrorChainManager:RemoveMember(target)
	if not self:HasMember(target) then
		return
	end

	cancel_existing_timer(self, target)
	target:RemoveTag(CHAIN_TAG)
	remove_fx(self, target)
	self.members[target] = nil
	target:RemoveEventCallback("death", self._remove_member)
	target:RemoveEventCallback("remove", self._remove_member)
end

function HorrorChainManager:HasMember(target)
	return self.members[target]
end

function HorrorChainManager:GetMemberTimeRemaining(target)
	return GetTaskRemaining(self.members[target])
end

function HorrorChainManager:OnSave()
	local members = {}
	local references = {}
	for member, task in pairs(self.members) do
		members[member.GUID] = GetTaskRemaining(task)
		table.insert(references, member.GUID)
	end
	return { members = members }, references
end

function HorrorChainManager:LoadPostPass(newents, save_data)
	if save_data and save_data.members then
		for member, remaining_time in pairs(save_data.members) do
			if newents[member] then
				self:AddMember(newents[member].entity, remaining_time)
			end
		end
	end
end

function HorrorChainManager:GetNearbyMembers(member)
	if self:HasMember(member) then
		local x, y, z = member.Transform:GetWorldPosition()
		return TheSim:FindEntities(x, y, z, TUNING.HORRORCHAIN_DIST, { CHAIN_TAG })
	end
	return {}
end

return HorrorChainManager
