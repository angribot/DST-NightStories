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

return {
	GetState = GetState,
	CanCorrupt = CanCorrupt,
}
