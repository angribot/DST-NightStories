local AddAction = AddAction
local AddComponentAction = AddComponentAction
local AddStategraphState = AddStategraphState
local AddStategraphActionHandler = AddStategraphActionHandler
local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local UpvalueUtil = GlassicAPI.UpvalueUtil

NS_ACTIONS = {
	GEMTRADE = Action({ priority = 3, mount_valid = true }),
	LUNARSHADOWCHARGE = Action({ mount_valid = true }),
	LUNARSHADOWSTATE = Action({ priority = 1, mount_valie = true, rmb = true }),
	MIOFUEL = Action({ priority = 3, mount_valid = true }),
	MIOEATFUEL = Action({ priority = 4, mount_valid = true }),
	NIGHTSWITCH = Action({ priority = 1, mount_valid = true }),
	NIGHTSWORD = Action({ priority = 2, mount_valid = true }),
	FUELPOCKETWATCH = Action({ priority = 3, rmb = true }),
	MUTATETOTEM = Action({ priority = 3, rmb = true }),
	TOGGLETOTEM = Action({ mount_valid = true }),
}

NS_ACTIONS.GEMTRADE.str = STRINGS.ACTIONS.GIVE.SOCKET
NS_ACTIONS.NIGHTSWITCH.str = STRINGS.ACTIONS.USEITEM
NS_ACTIONS.NIGHTSWORD.str = STRINGS.ACTIONS.GIVE.SOCKET
NS_ACTIONS.MIOFUEL.str = STRINGS.ACTIONS.ADDFUEL
NS_ACTIONS.MIOEATFUEL.str = STRINGS.ACTIONS.EAT
NS_ACTIONS.MUTATETOTEM.str = STRINGS.ACTIONS.GIVE.SOCKET
NS_ACTIONS.TOGGLETOTEM.str = STRINGS.ACTIONS.TOGGLETOTEM
NS_ACTIONS.FUELPOCKETWATCH.str = STRINGS.ACTIONS.FUELPOCKETWATCH
NS_ACTIONS.LUNARSHADOWCHARGE.str = STRINGS.ACTIONS.LUNARSHADOWCHARGE
NS_ACTIONS.LUNARSHADOWSTATE.str = STRINGS.ACTIONS.LUNARSHADOWSTATE

-- NS_ACTIONS.MIOFUEL.stroverridefn = function(act)
-- 	if act.invobject then
-- 		return act.invobject:GetIsWet() and STRINGS.ACTIONS.ADDWETFUEL or STRINGS.ACTIONS.ADDFUEL
-- 	end
-- end

local blink_strfn = ACTIONS.BLINK.strfn
ACTIONS.BLINK.strfn = function(act)
	local blinkstaff = act.invobject == nil or act.invobject.prefab == "orangestaff"
	local doer = act.doer
	if blinkstaff and doer and doer:HasTag("mio_boosted_task") then
		if doer.replica.inventory:Has("nightmarefuel", 1) then
			return "FUEL"
		end
	end
	return blink_strfn(act)
end

local change_tackle_strfn = ACTIONS.CHANGE_TACKLE.strfn
ACTIONS.CHANGE_TACKLE.strfn = function(act)
	local item = (act.invobject and act.invobject:IsValid()) and act.invobject
	return change_tackle_strfn(act) or ((item and item:HasTag("reloaditem_lunarshadow")) and "BATTERY") or nil
end

NS_ACTIONS.TOGGLETOTEM.strfn = function(act)
	local totem = act.target or act.invobject
	if totem then
		return totem.toggled:value() and "OFF" or "ON"
	end
end

-- [[ Gem Trade ]] --

local GEM_MAP = {
	horrorfuel = "horror",
	nightmarefuel = "nightmare",
	redgem = "red",
	bluegem = "blue",
	purplegem = "purple",
	yellowgem = "yellow",
	orangegem = "orange",
	greengem = "green",
	opalpreciousgem = "opal",
}
NS_ACTIONS.GEMTRADE.fn = function(act)
	if act.target == nil or act.target:HasTag("nightpack_blighted") then
		return false
	end
	local doer = act.doer
	local target = act.target
	if doer.components.inventory then
		local item = doer.components.inventory:RemoveItem(act.invobject)
		if target.OnGemTrade then
			local gem_type = GEM_MAP[item.prefab]
			if gem_type then
				target:OnGemTrade(gem_type, doer.prefab == "dummy")
			end
		end
		item:Remove()
		return true
	end
