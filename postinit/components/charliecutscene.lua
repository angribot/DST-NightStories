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

	-- Existing saves and interrupted cutscenes can load an already repaired gate.
	local onload = self.OnLoad
	self.OnLoad = function(self, ...)
		onload(self, ...)
		update_progress()
	end
end)
