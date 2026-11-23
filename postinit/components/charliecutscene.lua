local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("charliecutscene", function(self)
	if not TheWorld.ismastersim then
		return
	end

	local function update_progress()
		if self:IsGateRepaired() then
			TheWorld:SetAtriumGateRepaired()
		end
	end

	local repair_gate = self.RepairGate
	self.RepairGate = function(self, ...)
		repair_gate(self, ...)
		update_progress()
	end

	-- Vanilla components/charliecutscene.lua:CharlieCutscene:OnLoad (762172): restores a repaired gate without RepairGate, also from a save taken mid-cutscene
	local onload = self.OnLoad
	self.OnLoad = function(self, ...)
		onload(self, ...)
		update_progress()
	end
end)