end

-- [[ Civi: Tweak Levels ]] --

NS_ACTIONS.NIGHTSWITCH.fn = function(act)
	local doer = act.doer
	local level = doer.level
	if doer.components.inventory then
		local item = doer.components.inventory:RemoveItem(act.invobject)
		if item.prefab == "darkcrystal" then
			doer.level = level + 1
			if doer.level < 2 then
				doer.components.talker:Say(STRINGS.CIVI_LEVELS.FEEL_DARK, 3)
			else
				doer.components.talker:Say(STRINGS.CIVI_LEVELS.ALREADY_DARK, 3)
			end
		elseif item.prefab == "lightcrystal" then
			doer.level = level - 1
			if doer.level > 0 then
				doer.components.talker:Say(STRINGS.CIVI_LEVELS.FEEL_LIGHT, 3)
			else
				doer.components.talker:Say(STRINGS.CIVI_LEVELS.ALREADY_LIGHT, 3)
			end
		end

		doer.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
		if doer.applylevelfn ~= nil then
			doer.applylevelfn(doer)
		end
		item:Remove()
		return true
	end
end

scheduler:ExecuteInTime(0, function()
	if rawget(_G, "STRCODE_TALKER") then
		STRCODE_TALKER[STRINGS.CIVI_LEVELS.FEEL_DARK] = "CIVI_LEVELS.FEEL_DARK"
		STRCODE_TALKER[STRINGS.CIVI_LEVELS.ALREADY_DARK] = "CIVI_LEVELS.ALREADY_DARK"
		STRCODE_TALKER[STRINGS.CIVI_LEVELS.FEEL_LIGHT] = "CIVI_LEVELS.FEEL_LIGHT"
		STRCODE_TALKER[STRINGS.CIVI_LEVELS.ALREADY_LIGHT] = "CIVI_LEVELS.ALREADY_LIGHT"
	end
end)

-- [[ Mio: Add Fuel ]] --

local fuel_action_prefabs = {
	torch = true,
	lighter = true,
	pumpkin_lantern = true,
	ironwind = true, -- Volcano Biome MOD
	purpleamulet = true,
}

for i = 1, 8 do
	fuel_action_prefabs["winter_ornament_light" .. tostring(i)] = true
end

local book_fuel_uses = {
	book_harvest = { nightmarefuel = 1, horrorfuel = 2 },
	book_toggledownfall = { nightmarefuel = 1, horrorfuel = 2 },
	book_wetness = { horrorfuel = 1 },
}

local function use_fuel(item, target, doer)
	local book_uses = book_fuel_uses[target.prefab]
	if book_uses then
		local uses = book_uses[item.prefab]
		if uses and target.components.finiteuses then
			target.components.finiteuses:Repair(uses)
			doer.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
			return true
		end
		return false
	end

	local wetmult = item:GetIsWet() and TUNING.WET_FUEL_PENALTY or 1
	local fueled = target.components.fueled
	if fueled then
		fueled:DoDelta(item.components.fuel.fuelvalue * fueled.bonusmult * wetmult, doer)
		if fuel_action_prefabs[target.prefab] then
			doer.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
		end
		if fueled.ontakefuelfn then
			fueled.ontakefuelfn(target)
		end
		return true
	elseif target.components.perishable then
		target.components.perishable:SetPercent(target.components.perishable:GetPercent() + item.components.fuel.fuelvalue / TUNING.LANTERN_LIGHTTIME * wetmult)
		return true
	end
end

NS_ACTIONS.MIOFUEL.fn = function(act)
	if act.doer.components.inventory then
		local fuel = act.doer.components.inventory:RemoveItem(act.invobject)
		if fuel then
			if use_fuel(fuel, act.target, act.doer) then
				fuel:Remove()
				return true
			else
				act.doer.components.inventory:GiveItem(fuel)
			end
		end
	end
