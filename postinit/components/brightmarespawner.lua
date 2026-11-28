local AddComponentPostInit = AddComponentPostInit
local devassert = devassert
local UpvalueUtil = GlassicAPI.UpvalueUtil
GLOBAL.setfenv(1, GLOBAL)

local AMBIENT_GESTALT_SUPPRESSION_SEEDS = 100

AddComponentPostInit("brightmarespawner", function(self)
	local spawn_path = "OnSanityModeChanged.Start.UpdatePopulation.TrySpawnGestaltForPlayer"
	local events = self.inst.event_listeners
	local listeners = events and events.ms_playerjoined and events.ms_playerjoined[self.inst]
	for _, listener in ipairs(listeners or {}) do
		local spawn_gestalt = UpvalueUtil.GetUpvalue(listener, spawn_path)
		if spawn_gestalt then
			UpvalueUtil.SetUpvalue(listener, spawn_path, function(player, ...)
				local inventory = player.components.inventory
				local hat = inventory and inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
				-- Too Strong Fixed main/modules/enhanced_alterguardianhat.lua:OnEntityReplicated (d55d013): lets the crown's slots hold stacks of seeds
				-- Vanilla prefabs/hats.lua:alterguardianhat_updatelight (762172): sets lunarseedsmaxed by occupied slots, not seed count
				if hat and hat.prefab == "alterguardianhat" and hat.components.container and hat.components.container:Has("lunar_seed", AMBIENT_GESTALT_SUPPRESSION_SEEDS) then
					return
				end
				return spawn_gestalt(player, ...)
			end)
			return
		end
	end
	devassert(false, "Could not find TrySpawnGestaltForPlayer")
end)
