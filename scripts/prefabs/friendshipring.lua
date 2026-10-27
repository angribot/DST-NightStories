local assets = {
	Asset("ANIM", "anim/friendshipring.zip"),
}

local prefabs = {
	ring = {
		"glash_fx",
		"glash_big_fx",
	},
	totem = {
		"statue_transition",
		"statue_transition_2",
	},
}

----------------------------------------------------------------
-------------------------- TOGGLE FX ---------------------------
----------------------------------------------------------------

local WAVE_FX_LEN = 0.5
local function WaveFxOnUpdate(inst, dt)
	inst.t = inst.t + dt

	if inst.t < WAVE_FX_LEN then
		local k = 1 - inst.t / WAVE_FX_LEN
		k = k * k
		inst.AnimState:SetMultColour(1, 1, 1, k)
		k = (2 - 1.7 * k) * (inst.scalemult or 1)
		inst.AnimState:SetScale(k, k)
	else
		inst:Remove()
	end
end

local function CreateWaveFX()
	local inst = CreateEntity()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst.AnimState:SetBank("umbrella_voidcloth")
	inst.AnimState:SetBuild("umbrella_voidcloth")
	inst.AnimState:PlayAnimation("barrier_rim")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst:AddComponent("updatelooper")
	inst.components.updatelooper:AddOnUpdateFn(WaveFxOnUpdate)
	inst.t = 0
	inst.scalemult = 0.75
	WaveFxOnUpdate(inst, 0)

	return inst
end

local function CreateDomeFX()
	local inst = CreateEntity()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()

	inst.AnimState:SetBank("umbrella_voidcloth")
	inst.AnimState:SetBuild("umbrella_voidcloth")
	inst.AnimState:PlayAnimation("barrier_dome")
	inst.AnimState:SetFinalOffset(7)

	inst:AddComponent("updatelooper")
	inst.components.updatelooper:AddOnUpdateFn(WaveFxOnUpdate)
	inst.t = 0
	WaveFxOnUpdate(inst, 0)

	return inst
end