end

-- [[ Mio Eat Fuel ]] --
NS_ACTIONS.MIOEATFUEL.fn = function(act)
	local obj = act.target or act.invobject
	if obj ~= nil then
		if obj.components.nightfuel and act.doer:HasTag("nightfueleater") then
			return act.doer.components.eater:Eat(obj, act.doer)
		end
	end
end

-- [[ Dark Sword: Socket Gems ]] --

NS_ACTIONS.NIGHTSWORD.fn = function(act)
	local doer = act.doer
	local target = act.target
	if doer.components.inventory then
		local item = doer.components.inventory:RemoveItem(act.invobject)

		target:InitContainer()
		target.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")

		if doer.components.inventory:IsItemEquipped(target) then
			if target.components.container then
				target.components.container:Open(doer)
				target.add_container_event:push()
			end
		end

		target.components.container:GiveItem(item)

		return true
	end
end

-- [[ Totem: Mutate ]] --

local TOTEM_TARGET = {
	darkcrystal = "friendshiptotem_dark",
	lightcrystal = "friendshiptotem_light",
}
NS_ACTIONS.MUTATETOTEM.fn = function(act)
	local item = act.invobject
	local totem_prefab = TOTEM_TARGET[item.prefab]
	if totem_prefab then
		if item.components.stackable then
			item.components.stackable:Get():Remove()
		else
			item:Remove()
		end
		local totem = SpawnPrefab(totem_prefab)
		local target = act.target
		local container = target.components.inventoryitem and target.components.inventoryitem:GetContainer()
		local fx = SpawnPrefab("halloween_moonpuff")
		-- fx.AnimState:SetScale(0.6, 0.6, 0.6)
		local x, y, z = target.Transform:GetWorldPosition()
		target:Remove()
		if container then
			container:GiveItem(totem, nil, Vector3(x, y, z))
			fx.Transform:SetPosition(container.inst.Transform:GetWorldPosition())
		else
			totem.Transform:SetPosition(x, y, z)
			fx.Transform:SetPosition(x, y, z)
		end
		return true
	end
end

-- [[ Totem: Inventory Toggle ]] --
NS_ACTIONS.TOGGLETOTEM.fn = function(act, ...)
	local totem = act.target or act.invobject
	if totem then
		if totem.toggled:value() then
			totem:TurnOff()
		else
			totem:TurnOn()
		end
		return true
	end
end

-- [[ portable_wardrobe ]] --
local changein_fn = ACTIONS.CHANGEIN.fn
ACTIONS.CHANGEIN.fn = function(act, ...)
	if not act.target and act.invobject then
		act.target = act.invobject
	end
	return changein_fn(act, ...)
end

for _, k, v in sorted_pairs(NS_ACTIONS) do
	v.id = k
	AddAction(v)
end

-- [[ Hack Pocket Watch ]] --

local function fuel_pocket_watch(inst, caster)
	return inst.components.pocketwatch:CastSpell(caster)
end
NS_ACTIONS.FUELPOCKETWATCH.fn = function(act)
	local caster = act.doer
	local inventory = caster.components.inventory
	if act.invobject ~= nil and caster ~= nil and caster:HasTag("nightmare_twins") then
		if fuel_pocket_watch(act.invobject, act.doer) then
			if inventory:Has("horrorfuel", 1) then
				inventory:ConsumeByName("horrorfuel", 1)
			elseif inventory:Has("nightmarefuel", 1) then
				inventory:ConsumeByName("nightmarefuel", 1)
				caster.components.health:DoDelta(TUNING.HEALTH_FUELPOCKETWATCH_COST, nil, "fuelpocketwatch", true, nil, true)
			elseif caster.prefab == "dummy" then
				caster.components.health:DoDelta(TUNING.HEALTH_FUELPOCKETWATCH_COST_MORE, nil, "fuelpocketwatch", true, nil, true)
			else
				return
			end
			return true
		end
	end
end

