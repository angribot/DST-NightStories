local assets = {
	Asset("ANIM", "anim/nightpack.zip"),
	Asset("ANIM", "anim/ui_backpack_2x4.zip"),
}

local prefabs = {
	"lanternlight",
	"shadow_puff",
	"pandorachest_reset",
}

local STATE_NAMES = {
	"red",
	"blue",
	"purple",
	"yellow",
	"orange",
	"green",
	"opal",
	"dark", -- Deprecated
	"light", -- Deprecated
	"nightmare",
	"horror",
}

local FUEL_STATES = {
	nightmare = true,
	horror = true,
}

local STATE_IDS = table.invert(STATE_NAMES)

local function SetState(inst, state)
	inst._state:set(STATE_IDS[state] or 0)
end

local function GetState(inst)
	local id = inst._state:value()
	return id ~= 0 and STATE_NAMES[id] or nil
end

-- function RED --
local function IsValidVictim(victim)
	return not (
			victim:HasTag("veggie")
			or victim:HasTag("structure")
			or victim:HasTag("wall")
			or victim:HasTag("balloon")
			or victim:HasTag("soulless")
			or victim:HasTag("groundspike")
			or victim:HasTag("smashable")
		) and ((victim.components.combat ~= nil and victim.components.health ~= nil) or victim.components.murderable ~= nil)
end

local function OnHealing(inst, data)
	local victim = data.inst
	if
		victim ~= nil
		and victim:IsValid()
		and (victim == inst or (not inst.components.health:IsDead() and IsValidVictim(victim) and victim.components.health:IsDead() and inst:IsNear(victim, 15)))
	then
		local epicmult = victim:HasTag("dualsoul") and 2 or (victim:HasTag("epic") and math.random(7, 8)) or 1
		if inst.components.health then
			inst.components.health:DoDelta(5 * epicmult)
		end
	end
end

local function OnEntityDeath(inst, data)
	if data.inst ~= nil and data.inst.components.lootdropper == nil then
		OnHealing(inst, data)
	end
end

local function OnStarvedTrapSouls(inst, data)
	local trap = data.trap
	if trap ~= nil and (data.numsouls or 0) > 0 and trap:IsValid() and inst:IsNear(trap, 15) then
		if inst.components.health then
			inst.components.health:DoDelta(5 * data.numsouls)
		end
	end
end

local function OnMurdered(inst, data)
	local victim = data.victim
	if victim ~= nil and victim:IsValid() and (not inst.components.health:IsDead() and IsValidVictim(victim)) then
		if inst.components.health then
			inst.components.health:DoDelta(5 * (data.stackmult or 1))
		end
	end
end

local function RemoveListen(inst, owner)
	if inst._onentitydroplootfn ~= nil then
		inst:RemoveEventCallback("entity_droploot", inst._onentitydroplootfn, TheWorld)
		inst._onentitydroplootfn = nil
	end
	if inst._onentitydeathfn ~= nil then
		inst:RemoveEventCallback("entity_death", inst._onentitydeathfn, TheWorld)
		inst._onentitydeathfn = nil
	end
	if inst._onstarvedtrapsoulsfn ~= nil then
		inst:RemoveEventCallback("starvedtrapsouls", inst._onstarvedtrapsoulsfn, TheWorld)
		inst._onstarvedtrapsoulsfn = nil
	end
	if inst._onmurderedfn ~= nil then
		inst:RemoveEventCallback("murdered", inst._onmurderedfn, owner)
		inst._onmurderedfn = nil
	end
end

local function ActivateListen(inst, owner)
	if inst._onentitydroplootfn == nil then
		inst._onentitydroplootfn = function(src, data)
			OnHealing(owner, data)
		end
		inst:ListenForEvent("entity_droploot", inst._onentitydroplootfn, TheWorld)
	end
	if inst._onentitydeathfn == nil then
		inst._onentitydeathfn = function(src, data)
			OnEntityDeath(owner, data)
		end
		inst:ListenForEvent("entity_death", inst._onentitydeathfn, TheWorld)
	end
	if inst._onstarvedtrapsoulsfn == nil then
		inst._onstarvedtrapsoulsfn = function(src, data)
			OnStarvedTrapSouls(inst, data)
		end
		inst:ListenForEvent("starvedtrapsouls", inst._onstarvedtrapsoulsfn, TheWorld)
	end
	if inst._onmurderedfn == nil then
		inst._onmurderedfn = function(src, data)
			OnMurdered(owner, data)
		end
		inst:ListenForEvent("murdered", inst._onmurderedfn, owner)
	end
end

