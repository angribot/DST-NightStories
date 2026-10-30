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

local on_shard_connected = Shard_OnShardConnected
function Shard_OnShardConnected(shardid, ...)
	on_shard_connected(shardid, ...)
	if TheWorld ~= nil and TheWorld.SetAtriumGateRepaired ~= nil then
		SyncAtriumGateProgress(TheWorld, shardid)
	end
end

AddPrefabPostInit("world", function(inst)
	if not inst.ismastersim then
		return
	end

	inst:AddComponent("horrorchainmanager")
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