-- [[ Lunar Shadow ]] --

NS_ACTIONS.LUNARSHADOWCHARGE.fn = function(act)
	local doer = act.doer
	local target = act.target
	local item = act.invobject
	local charges = 1
	local sound = "aqol/new_test/gem"
	if item.components.stackable then
		local stacks = item.components.stackable:StackSize()
		local single_charge = math.abs(TUNING.LUNARSHADOW.BATTERIES[item.prefab])
		if TUNING.LUNARSHADOW.BATTERIES[item.prefab] < 0 then
			sound = "dontstarve/common/nightmareAddFuel"
		end
		-- total is max uses
		local max_change_needed = target.components.finiteuses.total - target.components.finiteuses:GetUses()
		charges = math.clamp(math.ceil(max_change_needed / single_charge), 1, stacks)
		item.components.stackable:Get(charges):Remove()
	else
		act.invobject:Remove()
	end
	target:ChargeWithItem(item, charges)
	doer.SoundEmitter:PlaySound(sound)
	return true
end

NS_ACTIONS.LUNARSHADOWSTATE.fn = function(act)
	local current_state = act.invobject.state:value()
	act.invobject:SetLunarState(not current_state)
	act.doer.SoundEmitter:PlaySound("aqol/new_test/gem")
	return true
end
---------------------------------------------------------------------
----------------------- COMPONENT ACTIONS ---------------------------
---------------------------------------------------------------------

local MIO_FUEL_ACTION_TAGS = { "CAVE_fueled", "BURNABLE_fueled", "WORMLIGHT_fueled", "TAR_fueled" }
local function fuel_action_testfn(target, item)
	local book_uses = book_fuel_uses[target.prefab]
	if book_uses then
		return book_uses[item.prefab] ~= nil
	end
	return target:HasAnyTag(MIO_FUEL_ACTION_TAGS) or fuel_action_prefabs[target.prefab]
end

AddComponentAction("USEITEM", "fuel", function(inst, doer, target, actions, right)
	if doer.prefab == "miotan" and (inst.prefab == "nightmarefuel" or inst.prefab == "horrorfuel") then
		if
			fuel_action_testfn(target, inst)
			and (not (doer.replica.rider and doer.replica.rider:IsRiding()) or (target.replica.inventoryitem and target.replica.inventoryitem:IsGrandOwner(doer)))
		then
			table.insert(actions, NS_ACTIONS.MIOFUEL)
		end
	end
end)

AddComponentAction("INVENTORY", "nightfuel", function(inst, doer, actions, right)
	if
		doer.replica.inventory
		and not doer.components.playercontroller.isclientcontrollerattached
		and (right or doer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT))
	then
		local hand_item = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		if hand_item and hand_item.replica.container and hand_item.replica.container:IsOpenedBy(doer) and hand_item.replica.container:CanTakeItemInSlot(inst) then
			table.insert(actions, ACTIONS.CHANGE_TACKLE)
		end
	elseif doer:HasTag("nightfueleater") then
		table.insert(actions, NS_ACTIONS.MIOEATFUEL)
	end
end)

AddComponentAction("USEITEM", "nightfuel", function(inst, doer, target, actions)
	if doer == target and target:HasTag("nightfueleater") then
		table.insert(actions, NS_ACTIONS.MIOEATFUEL)
	end
end)

AddComponentAction("INVENTORY", "fuelpocketwatch", function(inst, doer, actions)
	if inst:HasTag("pocketwatch_inactive") and doer:HasTag("nightmare_twins") and inst:HasTag("pocketwatch_castfrominventory") then
		if doer.prefab == "dummy" or (doer.replica.inventory and doer.replica.inventory:HasItemWithTag("fuelpocketwatch_fuel", 1)) then
			table.insert(actions, NS_ACTIONS.FUELPOCKETWATCH)
		end
	end
end)

AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
	if
		right
		and target.prefab == "nightpack"
		and not target:HasTag("nightpack_blighted")
		and inst:HasTag("nightpackgem")
		and not doer.replica.rider:IsRiding()
		and not (target:HasTag("nofuelsocket") and (inst.prefab == "nightmarefuel" or inst.prefab == "horrorfuel"))
	then
		table.insert(actions, NS_ACTIONS.GEMTRADE)
	end
