GLOBAL.setfenv(1, GLOBAL)

local DryingRackSaltCollector = require("components/dryingracksaltcollector")

function DryingRackSaltCollector:AddSalt(slot)
	if self.slots[slot] then
		return false
	end
	local item = self.inst.components.container:GetItemInSlot(slot)
	local count = item.components.stackable and item.components.stackable:StackSize() or 1
	self.slots[slot] = count
	self.numsalts = self.numsalts + count
	if self.onsaltchangedfn then
		self.onsaltchangedfn(self.inst, self.numsalts)
	end
	return true
end

function DryingRackSaltCollector:RemoveSalt(slot)
	local count = self.slots[slot]
	if not count then
		return false
	end
	self.slots[slot] = nil
	self.numsalts = self.numsalts - count
	if self.onsaltchangedfn then
		self.onsaltchangedfn(self.inst, self.numsalts)
	end
	return count
end

-- Vanilla components/dryingracksaltcollector.lua:DryingRackSaltCollector:OnLoad (762172): reads data.slots as one salt each when this mod is disabled
local OnSave = DryingRackSaltCollector.OnSave
function DryingRackSaltCollector:OnSave()
	local data = OnSave(self)
	if data then
		data.counts = {}
		for i, slot in ipairs(data.slots) do
			data.counts[i] = self.slots[slot]
		end
	end
	return data
end

function DryingRackSaltCollector:OnLoad(data)
	if data.slots and #data.slots > 0 then
		for i, slot in ipairs(data.slots) do
			-- Vanilla prefabs/meatrack2.lua:hermit_OnItemGet (762172): already adds salt for items the container loads before this component
			local count = data.counts and data.counts[i] or 1
			self.numsalts = self.numsalts - (self.slots[slot] or 0) + count
			self.slots[slot] = count
		end
		if self.onsaltchangedfn then
			self.onsaltchangedfn(self.inst, self.numsalts)
		end
	end
end
