local CHAIN_TAG = "horrorchain"
local Utils = require("ns_utils")
local ChainDamage = require("ns_horrorchain_damage")

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

function HorrorChainManager:QueueAttack(combat, target, weapon, projectile, stimuli, instancemult)
	local entry = ChainDamage.Capture(combat, target, weapon, projectile, stimuli, instancemult)
	if entry == nil then
		return
	end
	if self.pending_damage == nil then
		self.pending_damage = {}
		self.pending_index = {}
		self.pending_task = self.inst:DoTaskInTime(FRAMES, function()
			self:FlushDamage()
		end)
	end

	local index = self.pending_index
	for _, key in ipairs({ GetTick(), entry.attacker, weapon or false, target, entry.stimuli or false }) do
		if index[key] == nil then
			index[key] = {}
		end
		index = index[key]
	end
	local previous = index[entry.ranged]
	if previous then
		previous.damage = previous.damage + entry.damage
		if entry.spdamage then
			previous.spdamage = previous.spdamage or {}
			for kind, amount in pairs(entry.spdamage) do
				previous.spdamage[kind] = (previous.spdamage[kind] or 0) + amount
			end
		end
	else
		index[entry.ranged] = entry
		self.pending_damage[#self.pending_damage + 1] = entry
	end
end

function HorrorChainManager:FlushDamage()
	local pending = self.pending_damage
	if self.pending_task then
		self.pending_task:Cancel()
	end
	self.pending_task = nil
	self.pending_damage = nil
	self.pending_index = nil
	-- Detach the batch before callbacks can enqueue new attacks.
	for _, entry in ipairs(pending or {}) do
		ChainDamage.Apply(entry)
	end
end

function HorrorChainManager:OnRemoveFromEntity()
	if self.pending_task then
		self.pending_task:Cancel()
	end
	self.pending_task = nil
	self.pending_damage = nil
	self.pending_index = nil
end

return HorrorChainManager