local function CLIENT_TriggerFX(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	CreateWaveFX().Transform:SetPosition(x, 0, z)
	local fx = CreateDomeFX()
	fx.Transform:SetPosition(x, 0, z)
	fx.SoundEmitter:PlaySound("meta2/voidcloth_umbrella/barrier_activate")
end

local function SERVER_TriggerFX(inst)
	inst.fx_proxy.triggerfx:push()
	if not TheNet:IsDedicated() then
		CLIENT_TriggerFX(inst.fx_proxy)
	end
end

----------------------------------------------------------------
------------------------ TOTEM FUNCTION ------------------------
----------------------------------------------------------------

local function turn_on(inst)
	if not inst.toggled:value() then
		inst.toggled:set(true)
		inst.components.fueled:StartConsuming()

		if inst.shadowtask ~= nil then
			inst.shadowtask:Cancel()
			inst.shadowtask = nil
		end

		if not (inst:IsAsleep() or POPULATING) then
			SERVER_TriggerFX(inst)
		end

		inst.SoundEmitter:PlaySound("meta2/voidcloth_umbrella/barrier_lp", "loop")

		if inst.task == nil then
			inst.task = inst:DoPeriodicTask(0.5, inst.totemfn, 0)
		end
	end
end

local function turn_off(inst)
	if inst.toggled:value() then
		inst.toggled:set(false)
		inst.components.fueled:StopConsuming()

		if inst.task then
			inst.task:Cancel()
			inst.task = nil
		end

		if inst.SoundEmitter:PlayingSound("loop") then
			inst.SoundEmitter:KillSound("loop")
		end
		inst.SoundEmitter:PlaySound("meta2/voidcloth_umbrella/barrier_close")
	end
end

local function onupdate(inst)
	if inst.components.fueled and inst.components.fueled:IsEmpty() then
		turn_off(inst)
	else
		turn_on(inst)
	end
end

local totemfn = {
	dark = function(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local players = FindPlayersInRange(x, y, z, TUNING.TOTEM_BUFF_RANGE, true)
		for _, player in pairs(players) do
			player:AddDebuff("buff_friendshiptotem_dark", "buff_friendshiptotem_dark")
		end
	end,

	light = function(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local players = FindPlayersInRange(x, y, z, TUNING.TOTEM_BUFF_RANGE, true)
		for _, player in pairs(players) do
			player:AddDebuff("buff_friendshiptotem_light", "buff_friendshiptotem_light")
		end
	end,
}

---------------------------------------------------------------
------------------------ RING FUNCTION ------------------------
---------------------------------------------------------------
local AIBO_TAGS = { "eyeturret", "catapult", "bigbernie", "vault_pillar_guard", "wagdrone_rolling" }

local function get_aibo(player)
	local ppx, ppy, ppz = player.Transform:GetWorldPosition()
	return TheSim:FindEntities(ppx, ppy, ppz, 30, nil, nil, AIBO_TAGS)
end

local function buff_friends(oneatenfn, food, player, buff_self)
	local buff_entities = {}
	if buff_self then
		buff_entities[player] = true
	end
	local leader = player.components.leader
	if leader then
		for follower in pairs(leader.followers) do
			buff_entities[follower] = true
		end
		for follower in pairs(leader.itemfollowers) do
			buff_entities[follower] = true
		end
	end
	for _, ent in ipairs(get_aibo(player)) do
		if (not ent:HasTag("vault_pillar_guard") or ent:HasTag("player_aligned")) and (not ent:HasTag("wagdrone_rolling") or ent.components.inventoryitem ~= nil) then
			buff_entities[ent] = true
		end
	end
	for ent in pairs(buff_entities) do
		oneatenfn(food, ent)
		local x, y, z = ent.Transform:GetWorldPosition()
		SpawnPrefab("glash_fx").Transform:SetPosition(x, y, z)
	end
end

local function oneat(inst, owner, data)
	local food = data and data.food
	-- local owner = inst.components.inventoryitem.owner
	if food then
		local oneatenfn = food.components.edible.oneaten
		-- print("oneatenfn", inst, owner, oneatenfn)
		if oneatenfn then
			local x, y, z = owner.Transform:GetWorldPosition()
			local players = FindPlayersInRange(x, y, z, TUNING.TOTEM_BUFF_RANGE, true)
			for _, player in pairs(players) do
				if player.userid ~= owner.userid then
					buff_friends(oneatenfn, food, player, true)
				else
					buff_friends(oneatenfn, food, player)
					SpawnPrefab("glash_big_fx").Transform:SetPosition(x, y, z)
				end
			end
			local percent = inst.components.finiteuses:GetPercent()
			percent = math.clamp(percent, 0, 1)
			inst.components.finiteuses:SetPercent(percent)
			inst.components.finiteuses:Use(1)
		end
	end
end

local function onequip(inst, owner)
	inst._oneat = function(_owner, _data)
		oneat(inst, _owner, _data)
	end
	inst:ListenForEvent("oneat", inst._oneat, owner)

	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function onunequip(inst, owner)
	inst:RemoveEventCallback("oneat", inst._oneat, owner)

	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
	if inst:GetSkinBuild() ~= nil then
		owner:PushEvent("unequipskinneditem", inst:GetSkinName())
	end
end

local function onfinished(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
	inst:Remove()
end

local function spawn_fx(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")

	local x, y, z = inst.Transform:GetWorldPosition()
	local fx = SpawnPrefab("statue_transition_2")
	if fx ~= nil then
		fx.Transform:SetPosition(x, y, z)
		fx.Transform:SetScale(0.4, 1, 0.4)
	end
	fx = SpawnPrefab("statue_transition")
	if fx ~= nil then
		fx.Transform:SetPosition(x, y, z)
		fx.Transform:SetScale(0.4, 0.6, 0.4)
	end
end

local function onfinished_totem(inst)
	turn_off(inst)
	spawn_fx(inst)
	inst:Remove()
end

local function update_fx_parent(inst)
	local owner = inst.components.inventoryitem:GetGrandOwner() or inst.components.inventoryitem.owner or inst
	inst.fx_proxy.entity:SetParent(owner.entity)
end

-- Going in / swap to another container
local function on_in_inventory(inst, owner)
	turn_off(inst)

	update_fx_parent(inst)

	inst:RemoveEventCallback("onownerputininventory", update_fx_parent)
	inst:RemoveEventCallback("onownerdropped", update_fx_parent)
	inst:ListenForEvent("onownerputininventory", update_fx_parent)
	inst:ListenForEvent("onownerdropped", update_fx_parent)
end

local function on_out_inventory(inst)
	turn_on(inst)

	update_fx_parent(inst)

	inst:RemoveEventCallback("onownerputininventory", update_fx_parent)
	inst:RemoveEventCallback("onownerdropped", update_fx_parent)
end

local function OnLoad(inst, data)
	if data and data.toggled then
		turn_on(inst)
	end
end

local function OnSave(inst, data)
	data.toggled = inst.toggled:value()
end

---------------------------------------------------------------
----------------------- COMMON FUNCTION -----------------------
---------------------------------------------------------------

local function common_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("friendshipring")
	inst.AnimState:SetBuild("friendshipring")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inventoryitem")

	inst:AddComponent("inspectable")

	-- inst:DoTaskInTime(0, function(inst)
	--	 inst.drawnameoverride = rawget(_G, "EncodeStrCode") and EncodeStrCode({content = "NAMES." .. string.upper(inst.prefab)})
	-- end)
	if rawget(_G, "EncodeDrawNameCode") then
		EncodeDrawNameCode(inst)
	end

	return inst
end

local function base_fn()
	local inst = common_fn()
	MakeInventoryFloatable(inst, "small", 0.07, { 0.7, 0.7, 0.7 })

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetOnFinished(onfinished)
	inst.components.finiteuses:SetMaxUses(15)
	inst.components.finiteuses:SetUses(15)

	return inst
end

local function fx_proxy_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:SetPristine()
	inst.triggerfx = net_event(inst.GUID, "friendshiptotem.triggerfx")

	if not TheWorld.ismastersim then
		inst:DoTaskInTime(0, inst.ListenForEvent, "friendshiptotem.triggerfx", CLIENT_TriggerFX)
		return inst
	end
	return inst
end

local function MakeTotem(color)
	local function totem_fn()
		local inst = common_fn()

		inst.AnimState:PlayAnimation(color .. "_loop", true)

		inst.toggled = net_bool(inst.GUID, "friendshiptotem.toogle", "friendshiptotem.toggledirty")

		inst.fx_proxy = SpawnPrefab("friendshiptotem_fx_proxy")
		inst.fx_proxy.entity:SetParent(inst.entity)
		inst:ListenForEvent("remove", inst.fx_proxy.Remove)

		if not TheWorld.ismastersim then
			return inst
		end

		inst.components.inventoryitem:SetSinks(true)

		inst:AddComponent("friendshiptotem")

		local fueled = inst:AddComponent("fueled")
		fueled.fueltype = FUELTYPE.MAGIC
		fueled:InitializeFuelLevel(480)
		fueled:SetDepletedFn(onfinished_totem)
		fueled:SetUpdateFn(onupdate)
		fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
		fueled.period = FRAMES

		local inventoryitem = inst.components.inventoryitem
		inventoryitem:SetOnDroppedFn(on_out_inventory)
		inventoryitem:SetOnPutInInventoryFn(on_in_inventory)

		if color == "dark" then
			local sanityaura = inst:AddComponent("sanityaura")
			sanityaura.aura = -TUNING.SANITYAURA_SMALL
		end

		inst.totemfn = totemfn[color]
		inst.toggled:set(false)

		inst.TurnOn = turn_on
		inst.TurnOff = turn_off

		inst.OnSave = OnSave
		inst.OnLoad = OnLoad

		return inst
	end

	return Prefab("friendshiptotem_" .. color, totem_fn, assets, prefabs.totem)
end

return Prefab("friendshipring", base_fn, assets.ring), MakeTotem("dark"), MakeTotem("light"), Prefab("friendshiptotem_fx_proxy", fx_proxy_fn)
