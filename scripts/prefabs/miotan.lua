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

local function get_boat_container(inst)
	local boat = inst.components.sailor and inst.components.sailor:GetBoat() -- Island Adventures
	return boat and boat.components.container
end

local function get_stack_size(item)
	return item.components.stackable and item.components.stackable:StackSize() or 1
end

-- Counts a fuel in Mio's pockets, cursor, and backpack and in her boat's cargo. Island Adventures' Inventory:Has counts
-- the backpack twice, so count the places Inventory:ConsumeByName takes from directly.
local function count_fuel(inst, item)
	local inventory = inst.components.inventory
	local count = 0
	for _, v in pairs(inventory.itemslots) do
		if v.prefab == item then
			count = count + get_stack_size(v)
		end
	end
	local active_item = inventory:GetActiveItem()
	if active_item and active_item.prefab == item then
		count = count + get_stack_size(active_item)
	end
	for _, container in pairs({ inventory:GetOverflowContainer(), get_boat_container(inst) }) do
		local _, found = container:Has(item, 1)
		count = count + found
	end
	return count
end

-- Spends a fuel from the boat's cargo first, the order Island Adventures' Inventory:ConsumeByName already uses, then
-- from Mio's inventory. The cargo is taken directly because Island Adventures skips a boat container not yet opened.
local function consume_fuel(inst, item, amount)
	amount = amount or 1
	local boat_container = get_boat_container(inst)
	if boat_container then
		local _, found = boat_container:Has(item, 1)
		local from_boat = math.min(amount, found)
		boat_container:ConsumeByName(item, from_boat)
		amount = amount - from_boat
	end
	inst.components.inventory:ConsumeByName(item, amount)
end

-- Shadowpoof: a fuel-boosted Mio's own Lazy Explorer casts, which never cost sanity and spend fuel instead of uses.
local function can_shadowpoof(inst, staff)
	return staff ~= nil and staff.prefab == "orangestaff" and inst:HasTag("mio_boosted_task") and staff.replica.inventoryitem ~= nil and staff.replica.inventoryitem:IsHeldBy(inst)
end

-- Counts a fuel on either side: clients only have the replica, whose Has already adds an Island Adventures boat's cargo.
local function count_blink_fuel(inst, item)
	if inst.components.inventory ~= nil then
		return count_fuel(inst, item)
	end
	local inventory = inst.replica.inventory
	if inventory == nil then
		return 0
	end
	local _, found = inventory:Has(item, 1)
	return found
end

-- Uses the carried fuel can pay beyond the staff's own; map blink mods read this on clients and the server.
local function get_extra_blink_uses(inst, staff)
	if not can_shadowpoof(inst, staff) then
		return 0
	end
	-- Count only the fuels pay_shadowpoof spends, or map blinks could pass with uses it cannot pay.
	return count_blink_fuel(inst, "nightmarefuel") * FUELMULT.nightmarefuel + count_blink_fuel(inst, "horrorfuel") * FUELMULT.horrorfuel
end

-- Pays one Shadowpoof use with fuel; returns false when the staff's own use should pay instead.
local function pay_shadowpoof(inst, staff)
	if count_fuel(inst, "nightmarefuel") > 0 then
		consume_fuel(inst, "nightmarefuel", 1)
		return true
	end
	-- Pure Horror's spare uses repair the staff. A staff without room spends its own use now and takes the spare later.
	local spare = FUELMULT.horrorfuel - 1
	local finiteuses = staff.components.finiteuses
	if count_fuel(inst, "horrorfuel") > 0 and finiteuses:GetUses() + spare <= finiteuses.total then
		consume_fuel(inst, "horrorfuel", 1)
		finiteuses:Use(-spare)
		return true
	end
	return false
end

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

	local boat_container = get_boat_container(inst)
	if boat_container then
		if boat_container.boatequipslots then
			set_moisture(boat_container.boatequipslots)
		end
		set_moisture(boat_container.slots)
	end
end

local function check_fuel(inst, data)
	local num = data.cost or 1
	local override_fuel = data.override_fuel
	if override_fuel then
		if count_fuel(inst, override_fuel) >= num then
			return override_fuel, 1
		end
		return
	elseif count_fuel(inst, "nightmarefuel") >= num then
		return "nightmarefuel", FUELMULT["nightmarefuel"]
	elseif count_fuel(inst, "horrorfuel") >= num then
		return "horrorfuel", FUELMULT["horrorfuel"]
	end
end

-- Cooldown seconds removed per Nightmare Fuel; Pure Horror removes FUELMULT.horrorfuel times as much.
local KING_CANE_FUEL_TIME = 10

