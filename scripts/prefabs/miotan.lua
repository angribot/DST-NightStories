local MakePlayerCharacter = require("prefabs/player_common")

local assets = {
	Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
	Asset("SOUND", "sound/miotan.fsb"),

	Asset("ANIM", "anim/miotan.zip"),
	Asset("ANIM", "anim/ghost_miotan_build.zip"),
}

local prefabs = {
	"horrorfuel",
	"nightmarefuel",
	"pandorachest_reset",
	"statue_transition",
}

local start_inv = {}

for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.MIOTAN
end
prefabs = FlattenTree({ prefabs, start_inv }, true)

local SHADOWCREATURE_MUST_TAGS = { "shadowcreature", "_combat", "locomotor" }
local SHADOWCREATURE_CANT_TAGS = { "INLIMBO", "notaunt" }
local function on_read_fn(inst, book)
	if inst.components.sanity:IsInsane() then
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 16, SHADOWCREATURE_MUST_TAGS, SHADOWCREATURE_CANT_TAGS)

		if #ents < TUNING.BOOK_MAX_SHADOWCREATURES then
			TheWorld.components.shadowcreaturespawner:SpawnShadowCreature(inst)
		end
	end
end

local FUELMULT = {
	nightmarefuel = 1,
	horrorfuel = 2,
}

local function set_moisture(table)
	for _, v in pairs(table) do
		if (v.components.equippable and v.components.equippable:IsEquipped()) and (v.components.inventoryitem and v.components.inventoryitem:IsWet()) then
			v.components.inventoryitemmoisture:SetMoisture(0)
		end
	end
end

local function dry_equipment(inst)
	local inv = inst.components.inventory
	if not inv then
		return
	end

	local eslots = inv.equipslots
	if eslots then
		set_moisture(eslots)
	end

	local boat = inst.components.sailor and inst.components.sailor:GetBoat()
	if boat then
		local boatinv = boat.components.container and boat.components.container.boatequipslots
		local boatslots = boat.components.container and boat.components.container.slots
		if boatinv then
			set_moisture(boatinv)
		end
		if boatslots then
			set_moisture(boatslots)
		end
	end
end

local function check_has_fuel(inv, inv_boat, item, num)
	return (inv and inv:Has(item, num)) or (inv_boat and inv_boat:Has(item, num))
end

local function check_fuel(inst, data)
	local num = data.count or 1
	local inv = inst.components.inventory
	local inv_boat = inst.components.sailor and inst.components.sailor:GetBoat() and inst.components.sailor:GetBoat().components.container
	local override_fuel = data.override_fuel
	if override_fuel then
		if check_has_fuel(inv, inv_boat, override_fuel, num) then
			return override_fuel, 1
		end
		return
	elseif not data.only_horror and check_has_fuel(inv, inv_boat, "nightmarefuel", num) then
		return "nightmarefuel", FUELMULT["nightmarefuel"]
	elseif check_has_fuel(inv, inv_boat, "horrorfuel", num) then
		return "horrorfuel", FUELMULT["horrorfuel"]
	end
end

local function consume_item(inst, item, mult)
	local num = mult or 1
	if item == nil then
		return
	end
	local inv = inst.components.inventory
	local inv_boat = inst.components.sailor and inst.components.sailor:GetBoat() and inst.components.sailor:GetBoat().components.container
	if check_has_fuel(inv, nil, item, num) then
		inv:ConsumeByName(item, num)
	elseif check_has_fuel(nil, inv_boat, item, num) then
		inv_boat:ConsumeByName(item, num)
	end
end

local function auto_refuel(inst)
	local is_fx_true = false

	local player_eslots = inst.components.inventory and inst.components.inventory.equipslots
	local boat = inst.components.sailor and inst.components.sailor:GetBoat() -- Compatible for Island Adventures
	local boatequipslots = boat and boat.components.container and boat.components.container.boatequipslots

	local fueled_table = TUNING.MIOTAN_AUTO_REFUEL_TABLE.FUELED
	local finiteuses_table = TUNING.MIOTAN_AUTO_REFUEL_TABLE.FINITEUSES

	for source, eslots in pairs({ player = player_eslots, boat = boatequipslots }) do
		for _, target in pairs(eslots) do
			if fueled_table[source] and fueled_table[source][target.prefab] then
				local data = fueled_table[source][target.prefab]
				local bonus = data.bonus or 1
				local fueled = target.components.fueled
				local fuel, fuelmult = check_fuel(inst, data)
				if fuel and fuelmult then
					if fueled and fueled:GetPercent() + TUNING.LARGE_FUEL / fueled.maxfuel * fuelmult * data.trigger * fueled.bonusmult <= 1 then
						is_fx_true = true
						fueled:DoDelta(TUNING.LARGE_FUEL * bonus * fueled.bonusmult * fuelmult)
						consume_item(inst, fuel, data.cost)
						if fueled.ontakefuelfn then
							fueled.ontakefuelfn(target)
						end
					end
				end
			elseif finiteuses_table[source] and finiteuses_table[source][target.prefab] then
				local data = finiteuses_table[source][target.prefab]
				local bonus = data.bonus or 1
				local finiteuses = target.components.finiteuses
				local fuel, fuelmult = check_fuel(inst, data)
				if fuel and fuelmult then
					if finiteuses and finiteuses:GetUses() + data.trigger * fuelmult <= finiteuses.total then
						is_fx_true = true
						finiteuses:Use(-bonus * fuelmult)
						consume_item(inst, fuel, data.cost)
					end
				end
			end
		end
	end

	if is_fx_true then
		SpawnPrefab("pandorachest_reset").entity:SetParent(inst.entity)
	end
end