-- function ORANGE --
local function pickup(inst, owner)
	local item = FindPickupableItem(owner, TUNING.ORANGEAMULET_RANGE, false)
	if item == nil then
		return
	end

	local didpickup = false
	if item.components.trap ~= nil then
		item.components.trap:Harvest(owner)
		didpickup = true
	end

	if owner.components.minigame_participator ~= nil then
		local minigame = owner.components.minigame_participator:GetMinigame()
		if minigame ~= nil then
			minigame:PushEvent("pickupcheat", { cheater = owner, item = item })
		end
	end

	--Amulet will only ever pick up items one at a time. Even from stacks.
	SpawnPrefab("shadow_puff").Transform:SetPosition(item.Transform:GetWorldPosition())

	if not didpickup then
		local item_pos = item:GetPosition()
		if item.components.stackable ~= nil then
			item = item.components.stackable:Get()
		end

		owner.components.inventory:GiveItem(item, nil, item_pos)
	end
end

local function onfuelupdate(inst)
	local owner = inst.components.inventoryitem.owner
	if inst._light == nil or not inst._light:IsValid() then
		inst._light = SpawnPrefab("lanternlight")
	end
	if inst._light ~= nil and inst._light:IsValid() then
		local fuelpercent = inst.components.fueled:GetPercent()
		inst._light.Light:SetIntensity(Lerp(0.3, 0.5, fuelpercent))
		inst._light.Light:SetRadius(Lerp(1.75, 2.25, fuelpercent))
		inst._light.Light:SetFalloff(0.7)
		inst._light.entity:SetParent((owner or inst).entity)
	end
end

local function nofuel(inst)
	inst.components.fueled:SetUpdateFn(nil)
	inst:RemoveComponent("fueled")
	if inst:HasTag("nofuelsocket") then
		inst:RemoveTag("nofuelsocket")
	end
	inst:RenewState()
end

local function try_reopen(inst, owner)
	if owner and inst.components.container:IsOpen() then
		inst.components.container:Close()
		inst.components.container:Open(owner)
	end
end

local StateFns = {

	red = function(inst, owner)
		if owner then
			ActivateListen(inst, owner)
		end
	end,

	blue = function(inst, owner)
		if not inst:HasTag("fridge") then
			inst:AddTag("fridge")
		end
		if not inst:HasTag("nocool") then
			inst:AddTag("nocool")
		end
	end,

	purple = function(inst, owner)
		inst.components.equippable.dapperness = -TUNING.CRAZINESS_SMALL
	end,

	yellow = function(inst, owner)
		inst.components.equippable.walkspeedmult = 1.2
	end,

	orange = function(inst, owner)
		if inst.pickup_task ~= nil then
			inst.pickup_task:Cancel()
			inst.pickup_task = nil
		end
		if owner then
			inst.pickup_task = inst:DoPeriodicTask(0.2, pickup, nil, owner)
		end
	end,

	green = function(inst, owner)
		inst.components.container:WidgetSetup("krampus_sack")
		if owner and not TheNet:IsDedicated() then -- For client host
			try_reopen(inst, owner)
		end
	end,

	opal = function(inst, owner)
		if not inst:HasTag("fridge") then
			inst:AddTag("fridge")
		end
		if inst:HasTag("nocool") then
			inst:RemoveTag("nocool")
		end
	end,

	dark = function(inst, owner)
		if owner and owner.components.combat then
			owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1.2, "nightpack")
		end
	end,

	light = function(inst, owner)
		if inst._light == nil or not inst._light:IsValid() then
			inst._light = SpawnPrefab("lanternlight")
		end
		if inst._light ~= nil or inst._light:IsValid() then
			inst._light.Light:SetIntensity(0.5)
			inst._light.Light:SetRadius(3)
			inst._light.Light:SetFalloff(0.7)
			inst._light.entity:SetParent((owner or inst).entity)
		end
	end,

	nightmare = function(inst, owner)
		if not inst:HasTag("nofuelsocket") then
			inst:AddTag("nofuelsocket")
		end
		if inst.components.fueled == nil then
			inst:AddComponent("fueled")
			inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
			inst.components.fueled:InitializeFuelLevel(360)
			inst.components.fueled:SetPercent(0.5)
			inst.components.fueled:SetDepletedFn(nofuel)
			inst.components.fueled:SetUpdateFn(onfuelupdate)
			inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
			inst.components.fueled.accepting = true

			inst.components.fueled:StartConsuming()
		end
	end,

	horror = function(inst, owner)
		if not inst:HasTag("nofuelsocket") then
			inst:AddTag("nofuelsocket")
		end
		if inst.components.fueled == nil then
			inst:AddComponent("fueled")
			inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
			inst.components.fueled:InitializeFuelLevel(360)
			inst.components.fueled:SetPercent(1)
			inst.components.fueled:SetDepletedFn(nofuel)
			inst.components.fueled:SetUpdateFn(onfuelupdate)
			inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
			inst.components.fueled.accepting = true

			inst.components.fueled:StartConsuming()
		end
	end,
}