local function recharge_king_cane(inst, staff)
	if not staff or staff.prefab ~= "king_cane" or not staff.components.corruption or not staff.components.corruption:IsCorrupted() then
		return false
	end

	local rechargeable = staff.components.rechargeable
	local remaining = rechargeable and rechargeable:GetTimeToCharge() or 0
	if remaining <= 0 then
		return false
	end

	-- Settle the whole cooldown at once, counted in Nightmare Fuel units: Pure Horror covers only what Nightmare Fuel cannot,
	-- so no Nightmare Fuel is spent where Pure Horror already covers it.
	local units_needed = math.ceil(remaining / KING_CANE_FUEL_TIME)
	local nightmare_owned = count_fuel(inst, "nightmarefuel")
	local horror_spent = math.max(0, math.min(count_fuel(inst, "horrorfuel"), math.ceil((units_needed - nightmare_owned) / FUELMULT.horrorfuel)))
	local nightmare_spent = math.max(0, math.min(nightmare_owned, units_needed - horror_spent * FUELMULT.horrorfuel))
	if horror_spent + nightmare_spent <= 0 then
		return false
	end

	consume_fuel(inst, "horrorfuel", horror_spent)
	consume_fuel(inst, "nightmarefuel", nightmare_spent)
	rechargeable:SetPercent(rechargeable:GetPercent() + (nightmare_spent + horror_spent * FUELMULT.horrorfuel) * KING_CANE_FUEL_TIME / rechargeable:GetRechargeTime())
	return true
end

local function auto_refuel(inst)
	local inventory = inst.components.inventory
	local staff = inventory and inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	local is_fx_true = recharge_king_cane(inst, staff)
	local active_item = inventory and inventory:GetActiveItem()
	if active_item ~= staff then
		is_fx_true = recharge_king_cane(inst, active_item) or is_fx_true
	end

	local player_eslots = inst.components.inventory and inst.components.inventory.equipslots
	local boat_container = get_boat_container(inst)
	local boatequipslots = boat_container and boat_container.boatequipslots

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
						consume_fuel(inst, fuel, data.cost)
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
						consume_fuel(inst, fuel, data.cost)
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

-- Equipment cannot lower Mio's sanity while she is fuel-boosted.
local function get_equippable_dapperness(owner, equippable)
	local dapperness = equippable:GetDapperness(owner, owner.components.sanity.no_moisture_penalty)
	if dapperness < 0 and owner:HasTag("mio_boosted_task") then
		return 0
	end
	return dapperness
end

local function has_queen_torch_equipped(inst)
	local inventory = inst.components.inventory
	local item = inventory and inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	return item ~= nil and item.prefab == "queen_torch"
end

local function on_update(inst, dt)
	if not has_queen_torch_equipped(inst) then
		inst.boost_time = inst.boost_time - dt
	end
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
	if not has_queen_torch_equipped(inst) then
		inst.boost_time = math.max(0, inst.boost_time - dt)
	end
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

local function refresh_queen_torch_boost(inst)
	if inst.boost_time <= 0 and not inst:HasTag("playerghost") and not inst.components.health:IsDead() and has_queen_torch_equipped(inst) then
		start_boost(inst, 3 * FRAMES)
	end
end

local function on_equip(inst, data)
	if data and data.eslot == EQUIPSLOTS.HANDS then
		refresh_queen_torch_boost(inst)
	end
end

local function on_load(inst, data)
	if data and data.boost_time then
		start_boost(inst, data.boost_time)
	end
	refresh_queen_torch_boost(inst)
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

	inst.CanShadowpoof = can_shadowpoof
	inst.GetExtraBlinkUses = get_extra_blink_uses
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
	inst.components.sanity.get_equippable_dappernessfn = get_equippable_dapperness

	inst:ListenForEvent("sanitydelta", set_sanity_dapperness)
	inst:ListenForEvent("isinsanitymodedirty", set_sanity_dapperness)

	if inst.components.eater then
		inst.components.eater.stale_hunger = TUNING.MIOTAN_STALE_HUNGER_RATE
		inst.components.eater.stale_health = TUNING.MIOTAN_STALE_HEALTH_RATE
		inst.components.eater.spoiled_hunger = TUNING.MIOTAN_SPOILED_HUNGER_RATE
		inst.components.eater.spoiled_health = TUNING.MIOTAN_SPOILED_HEALTH_RATE
	end

	inst:ListenForEvent("equip", on_equip)
	inst:ListenForEvent("ms_becameghost", on_becameghost)
	inst.OnLongUpdate = on_long_update
	inst.OnSave = on_save
	inst.OnLoad = on_load

	inst.skeleton_prefab = nil
	inst:ListenForEvent("death", on_death)

	inst.StartBoost = start_boost
	inst.PayShadowpoof = pay_shadowpoof
end

return MakePlayerCharacter("miotan", prefabs, assets, common_postinit, master_postinit)
