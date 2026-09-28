local MakePlayerCharacter = require("prefabs/player_common")
local BUILDER_TAG = "ns_builder_civi"

local assets = {
	Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
	Asset("SOUND", "sound/civi.fsb"),

	Asset("ANIM", "anim/civi.zip"),
	Asset("ANIM", "anim/ghost_civi_build.zip"),
}

local prefabs = {}
local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.CIVI
end
prefabs = FlattenTree({ prefabs, start_inv }, true)

-- local function SetupHorrorChainTag(inst, target, ...)
--	 TheWorld.components.horrorchainmanager:AddMember(target, 3, true)
-- end

local function update_food(inst)
	inst.components.foodaffinity:RemovePrefabAffinity("bonesoup")
	inst.components.foodaffinity:RemovePrefabAffinity("meatballs")
	inst.components.foodaffinity:RemovePrefabAffinity("voltgoatjelly")
	if inst.level == 0 then
		inst.components.foodaffinity:AddPrefabAffinity("bonesoup", 1.1)
	elseif inst.level == 1 then
		inst.components.foodaffinity:AddPrefabAffinity("meatballs", 1.24)
	elseif inst.level == 2 then
		inst.components.foodaffinity:AddPrefabAffinity("voltgoatjelly", 1.4)
	end
end

local function on_level_change(inst)
	inst.level = math.min(2, inst.level)
	inst.level = math.max(0, inst.level)

	update_food(inst)

	if inst:HasTag("civi_canupgrade") then
		inst:RemoveTag("civi_canupgrade")
	end
	if inst:HasTag("civi_candegrade") then
		inst:RemoveTag("civi_candegrade")
	end
	if inst.level < 2 then
		inst:AddTag("civi_canupgrade")
	end
	if inst.level > 0 then
		inst:AddTag("civi_candegrade")
	end

	local hunger_percent = inst.components.hunger:GetPercent()
	local health_percent = inst.components.health:GetPercent()
	local sanity_percent = inst.components.sanity:GetPercent()

	inst.components.hunger.max = (TUNING.CIVI_BASE_STATUS - inst.level * 50) -- max_level = 75
	inst.components.sanity.max = (TUNING.CIVI_BASE_STATUS - inst.level * 50) -- max_level = 75
	inst.components.health.maxhealth = (TUNING.CIVI_BASE_STATUS - inst.level * 50) -- max_level = 75

	inst.components.locomotor.runspeed = (TUNING.WILSON_RUN_SPEED * (1 + 0.25 * inst.level)) -- max_level = 9

	inst.components.combat.damagemultiplier = (1 + inst.level * 0.25) -- max_level = 1.5
	inst.components.sanity.night_drain_mult = (TUNING.CIVI_BASE_SANITY_MULT + inst.level * 0.25)
	inst.components.sanity.neg_aura_modifiers:SetModifier(inst, TUNING.CIVI_BASE_SANITY_MULT + inst.level * 0.25, "civi")

	if inst.components.eater ~= nil then
		inst.components.eater:SetAbsorptionModifiers((1 - 0.25 * inst.level), (1 - 0.25 * inst.level), (1 - 0.25 * inst.level))
	end
	inst.components.hunger:SetRate((1 - inst.level * 0.1) * TUNING.WILSON_HUNGER_RATE)
	inst.components.hunger:SetPercent(hunger_percent)
	inst.components.health:SetPercent(health_percent)
	inst.components.sanity:SetPercent(sanity_percent)

	-- if inst.level == 2 then
	--	 inst.components.combat.onhitotherfn = SetupHorrorChainTag
	-- else
	--	 inst.components.combat.onhitotherfn = nil
	-- end
end

local function on_preload(inst, data)
	if data and data.level then
		inst.level = data.level
		on_level_change(inst)
		--re-set these from the save data, because of load-order clipping issues
		-- if data.health and data.health.health then inst.components.health.currenthealth = data.health.health end
		-- if data.hunger and data.hunger.hunger then inst.components.hunger.current = data.hunger.hunger end
		-- if data.sanity and data.sanity.current then inst.components.sanity.current = data.sanity.current end
		inst.components.health:DoDelta(0)
		inst.components.hunger:DoDelta(0)
		inst.components.sanity:DoDelta(0)
	end
end

local function on_save(inst, data)
	data.level = inst.level
end

local function on_becameghost(inst)
	on_level_change(inst)
	inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED -- set to default speed when dead.
end

local function on_becamehuman(inst)
	on_level_change(inst)
end
-- This initializes for both clients and the host
local common_postinit = function(inst)
	inst:AddTag("nightstorychar")
	inst:AddTag(BUILDER_TAG)

	inst.MiniMapEntity:SetIcon("civi.tex")
end

-- This initializes for the host only
local master_postinit = function(inst)
	inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

	inst.talker_path_override = "nightstories/characters/"

	inst.level = 0

	-- inst.components.eater:SetOnEatFn(oneat)
	inst.components.builder.magic_bonus = 1

	on_level_change(inst)
	inst.applylevelfn = on_level_change

	inst.OnSave = on_save
	inst.OnPreLoad = on_preload
	inst:ListenForEvent("ms_becameghost", on_becameghost)
	inst:ListenForEvent("ms_respawnedfromghost", on_becamehuman)
end

return MakePlayerCharacter("civi", prefabs, assets, common_postinit, master_postinit)
