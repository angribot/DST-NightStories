local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

local SkillTreeData = require("skilltreedata")
local deactivate_skill = SkillTreeData.DeactivateSkill
function SkillTreeData:DeactivateSkill(...)
	-- Only bypass validation in the live data layer, including client RPC updates.
	-- In DST 760178, the updater also uses skip_validation as the callback's
	-- fromload argument. Restore it before running any gameplay callbacks.
	if not self.owner then
		return deactivate_skill(self, ...)
	end
	local previous = self.skip_validation
	self.skip_validation = true
	local ok, updated = pcall(deactivate_skill, self, ...)
	self.skip_validation = previous
	if not ok then
		error(updated, 0)
	end
	return updated
end

local SKILLTREE_DEFS = require("prefabs/skilltree_defs").SKILLTREE_DEFS
AddPlayerPostInit(function(inst)
	if SKILLTREE_DEFS[inst.prefab] then
		inst:AddTag("skilltree_characters")
	end
	if inst.prefab == "wathgrithr" then
		-- DST 760178 only refreshes riding music on mounting or activation.
		inst:ListenForEvent("ondeactivateskill_client", function(player)
			if not player.components.skilltreeupdater:HasSkillTag("beefalo") and player._play_riding_music_task then
				player._play_riding_music_task:Cancel()
				player._play_riding_music_task = nil
			end
		end)
	end
end)
