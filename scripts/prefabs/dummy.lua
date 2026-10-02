local MakePlayerCharacter = require("prefabs/player_common")
local DummyBadge = require("widgets/dummybadge")
local Utils = require("ns_utils")
local BUILDER_TAG = "ns_builder_dummy"

local assets = {
	Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
	Asset("SOUND", "sound/dummy.fsb"),

	Asset("ANIM", "anim/dummy.zip"),
	Asset("ANIM", "anim/ghost_dummy_build.zip"),
}

local prefabs = {
	"nightmarefuel",
}

local start_inv = {}

for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.DUMMY
end
prefabs = FlattenTree({ prefabs, start_inv }, true)

local SHADOWCREATURE_MUST_TAGS = { "shadowcreature", "_combat", "locomotor" }
local SHADOWCREATURE_CANT_TAGS = { "INLIMBO", "notaunt" }
local function OnReadFn(inst, book)
	if inst.components.sanity:IsInsane() then
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 16, SHADOWCREATURE_MUST_TAGS, SHADOWCREATURE_CANT_TAGS)

		if #ents < TUNING.BOOK_MAX_SHADOWCREATURES then
			TheWorld.components.shadowcreaturespawner:SpawnShadowCreature(inst)
		end
	end
end

local function calc_sanity_aura(inst, observer)
	if observer.prefab == "dummy" then
		return 0
	elseif observer.prefab ~= "dummy" and observer:HasTag("nightstorychar") then
		return inst.components.sanityaura.aura
	else
		return -inst.components.sanityaura.aura
	end
end

local function get_equippable_dapperness(owner, equippable)
	local dapperness = equippable:GetDapperness(owner, owner.components.sanity.no_moisture_penalty)
	if equippable.inst:HasTag("shadow_item") then
		return 0
	end
	return dapperness
end

local function check_insanity(inst)
	local sanity = inst.components.sanity
	if not sanity then
		return
	end

	local percent_ignoresinduced = sanity.current / sanity.max
	if sanity.mode == SANITY_MODE_INSANITY then
		if sanity.sane and percent_ignoresinduced <= TUNING.SANITY_BECOME_INSANE_THRESH then --30
			sanity.sane = false
		elseif not sanity.sane and percent_ignoresinduced >= TUNING.SANITY_BECOME_SANE_THRESH then --35
			sanity.sane = true
		end
	else
		if sanity.sane and percent_ignoresinduced >= TUNING.SANITY_BECOME_ENLIGHTENED_THRESH then
			sanity.sane = false
		elseif not sanity.sane and percent_ignoresinduced <= TUNING.SANITY_LOSE_ENLIGHTENMENT_THRESH then
			sanity.sane = true
		end
	end

	if sanity:IsSane() ~= sanity._oldissane then
		sanity._oldissane = sanity:IsSane()
		if sanity._oldissane then
			if sanity.onSane ~= nil then
				sanity.onSane(sanity.inst)
			end
			sanity.inst:PushEvent("gosane")
			ProfileStatsSet("went_sane", true)
		else
			if sanity.mode == SANITY_MODE_INSANITY then
				if sanity.onInsane ~= nil then
					sanity.onInsane(sanity.inst)
				end
				sanity.inst:PushEvent("goinsane")
				ProfileStatsSet("went_insane", true)
			else --sanity.mode == SANITY_MODE_LUNACY
				if sanity.onEnlightened ~= nil then
					sanity.onEnlightened(sanity.inst)
				end
				sanity.inst:PushEvent("goenlightened")
				ProfileStatsSet("went_enlightened", true)
			end
		end
	end
end

local function do_hunger_rate_change(inst)
	if inst:HasTag("playerghost") or inst.components.health:IsDead() then
		return
	end

	local percent = math.max(0, (inst.components.sanity.current - (inst.components.sanity.max * 0.15)) / (inst.components.sanity.max * 0.85))

	if inst.components.sanity and not inst.components.sanity.inducedinsanity and inst.components.sanity.sane then
		inst.components.hunger:SetRate((1 + percent) * TUNING.WILSON_HUNGER_RATE)
		inst:AddTag("playermonster")
		inst:AddTag("monster")
		if not inst.components.sanityaura then
			inst:AddComponent("sanityaura")
			inst.components.sanityaura.aurafn = calc_sanity_aura
			inst.components.sanityaura.aura = (TUNING.DUMMY_SANITY_AURA * (1 + percent) / 2)
		end
	else
		inst.components.hunger:SetRate(TUNING.WILSON_HUNGER_RATE)
		if inst:HasTag("playermonster") then
			inst:RemoveTag("playermonster")
		end
		if inst:HasTag("monster") then
			inst:RemoveTag("monster")
		end
		if inst.components.sanityaura then
			inst:RemoveComponent("sanityaura")
		end
	end
end

local function on_health_sanity_change(inst, data)
	if inst.components.sanity and inst.components.health then
		local sanity = inst.components.sanity
		sanity.current = inst.components.health.currenthealth
		sanity.inst:PushEvent("sanitydelta", {
			oldpercent = sanity._oldpercent,
			newpercent = sanity:GetPercent(),
			overtime = true,
			sanitymode = sanity.mode,
		})
		sanity._oldpercent = sanity:GetPercent()
	end
	do_hunger_rate_change(inst)
	check_insanity(inst)

	if data and data.cause == "fire" then
		local amount = data.amount and math.abs(data.amount) or 0
		Utils.TableInsertRate(inst.firedamage_history, amount)
	end
	inst._firedamage_rate:set(Utils.GetRateFromTable(inst.firedamage_history))
