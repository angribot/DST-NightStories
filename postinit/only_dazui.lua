local UpvalueUtil = GlassicAPI.UpvalueUtil
local AddComponentPostInit = AddComponentPostInit
local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local DUMMY_TAG = "ns_builder_dummy"
local SPAWNER_RADIUS = 120
local STATUE_RADIUS = 30

AddComponentPostInit("shadowcreaturespawner", function(self)
	local spawn_land = UpvalueUtil.GetUpvalue(self.SpawnShadowCreature, "SpawnLandShadowCreature")
	assert(spawn_land, "Could not find SpawnLandShadowCreature")
	UpvalueUtil.SetUpvalue(self.SpawnShadowCreature, "SpawnLandShadowCreature", function(player, ...)
		if player:HasTag(DUMMY_TAG) then
			return SpawnPrefab("terrorbeak")
		end
		return spawn_land(player, ...)
	end)
end)

local function has_nearby_dummy(inst, radius)
	for _, player in ipairs(AllPlayers) do
		if player:HasTag(DUMMY_TAG) and inst:GetDistanceSqToInst(player) < radius * radius then
			return true
		end
	end
	return false
end

AddComponentPostInit("childspawner", function(self)
	local get_child_prefab = self.GetChildPrefab
	function self:GetChildPrefab(...)
		-- Choose before the rare-child roll, without changing the spawning lifecycle.
		if self.childname == "crawlingnightmare" and has_nearby_dummy(self.inst, SPAWNER_RADIUS) then
			return "ruinsnightmare"
		end
		return get_child_prefab(self, ...)
	end
end)

local function on_work_finished(inst, worker)
	inst.components.lootdropper:DropLoot(inst:GetPosition())

	local fx = SpawnAt("collapse_small", inst)
	fx:SetMaterial("rock")

	-- Keep the upstream spawn chance and worker luck; only upgrade the species.
	if TheWorld.state.isnightmarewild and TryLuckRoll(worker, TUNING.STATUERUINS_SPAWN_NIGHTMARE_CHANCE, LuckFormulas.StatueSpawnNightmare) then
		SpawnAt("ruinsnightmare", inst)
	end

	inst:Remove()
end

local STATUERUINS = {
	"ruins_statue_head",
	"ruins_statue_head_nogem",
	"ruins_statue_mage",
	"ruins_statue_mage_nogem",
}
local function statueruins_postinit(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst.components.workable then
		local on_finish = inst.components.workable.onfinish
		inst.components.workable:SetOnFinishCallback(function(inst, worker, ...)
			if has_nearby_dummy(inst, STATUE_RADIUS) then
				return on_work_finished(inst, worker)
			end
			return on_finish(inst, worker, ...)
		end)
	end
end
for _, prefab in ipairs(STATUERUINS) do
	AddPrefabPostInit(prefab, statueruins_postinit)
end
