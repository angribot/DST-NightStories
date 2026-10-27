GLOBAL.setfenv(1, GLOBAL)

-- King Cane gem changes recreate the callback, so wrap each orange gem setup.
local stafffns = require("prefabs/staff_common").fns
local orange = stafffns.orange
stafffns.orange = function(inst, ...)
	orange(inst, ...)
	if inst.prefab ~= "king_cane" and inst.prefab ~= "orangestaff" then
		return
	end

	local blinkstaff = inst.components.blinkstaff
	local onblink = blinkstaff.onblinkfn
	blinkstaff.onblinkfn = function(staff, pos, caster)
		if caster and caster:HasTag("mio_boosted_task") then
			if staff.prefab == "king_cane" then
				-- DST 760178: the vanilla callback uses caster only for sanity costs.
				caster = nil
			else
				local inventory = caster.components.inventory
				if inventory and inventory:Has("nightmarefuel", 1) then
					inventory:ConsumeByName("nightmarefuel", 1)
					return
				end
			end
		end
		return onblink(staff, pos, caster)
	end
end