end)

AddComponentAction("USEITEM", "nightcrystal", function(inst, doer, target, actions, right)
	if right then
		if target.prefab == "nightsword" then
			if not target:HasTag("crystal_socketed") then
				table.insert(actions, NS_ACTIONS.NIGHTSWORD)
			end
		elseif target.prefab == "friendshipring" and not (target.replica.equippable and target.replica.equippable:IsEquipped()) then
			table.insert(actions, NS_ACTIONS.MUTATETOTEM)
		end
	end
	-- 这里写新的那部分
end)

local change_tackle_strfn = ACTIONS.CHANGE_TACKLE.strfn
ACTIONS.CHANGE_TACKLE.strfn = function(act)
	local item = (act.invobject and act.invobject:IsValid()) and act.invobject
	return change_tackle_strfn(act) or ((item and item:HasTag("civicrystal")) and "CRYSTAL")
end

AddComponentAction("INVENTORY", "nightcrystal", function(inst, doer, actions, right)
	if doer.replica.inventory and not doer.replica.inventory:IsHeavyLifting() then
		local sword = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		if sword and sword.prefab == "nightsword" and sword.replica.container and sword.replica.container:IsOpenedBy(doer) and sword.replica.container:CanTakeItemInSlot(inst) then
			table.insert(actions, ACTIONS.CHANGE_TACKLE)
		elseif doer.prefab == "civi" then
			-- if doer.replica.inventory:GetActiveItem() == inst then return end
			if inst.prefab == "darkcrystal" and doer:HasTag("civi_canupgrade") then
				table.insert(actions, NS_ACTIONS.NIGHTSWITCH)
			elseif inst.prefab == "lightcrystal" and doer:HasTag("civi_candegrade") then
				table.insert(actions, NS_ACTIONS.NIGHTSWITCH)
			end
		end
	end
end)

AddComponentAction("INVENTORY", "friendshiptotem", function(inst, doer, actions, right)
	if doer.replica.inventory and not doer.replica.inventory:IsHeavyLifting() then
		table.insert(actions, NS_ACTIONS.TOGGLETOTEM)
	end
end)

local COMPONENT_ACTIONS = UpvalueUtil.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
local SCENE = COMPONENT_ACTIONS.SCENE
local scene_hauntable = SCENE.hauntable

-- Hauntable for Dummy: only Dummy can haunt Mio and Dummy to revive herself
local DUMMY_NOT_HAUNTABLE_TAGS = { "playerghost", "reviving", "haunted", "catchable" }
function SCENE.hauntable(inst, doer, actions, ...)
	if inst:HasTag("nightmare_twins") then
		if doer.prefab == "dummy" and not inst:HasAnyTag(DUMMY_NOT_HAUNTABLE_TAGS) then
			table.insert(actions, ACTIONS.HAUNT)
		end
	else
		scene_hauntable(inst, doer, actions, ...)
	end
end

-- Delay this so other mods can still use upvalue to hook GetPickupAction
scheduler:ExecuteInTime(0, function()
	local PlayerController = require("components/playercontroller")

	local get_action_button_action = PlayerController.GetActionButtonAction
	function PlayerController:GetActionButtonAction(force_target, ...)
		local is_dummy = self.inst.prefab == "dummy"
		local HAUNT_TARGET_EXCLUDE_TAGS, fn_i, scope_fn = UpvalueUtil.GetUpvalue(get_action_button_action, "HAUNT_TARGET_EXCLUDE_TAGS")
		if HAUNT_TARGET_EXCLUDE_TAGS then
			local haunt_exclude_tags = shallowcopy(HAUNT_TARGET_EXCLUDE_TAGS)
			if is_dummy then
				table.insert(haunt_exclude_tags, "playerghost")
				table.insert(haunt_exclude_tags, "reviving")
			else
				table.insert(haunt_exclude_tags, "nightmare_twins")
			end
			debug.setupvalue(scope_fn, fn_i, haunt_exclude_tags)
		end
		local bufferedaction = get_action_button_action(self, force_target, ...)
		if HAUNT_TARGET_EXCLUDE_TAGS then
			debug.setupvalue(scope_fn, fn_i, HAUNT_TARGET_EXCLUDE_TAGS)
		end
		if bufferedaction and bufferedaction.action == ACTIONS.HAUNT and bufferedaction.target:HasTag("nightmare_twins") and bufferedaction.doer.prefab ~= "dummy" then
			return
		end
		return bufferedaction
	end
end)