local function on_boost(inst)
	inst.components.locomotor.runspeed = TUNING.MIOTAN_RUN_SPEED
	inst.components.temperature.mintemp = TUNING.MIOTAN_BOOST_MINTEMP
	if inst.components.eater then
		inst.components.eater:SetAbsorptionModifiers(TUNING.MIOTAN_BOOST_ABSORPTION, TUNING.MIOTAN_BOOST_ABSORPTION, TUNING.MIOTAN_BOOST_ABSORPTION)
	end
end

local function end_boost(inst)
	inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED
	inst.components.temperature.mintemp = -20
	if inst.components.eater then
		inst.components.eater:SetAbsorptionModifiers(1, 1, 1)
	end
end

local function set_sanity_dapperness(inst)
	local daydrain = TheWorld.state.isday and not TheWorld:HasTag("cave")
	local sanity = inst.components.sanity
	if sanity.mode == 1 and not daydrain then -- LUNACY BUT NOT IN DAYTIME
		sanity.dapperness = 0
	else
		sanity.dapperness = TUNING.MIOTAN_SANITY_DAPPERNESS
	end
end

local function on_update(inst, dt)
	inst.boost_time = inst.boost_time - dt
	if inst.boost_time <= 0 then
		inst.boost_time = 0
		if inst.boosted_task then
			inst.boosted_task:Cancel()
			inst.boosted_task = nil
		end
		end_boost(inst)
		if inst._dry_task then
			inst._dry_task:Cancel()
			inst._dry_task = nil
		end
		if inst:HasTag("mio_boosted_task") then
			inst:RemoveTag("mio_boosted_task")
		end
	else
		--boosteffect(inst)
		auto_refuel(inst)
		if inst._dry_task == nil then
			inst._dry_task = inst:DoPeriodicTask(0, function(inst)
				dry_equipment(inst)
			end)
		end
		if not inst:HasTag("mio_boosted_task") then
			inst:AddTag("mio_boosted_task")
		end
	end
end

local function on_long_update(inst, dt)
	inst.boost_time = math.max(0, inst.boost_time - dt)
end

local function start_boost(inst, duration)
	inst.boost_time = duration
	if inst.boosted_task == nil then
		inst.boosted_task = inst:DoPeriodicTask(1, on_update, nil, 1)
		inst:DoTaskInTime(0, function(inst)
			on_update(inst, 0)
		end) -- Prevent autorefuel function consumes nightmarefuels before actually "eated"
		on_boost(inst)
	end
end

local function on_load(inst, data)
	if data and data.boost_time then
		start_boost(inst, data.boost_time)
	end
	set_sanity_dapperness(inst)
end

local function on_save(inst, data)
	data.boost_time = inst.boost_time > 0 and inst.boost_time or nil
end

local function on_becameghost(inst)
	if inst.boosted_task then
		inst.boost_time = 0
		on_update(inst, 0)
	end
end

local function on_death(inst)
	local deathprefab = inst.boost_time > 0 and "horrorfuel" or "nightmarefuel"
	if inst.death_task == nil then
		inst.death_task = inst:DoTaskInTime(2, function(inst)
			SpawnPrefab(deathprefab).Transform:SetPosition(inst:GetPosition():Get())
			inst.death_task:Cancel()
			inst.death_task = nil
		end)
	end
end

local function on_haunt(inst, doer)
	return doer.prefab == "dummy" and inst.components.sanity and inst.components.sanity.current >= 5
end

local common_postinit = function(inst)
	inst:AddTag("reader")
	inst:AddTag("nightstorychar")
	inst:AddTag("nightmare_twins")
	inst:AddTag("nightfueleater")
	-- Minimap icon
	inst.MiniMapEntity:SetIcon("miotan.tex")
end

-- This initializes for the host only
local master_postinit = function(inst)
	inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

	inst.talker_path_override = "nightstories/characters/"

	inst.boost_time = 0
	inst.boosted_task = nil

	inst:AddComponent("reader")
	inst.components.reader:SetOnReadFn(on_read_fn)

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetOnHauntFn(on_haunt)
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)

	inst.components.health:SetMaxHealth(TUNING.MIOTAN_STATUS)
	inst.components.hunger:SetMax(TUNING.MIOTAN_STATUS)
	inst.components.sanity:SetMax(TUNING.MIOTAN_STATUS)

	inst.components.sanity.dapperness = TUNING.MIOTAN_SANITY_DAPPERNESS
	inst.components.sanity.night_drain_mult = TUNING.MIOTAN_SANITY_NIGHT_MULT
	inst.components.sanity.neg_aura_modifiers:SetModifier(inst, TUNING.MIOTAN_SANITY_MULT, "miotan")

	inst:ListenForEvent("sanitydelta", set_sanity_dapperness)
	inst:ListenForEvent("isinsanitymodedirty", set_sanity_dapperness)

	if inst.components.eater then
		inst.components.eater.stale_hunger = TUNING.MIOTAN_STALE_HUNGER_RATE
		inst.components.eater.stale_health = TUNING.MIOTAN_STALE_HEALTH_RATE
		inst.components.eater.spoiled_hunger = TUNING.MIOTAN_SPOILED_HUNGER_RATE
		inst.components.eater.spoiled_health = TUNING.MIOTAN_SPOILED_HEALTH_RATE
	end

	inst:ListenForEvent("ms_becameghost", on_becameghost)
	inst.OnLongUpdate = on_long_update
	inst.OnSave = on_save
	inst.OnLoad = on_load

	inst.skeleton_prefab = nil
	inst:ListenForEvent("death", on_death)

	inst.StartBoost = start_boost
end

return MakePlayerCharacter("miotan", prefabs, assets, common_postinit, master_postinit)
