local AddComponentAction = AddComponentAction
GLOBAL.setfenv(1, GLOBAL)

local nightpackcorruption = require("nightpackcorruption")

-- Do not give packs nightmarecorruptable: the vanilla collector cannot filter same-colour packs.
AddComponentAction("EQUIPPED", "corruption", function(inst, doer, target, actions, right)
	if right and nightpackcorruption.CanCorrupt(inst, target) then
		table.insert(actions, ACTIONS.CORRUPTNIGHTMARE)
	end
end)

local Corruption = require("components/corruption")
local CorruptEnt = Corruption.CorruptEnt
function Corruption:CorruptEnt(target, doer, ...)
	if target ~= nil and target.prefab == "nightpack" then
		if not self:IsCorrupted() or not nightpackcorruption.CanCorrupt(self.inst, target) then
			return false
		end
		if not target:CorruptWithGem(nightpackcorruption.GetState(self.inst)) then
			return false
		end
		self.inst.components.rechargeable:Discharge(TUNING.KING_CANE_CORRUPT_CHESSPIECE_COOLDOWN)
		return true
	end
	return CorruptEnt(self, target, doer, ...)
end