-- For portable_wardrobe
AddComponentAction("INVENTORY", "wardrobe", function(inst, doer, actions, right)
	if inst:HasTag("wardrobe") and not inst:HasTag("fire") and (right or not inst:HasTag("dressable")) then
		table.insert(actions, ACTIONS.CHANGEIN)
	end
end)

AddComponentAction("USEITEM", "lunarshadowbattery", function(inst, doer, target, actions, right)
	if target.prefab == "lunarshadow" then
		table.insert(actions, ACTIONS.LUNARSHADOWCHARGE)
	end
end)

AddComponentAction("INVENTORY", "lunarshadowstate", function(inst, doer, actions, right)
	local force_state
	local hat = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
	if hat and (hat.prefab == "lunarplanthat" or hat.prefab == "voidclothhat") then
		force_state = true
	end
	local equipped = inst.replica.equippable and inst.replica.equippable:IsEquipped()
	if not doer.components.playercontroller.isclientcontrollerattached and (right or doer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT)) then
		if equipped then
			if not force_state then
				table.insert(actions, NS_ACTIONS.LUNARSHADOWSTATE)
			end
		else
			table.insert(actions, NS_ACTIONS.LUNARSHADOWSTATE)
		end
	else
		if equipped and not force_state then
			table.insert(actions, NS_ACTIONS.LUNARSHADOWSTATE)
		end
	end
end)

local lunarshadow_state = State({
	name = "dostatebuild",

	onenter = function(inst)
		inst.sg:GoToState("dolongaction", 2)
	end,
})

for _, sg in ipairs({ "wilson", "wilson_client" }) do
	AddStategraphState(sg, lunarshadow_state)

	AddStategraphActionHandler(sg, ActionHandler(NS_ACTIONS.MIOFUEL, "doshortaction"))
	AddStategraphActionHandler(sg, ActionHandler(NS_ACTIONS.MIOEATFUEL, "quickeat"))
	AddStategraphActionHandler(sg, ActionHandler(NS_ACTIONS.GEMTRADE, "doshortaction"))
	AddStategraphActionHandler(sg, ActionHandler(NS_ACTIONS.NIGHTSWORD, "doshortaction"))
	AddStategraphActionHandler(sg, ActionHandler(NS_ACTIONS.NIGHTSWITCH, "domediumaction"))
	AddStategraphActionHandler(sg, ActionHandler(NS_ACTIONS.FUELPOCKETWATCH, "pocketwatch_warpback_pre"))
	AddStategraphActionHandler(sg, ActionHandler(NS_ACTIONS.MUTATETOTEM, "doshortaction"))
	AddStategraphActionHandler(sg, ActionHandler(NS_ACTIONS.TOGGLETOTEM, "doshortaction"))
	AddStategraphActionHandler(sg, ActionHandler(NS_ACTIONS.LUNARSHADOWCHARGE, "doshortaction"))
	AddStategraphActionHandler(sg, ActionHandler(NS_ACTIONS.LUNARSHADOWSTATE, "dostatebuild"))
end

--------------------------------------------------------------------------------

-- right click to set battery --
local function set_reloaditem_battery(inst)
	inst:AddTag("reloaditem_lunarshadow")
	if not TheWorld.ismastersim then
		return
	end
	inst:AddComponent("reloaditem")
	inst:AddComponent("lunarshadowbattery")
end

for prefab in pairs(TUNING.LUNARSHADOW.BATTERIES) do
	AddPrefabPostInit(prefab, set_reloaditem_battery)
end
