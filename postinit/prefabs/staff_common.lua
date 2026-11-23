GLOBAL.setfenv(1, GLOBAL)

-- Vanilla prefabs/king_cane.lua:SetGem (762172): calls fns.orange again on every gem change
local stafffns = require("prefabs/staff_common").fns
local orange = stafffns.orange
stafffns.orange = function(inst, ...)
	orange(inst, ...)

	local blinkstaff = inst.components.blinkstaff
	local onblink = blinkstaff.onblinkfn
	-- Vanilla mainfunctions.lua:SpawnPrefabFromSim (762172): sets inst.prefab only after the constructor returns
	blinkstaff.onblinkfn = function(staff, pos, caster)
		-- Vanilla prefabs/staff_common.lua:onblink (762172): uses caster only for the sanity cost
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
