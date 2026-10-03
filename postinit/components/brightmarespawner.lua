local AddComponentPostInit = AddComponentPostInit
local UpvalueUtil = GlassicAPI.UpvalueUtil
GLOBAL.setfenv(1, GLOBAL)

local AMBIENT_GESTALT_SUPPRESSION_SEEDS = 100

AddComponentPostInit("brightmarespawner", function(self)
	-- The spawn loop is private; reach it through the component's world join listener.
	local spawn_path = "OnSanityModeChanged.Start.UpdatePopulation.TrySpawnGestaltForPlayer"
	local events = self.inst.event_listeners
	local listeners = events and events.ms_playerjoined and events.ms_playerjoined[self.inst]
	for _, listener in ipairs(listeners or {}) do
		local spawn_gestalt = UpvalueUtil.GetUpvalue(listener, spawn_path)
		if spawn_gestalt then
			UpvalueUtil.SetUpvalue(listener, spawn_path, function(player, ...)
				local inventory = player.components.inventory
				local hat = inventory and inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
				-- DST-Fixed allows five stacks of twenty jewels; lunarseedsmaxed only counts occupied slots.
				if hat and hat.prefab == "alterguardianhat" and hat.components.container and hat.components.container:Has("lunar_seed", AMBIENT_GESTALT_SUPPRESSION_SEEDS) then
					return
				end
				-- Leave existing gestalts, other players, and attack/planting summons unchanged.
				return spawn_gestalt(player, ...)
			end)
			return
		end
	end
	assert(false, "Could not find TrySpawnGestaltForPlayer")
end)