local function ApplyState(inst, override_state)
	local state = override_state or inst:GetState()
	if not state then
		print("error: trying to apply nil state on", inst)
		return
	end
	local image_state = FUEL_STATES[state] and "fuel" or state
	inst.components.inventoryitem:ChangeImageName("nightpack_" .. image_state)
	inst.MiniMapEntity:SetIcon("nightpack_" .. image_state .. ".tex")
	inst.AnimState:PlayAnimation(image_state)

	local state_fn = StateFns[state]
	if state_fn then
		state_fn(inst, inst.components.inventoryitem.owner)
	end

	inst.drawnameoverride = not inst:HasTag("nightpack_blighted")
			and rawget(_G, "EncodeStrCode")
			and EncodeStrCode({ content = state and "NAMES.NIGHTPACK_" .. image_state:upper() or "NAMES.NIGHTPACK" })
		or nil
end

local function BlightedName(inst, name)
	return inst:HasTag("nightpack_blighted") and subfmt(STRINGS.NAMES.NIGHTPACK_BLIGHTED, { backpack = name }) or name
end

local function BaseDisplayName(inst)
	local state = inst:GetState()
	return state and STRINGS.NAMES["NIGHTPACK_" .. state:upper()] or STRINGS.NAMES.NIGHTPACK
end

local function DisplayNameFn(inst)
	return BlightedName(inst, BaseDisplayName(inst))
end

local function ImmortalDisplayNameFn(inst)
	inst:DoTaskInTime(FRAMES, function()
		inst.displaynamefn = function()
			return BlightedName(inst, subfmt(STRINGS.NAMES["IMMORTAL_BACKPACK"], { backpack = BaseDisplayName(inst) }))
		end
	end)
end

local function RenewState(inst, gemtype, isdummy, blighted)
	if inst:HasTag("nightpack_blighted") and not blighted then
		return
	end
	local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
	-- healing --
	RemoveListen(inst, owner)
	-- dark --
	if owner and owner.components.combat then
		owner.components.combat.externaldamagemultipliers:RemoveModifier(inst, "nightpack")
	end
	-- light
	if inst._light ~= nil then
		if inst._light:IsValid() then
			inst._light:Remove()
		end
		inst._light = nil
	end
	-- <renew pack> --
	local isopen = inst.components.container:IsOpen()
	local newpack = SpawnPrefab("nightpack")
	if owner ~= nil then
		if owner.components.inventory ~= nil then
			owner.components.inventory:Unequip(EQUIPSLOTS.BODY)
			owner.components.inventory:Equip(newpack)
			if not isopen then
				newpack.replica.container:Close()
			end
		end
	else
		newpack.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end

	if blighted then
		-- Set the destination capacity before moving items, including green-to-green corruption.
		newpack:OnGemTrade(gemtype, isdummy, true)
		newpack:AddTag("nightpack_blighted")
		newpack.components.timer:StopTimer("state_change")
		newpack.drawnameoverride = nil
	end

	local slots = inst.components.container.slots
	local need_compress = newpack.components.container:GetNumSlots() < inst.components.container:GetNumSlots()
	for _, slot, item in sorted_pairs(slots) do
		if need_compress then
			if not newpack.components.container:IsFull() or owner == nil then
				newpack.components.container:GiveItem(item)
			else
				owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
			end
		else
			newpack.components.container:GiveItem(item, slot)
		end
	end

	local setImmortal = false
	if inst:HasTag("keepfresh") and newpack.setImmortal then
		setImmortal = true
	end
	inst:Remove()

	if gemtype and not blighted then
		newpack:OnGemTrade(gemtype, isdummy, true)
	end

	if setImmortal then
		newpack:setImmortal()
		ImmortalDisplayNameFn(newpack)
	end
	return newpack
end

local CORRUPTED_STATES = { red = true, blue = true, purple = true, yellow = true, orange = true, green = true }
local function CorruptWithGem(inst, state)
	if not CORRUPTED_STATES[state] or (inst:HasTag("nightpack_blighted") and inst:GetState() == state) then
		return false
	end
	return inst:RenewState(state, false, true) ~= nil
end

local function OnChangeState(inst, state, duration)
	if inst:HasTag("nightpack_blighted") then
		return
	end
	inst:SetState(state)
	inst.components.timer:StopTimer("state_change")
	if duration then
		inst.components.timer:StartTimer("state_change", duration)
	end
	inst:ApplyState()
end

