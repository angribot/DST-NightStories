local AddPrefabPostInit = AddPrefabPostInit
local AddShardModRPCHandler = AddShardModRPCHandler
GLOBAL.setfenv(1, GLOBAL)

local function SyncAtriumGateProgress(inst, shardid)
	-- False requests progress from peers; true permanently unlocks it.
	SendModRPCToShard(GetShardModRPC("nightstories", "atriumgateprogress"), shardid, inst._atriumgate_repaired)
end

local function UnlockSoulSplitRecipe(inst, player)
	if inst._atriumgate_repaired and player:HasTag("ns_builder_dummy") and player.components.builder ~= nil then
		player.components.builder:AddRecipe("dummy_soulsplit_2")
		player:PushEvent("unlockrecipe")
	end
end

local function SetAtriumGateRepaired(inst)
	if inst._atriumgate_repaired then
		return
	end

	inst._atriumgate_repaired = true
	for _, player in ipairs(AllPlayers) do
		UnlockSoulSplitRecipe(inst, player)
	end
	SyncAtriumGateProgress(inst)
end

AddShardModRPCHandler("nightstories", "atriumgateprogress", function(shardid, repaired)
	if TheWorld ~= nil and TheWorld.SetAtriumGateRepaired ~= nil then
		if repaired == true then
			TheWorld:SetAtriumGateRepaired()
		elseif TheWorld._atriumgate_repaired then
			SyncAtriumGateProgress(TheWorld, shardid)
		end
	end
end)

-- Celestial Scion progress is per save but shared by every shard, because only the forest tracks the boss.
local function SyncCelestialScionProgress(inst, shardid)
	-- False requests progress from peers; true permanently unlocks it.
	SendModRPCToShard(GetShardModRPC("nightstories", "celestialscionprogress"), shardid, inst._celestialscion_defeated)
end

local function SetCelestialScionDefeated(inst)
	if inst._celestialscion_defeated then
		return
	end

	inst._celestialscion_defeated = true
	if inst.net ~= nil and inst.net._celestialscion_defeated ~= nil then
		inst.net._celestialscion_defeated:set(true)
	end
	SyncCelestialScionProgress(inst)
end

local function IsCelestialScionDefeated(inst)
	if inst.ismastersim then
		return inst._celestialscion_defeated == true
	end
	local defeated = inst.net ~= nil and inst.net._celestialscion_defeated or nil
	return defeated ~= nil and defeated:value()
end

AddShardModRPCHandler("nightstories", "celestialscionprogress", function(shardid, defeated)
	if TheWorld ~= nil and TheWorld.SetCelestialScionDefeated ~= nil then
		if defeated == true then
			TheWorld:SetCelestialScionDefeated()
		elseif TheWorld._celestialscion_defeated then
			SyncCelestialScionProgress(TheWorld, shardid)
		end
	end
end)

local on_shard_connected = Shard_OnShardConnected
function Shard_OnShardConnected(shardid, ...)
	on_shard_connected(shardid, ...)
	if TheWorld ~= nil and TheWorld.SetAtriumGateRepaired ~= nil then
		SyncAtriumGateProgress(TheWorld, shardid)
	end
	if TheWorld ~= nil and TheWorld.SetCelestialScionDefeated ~= nil then
		SyncCelestialScionProgress(TheWorld, shardid)
	end
end

AddPrefabPostInit("world", function(inst)
	if not inst.ismastersim then
		return
	end

	inst._atriumgate_repaired = false
	inst.SetAtriumGateRepaired = SetAtriumGateRepaired

	local onsave = inst.OnSave
	inst.OnSave = function(inst, data, ...)
		data.atriumgate_repaired = inst._atriumgate_repaired or nil
		if onsave ~= nil then
			return onsave(inst, data, ...)
		end
	end

	local onload = inst.OnLoad
	inst.OnLoad = function(inst, data, ...)
		if data ~= nil and data.atriumgate_repaired then
			inst:SetAtriumGateRepaired()
		end
		if onload ~= nil then
			return onload(inst, data, ...)
		end
	end

	inst:ListenForEvent("ms_playerjoined", UnlockSoulSplitRecipe)
	inst:DoTaskInTime(0, SyncAtriumGateProgress)
end)

AddPrefabPostInit("world", function(inst)
	inst.IsCelestialScionDefeated = IsCelestialScionDefeated

	if not inst.ismastersim then
		return
	end

	inst._celestialscion_defeated = false
	inst.SetCelestialScionDefeated = SetCelestialScionDefeated

	local onsave = inst.OnSave
	inst.OnSave = function(inst, data, ...)
		data.celestialscion_defeated = inst._celestialscion_defeated or nil
		if onsave ~= nil then
			return onsave(inst, data, ...)
		end
	end

	-- Entities spawn after this, so saved skins can validate against the loaded progress.
	local onload = inst.OnLoad
	inst.OnLoad = function(inst, data, ...)
		-- Components load first, so the forest's tracker already holds its saved state.
		local wagboss_tracker = inst.components.wagboss_tracker
		if (data ~= nil and data.celestialscion_defeated) or (wagboss_tracker ~= nil and wagboss_tracker:IsWagbossDefeated()) then
			inst:SetCelestialScionDefeated()
		end
		if onload ~= nil then
			return onload(inst, data, ...)
		end
	end

	inst:ListenForEvent("wagboss_defeated", SetCelestialScionDefeated)
	inst:DoTaskInTime(0, SyncCelestialScionProgress)
end)

-- Clients read the progress from the world network entity.
local function AddCelestialScionNetvar(inst)
	inst._celestialscion_defeated = net_bool(inst.GUID, "world_network.celestialscion_defeated")
	if TheWorld.ismastersim then
		inst._celestialscion_defeated:set(TheWorld._celestialscion_defeated == true)
	end
end

AddPrefabPostInit("forest_network", AddCelestialScionNetvar)
AddPrefabPostInit("cave_network", AddCelestialScionNetvar)
