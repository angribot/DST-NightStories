local AtriumGateProgress = Class(function(self, inst)
	self.inst = inst
	self.repaired = false

	inst:DoTaskInTime(0, function()
		self:Sync()
	end)
end)

function AtriumGateProgress:SetRepaired()
	if self.repaired then
		return
	end

	self.repaired = true
	self.inst:PushEvent("ns_atriumgate_repaired")
	self:Sync()
end

function AtriumGateProgress:Sync(shardid)
	-- False requests progress from peers; true permanently unlocks it.
	SendModRPCToShard(GetShardModRPC("nightstories", "atriumgateprogress"), shardid, self.repaired)
end

function AtriumGateProgress:OnSave()
	return self.repaired and { repaired = true } or nil
end

function AtriumGateProgress:OnLoad(data)
	if data ~= nil and data.repaired then
		self:SetRepaired()
	end
end

return AtriumGateProgress
