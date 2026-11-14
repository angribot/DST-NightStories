GLOBAL.setfenv(1, GLOBAL)

-- King Cane gem changes recreate the callback, so wrap each orange gem setup.
local stafffns = require("prefabs/staff_common").fns
local orange = stafffns.orange
stafffns.orange = function(inst, ...)
	orange(inst, ...)

	local blinkstaff = inst.components.blinkstaff
	local onblink = blinkstaff.onblinkfn
	-- Prefab names are assigned after construction, so check them when blinking.
	blinkstaff.onblinkfn = function(staff, pos, caster)
		-- DST 760178: the vanilla callback uses caster only for sanity costs, so clearing it skips them.
		if caster ~= nil then
			if caster.CanShadowpoof ~= nil and caster:CanShadowpoof(staff) then
				if caster:PayShadowpoof(staff) then
					return
				end
				caster = nil
			elseif staff.prefab == "king_cane" and caster:HasTag("mio_boosted_task") then
				caster = nil
			end
		end
		return onblink(staff, pos, caster)
	end
end