end

local function redirect_to_health(inst, amount, overtime, ...)
	return inst.components.health
		and (amount and amount < 0 or inst.components.health.currenthealth > 0)
		and inst.components.health:DoDelta(amount, overtime, "lose_sanity", true, nil, true)
end

local function on_haunt(inst, doer)
	return doer.prefab == "dummy" and inst.components.sanity and inst.components.sanity.current >= 5
end

local function on_respawn_from_ghost(inst, data)
	if data and data.source then
		local target = (data.source.prefab == "reviver" and data.user) or (data.source.prefab == "pocketwatch_revive" and data.source.components.inventoryitem.owner) or data.source
		local reviver_sanity = target and target.components.sanity
		if reviver_sanity then
			local current = reviver_sanity.current
			inst.components.health:SetCurrentHealth(current <= 5 and 5 or current)
			on_health_sanity_change(inst)
			reviver_sanity:DoDelta(-current)
		end
	end
end

local function on_death(inst, data)
	if inst.death_task == nil then
		inst.death_task = inst:DoTaskInTime(2, function(inst)
			SpawnPrefab("nightmarefuel").Transform:SetPosition(inst:GetPosition():Get())
			inst.death_task:Cancel()
			inst.death_task = nil
		end)
	end
end

local function on_debuff_removed(inst, name, ...)
	if inst:HasTag("hasbuff_" .. name) then
		inst:RemoveTag("hasbuff_" .. name)
	end
end

local function on_debuff_added(inst, name, ...)
	if not inst:HasTag("hasbuff_" .. name) then
		inst:AddTag("hasbuff_" .. name)
	end
end

local common_postinit = function(inst)
	inst:AddTag(BUILDER_TAG)
	inst:AddTag("insomniac")
	inst:AddTag("reader")
	inst:AddTag("nightstorychar")
	inst:AddTag("nightmare_twins")
	-- Minimap icon
	inst.MiniMapEntity:SetIcon("dummy.tex")

	inst._firedamage_rate = net_byte(inst.GUID, "_firedamage_rate", "_firedamage_rate")

	if not (TheNet:GetServerGameMode() == "lavaarena" or TheNet:GetServerGameMode() == "quagmire" or TheNet:IsDedicated()) then
		inst.CreateHealthBadge = DummyBadge
	end
end

-- This initializes for the host only
local master_postinit = function(inst)
	inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

	inst.talker_path_override = "nightstories/characters/"

	inst.customidleanim = "idle_wortox"

	inst.firedamage_history = {}

	inst:AddComponent("reader")
	inst.components.reader:SetOnReadFn(OnReadFn)

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetOnHauntFn(on_haunt)
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)

	inst.components.health:SetMaxHealth(TUNING.DUMMY_HEALTH)
	inst.components.hunger:SetMax(TUNING.DUMMY_HUNGER)
	inst.components.sanity:SetMax(TUNING.DUMMY_HEALTH)

	inst.components.sanity.dapperness = TUNING.DAPPERNESS_MED
	inst.components.sanity.night_drain_mult = TUNING.DUMMY_NIGHT_SANITY_MULT
	inst.components.sanity.neg_aura_modifiers:SetModifier(inst, TUNING.DUMMY_SANITY_MULT, "dummy")
	inst.components.sanity.redirect = redirect_to_health
	inst.components.sanity.get_equippable_dappernessfn = get_equippable_dapperness

	inst.components.health.disable_penalty = true

	inst.components.combat.damagemultiplier = TUNING.DUMMY_DAMAGE_MULT

	if inst.components.eater then
		inst.components.eater:SetAbsorptionModifiers(0.5, 1, 0) -- Health, Hunger, Sanity
	end
	inst.components.foodaffinity:AddPrefabAffinity("nightmarepie", TUNING.AFFINITY_15_CALORIES_MED)

	if inst.components.debuffable then
		inst.components.debuffable.ondebuffremoved = on_debuff_removed
		inst.components.debuffable.ondebuffadded = on_debuff_added
	end

	inst:ListenForEvent("respawnfromghost", on_respawn_from_ghost)
	inst:ListenForEvent("healthdelta", on_health_sanity_change)

	inst.skeleton_prefab = nil
	inst:ListenForEvent("death", on_death)

	-- Hack Builder:RemoveIngredients so Dummy won't do anim when crafting costs Sanity-Health.
	if inst.components.builder then
		local remove_ingredients = inst.components.builder.RemoveIngredients
		inst.components.builder.RemoveIngredients = function(self, ingredients, recname, ...)
			local builder_tag = AllRecipes[recname] and AllRecipes[recname].builder_tag
			if builder_tag == BUILDER_TAG then
				local push_event = self.inst.PushEvent
				self.inst.PushEvent = function(inst, event, ...)
					if event ~= "consumehealthcost" then
						return push_event(inst, event, ...)
					end
				end
				local ret = remove_ingredients(self, ingredients, recname, ...)
				self.inst.PushEvent = push_event
				return ret
			else
				return remove_ingredients(self, ingredients, recname, ...)
			end
		end
	end
end

return MakePlayerCharacter("dummy", prefabs, assets, common_postinit, master_postinit)
