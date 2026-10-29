local AddPrefabPostInit = AddPrefabPostInit
local AddShardModRPCHandler = AddShardModRPCHandler
GLOBAL.setfenv(1, GLOBAL)

AddShardModRPCHandler("nightstories", "atriumgateprogress", function(shardid, repaired)
	local progress = TheWorld ~= nil and TheWorld.components.ns_atriumgateprogress or nil
	if progress ~= nil then
		if repaired == true then
			progress:SetRepaired()
		elseif progress.repaired then
			progress:Sync(shardid)
		end
	end
end)

local on_shard_connected = Shard_OnShardConnected
function Shard_OnShardConnected(shardid, ...)
	on_shard_connected(shardid, ...)
	local progress = TheWorld ~= nil and TheWorld.components.ns_atriumgateprogress or nil
	if progress ~= nil then
		progress:Sync(shardid)
	end
end

AddPrefabPostInit("world", function(inst)
	if inst.ismastersim then
		inst:AddComponent("horrorchainmanager")
		inst:AddComponent("ns_atriumgateprogress")
	end
end)
