local AddComponentAction = AddComponentAction
GLOBAL.setfenv(1, GLOBAL)

local GEM_STATES = {
	redgem = "red",
	bluegem = "blue",
	purplegem = "purple",
	yellowgem = "yellow",
	orangegem = "orange",
	greengem = "green",
}

local function GetState(staff)
	return staff and staff.prefab == "king_cane" and staff._gem and GEM_STATES[staff._gem:value()] or nil
end

local function CanCorrupt(staff, target)
	local state = GetState(staff)
	return state ~= nil
		and staff:HasTag("corrupted")
		and not staff:HasTag("nomagiccast")
		and target ~= nil
		and target:IsValid()
		and target.prefab == "nightpack"
		and not target:IsInLimbo()
		and target.entity:IsVisible()
		and not target:HasTag("nomagic")
		and target.replica.inventoryitem ~= nil
		and not target.replica.inventoryitem:IsHeld()
		and not (target:HasTag("nightpack_blighted") and target:GetState() == state)
end

-- Do not give packs nightmarecorruptable: the vanilla collector cannot filter same-colour packs.
AddComponentAction("EQUIPPED", "corruption", function(inst, doer, target, actions, right)
	if right and CanCorrupt(inst, target) then
		table.insert(actions, ACTIONS.CORRUPTNIGHTMARE)
	end
end)

local Corruption = require("components/corruption")
local CorruptEnt = Corruption.CorruptEnt
function Corruption:CorruptEnt(target, doer, ...)
	if target ~= nil and target.prefab == "nightpack" then
		if not self:IsCorrupted() or not CanCorrupt(self.inst, target) then
			return false
		end
		if not target:CorruptWithGem(GetState(self.inst)) then
			return false
		end
		self.inst.components.rechargeable:Discharge(TUNING.KING_CANE_CORRUPT_CHESSPIECE_COOLDOWN)
		return true
	end
	return CorruptEnt(self, target, doer, ...)
end