local days = TUNING.TOTAL_DAY_TIME
local GEM_DURATIONS = {
	red = 1.2 * days,
	dark = 1.2 * days,
	purple = 2.4 * days,
	light = 2.4 * days,
	blue = 4.8 * days,
	yellow = 3.6 * days,
	orange = 1.2 * days,
	green = 12 * days,
	opal = 12 * days,
}

local function OnGemTrade(inst, gemtype, isdummy, from_renew)
	if inst:HasTag("nightpack_blighted") then
		return
	end
	local owner = inst.components.inventoryitem.owner
	if not from_renew then
		if inst:GetState() ~= gemtype then
			inst:RenewState(gemtype, isdummy)
			return
		else
			try_reopen(inst, owner)
		end
	end

	local fx = SpawnPrefab("pandorachest_reset")
	if fx ~= nil then
		fx.entity:SetParent((owner or inst).entity)
	end
	if gemtype == "nightmare" or gemtype == "horror" then
		inst.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
	else
		inst.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
	end
	inst:OnChangeState(gemtype, GEM_DURATIONS[gemtype] and GEM_DURATIONS[gemtype] * (isdummy and 1.5 or 1))
end

local function onequip(inst, owner)
	if inst.components.container ~= nil then
		inst.components.container:Open(owner)
	end
	if inst:GetState() then
		inst:ApplyState()
	end
end

local function onunequip(inst, owner)
	if inst.components.container then
		inst.components.container:Close(owner)
	end
	-- healing --
	RemoveListen(inst, owner)
	-- dark --
	if owner.components.combat then
		owner.components.combat.externaldamagemultipliers:RemoveModifier(inst, "nightpack")
	end
	if inst.pickup_task ~= nil then
		inst.pickup_task:Cancel()
		inst.pickup_task = nil
	end
	-- light
	if inst._light ~= nil and inst._light:IsValid() then
		inst._light.entity:SetParent(inst.entity)
	end
end

local function OnPreLoad(inst, data)
	if data and type(data._state) == "string" then -- for old buggy codes...
		if data.blighted and CORRUPTED_STATES[data._state] then
			inst:AddTag("nightpack_blighted")
		end
		inst:SetState(data._state)
		inst:ApplyState()
	end
end

local function OnSave(inst, data)
	data._state = inst:GetState()
	data.blighted = inst:HasTag("nightpack_blighted") or nil
end

local function OnRemove(inst)
	if inst._light ~= nil then
		inst._light:Remove()
	end
end

local function on_timerdone(inst)
	inst:RenewState()
end

local function OnEntityReplicated(inst)
	inst.replica.container:WidgetSetup("backpack")
end

local function OnStateDirty(inst)
	if inst:GetState() == "green" then
		if not inst.is_greenpack then
			inst.replica.container:WidgetSetup("krampus_sack")
			inst.is_greenpack = true
		end
	elseif inst.is_greenpack then
		inst.replica.container:WidgetSetup("backpack")
		inst.is_greenpack = false
	end
end

local function getstatus(inst, viwer)
	local state = inst:GetState()
	return state and state:upper()
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("nightpack")
	inst.AnimState:SetBuild("nightpack")
	inst.AnimState:PlayAnimation("anim")

	inst.MiniMapEntity:SetIcon("nightpack.tex")

	inst:AddTag("backpack")
	inst:AddTag("waterproofer")

	inst.displaynamefn = DisplayNameFn

	inst._state = net_smallbyte(inst.GUID, "nightpack._state", "statedirty")

	inst.GetState = GetState

	inst.foleysound = "dontstarve/movement/foley/backpack"

	MakeInventoryFloatable(inst, "small", 0.1, 0.7)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst.is_greenpack = false
		inst.OnEntityReplicated = OnEntityReplicated
		inst:ListenForEvent("statedirty", OnStateDirty)
		return inst
	end

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = getstatus

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.cangoincontainer = false

	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(0)

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("backpack")

	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", on_timerdone)

	MakeHauntableLaunchAndDropFirstItem(inst)

	inst.SetState = SetState
	inst.OnGemTrade = OnGemTrade
	inst.CorruptWithGem = CorruptWithGem
	inst.ApplyState = ApplyState
	inst.RenewState = RenewState
	inst.OnChangeState = OnChangeState

	inst.OnSave = OnSave
	inst.OnPreLoad = OnPreLoad
	inst.OnRemoveEntity = OnRemove

	inst:ListenForEvent("immortalchangenamedirty", function(_inst)
		if _inst:HasTag("keepfresh") and _inst.immortalchangename:value() then
			ImmortalDisplayNameFn(_inst)
		end
	end)

	inst.drawnameoverride = rawget(_G, "EncodeStrCode") and EncodeStrCode({ content = "NAMES.NIGHTPACK" })

	return inst
end

return Prefab("nightpack", fn, assets, prefabs)
