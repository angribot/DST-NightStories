local Utils = require("nightstories/utils")

local assets = {
	Asset("ANIM", "anim/lunarshadow.zip"),
	Asset("ANIM", "anim/lunarshadow_shadow.zip"),
	Asset("ANIM", "anim/inventory_fx_lunar.zip"),
}

local prefabs = {
	"lunarshadow_blade_fx",
	"hitsparks_fx",
	"lunarplanttentacle",
	"glash",
}

local function set_bonus_enabled(inst, enabled)
	if enabled then
		if not inst._bonusenabled then
			inst._bonusenabled = true
			if inst.components.weapon then
				inst.components.weapon:SetDamage(inst.base_damage * TUNING.LUNARSHADOW.SETBONUS_DAMAGE_MULT)
			end
			inst.components.planardamage:AddBonus(inst, TUNING.LUNARSHADOW.SETBONUS_PLANAR_DAMAGE, "setbonus")
		end
	elseif inst._bonusenabled then
		inst._bonusenabled = nil
		if inst.components.weapon then
			inst.components.weapon:SetDamage(inst.base_damage)
		end
		inst.components.planardamage:RemoveBonus(inst, "setbonus")
	end
end

local function set_bonus_owner(inst, owner)
	if inst._owner ~= owner then
		if inst._owner then
			inst:RemoveEventCallback("equip", inst._onownerequip, inst._owner)
			inst:RemoveEventCallback("unequip", inst._onownerunequip, inst._owner)
			inst._onownerequip = nil
			inst._onownerunequip = nil
			set_bonus_enabled(inst, false)
		end
		inst._owner = owner
		if owner then
			inst._onownerequip = function(owner, data)
				if data then
					if data.item and data.item.prefab == "lunarplanthat" then
						set_bonus_enabled(inst, true)
						inst:SetLunarState(true)
					elseif data.item and data.item.prefab == "voidclothhat" then
						set_bonus_enabled(inst, true)
						inst:SetLunarState(false)
					elseif data.eslot == EQUIPSLOTS.HEAD then
						set_bonus_enabled(inst, false)
					end
				end
			end
			inst._onownerunequip = function(owner, data)
				if data and data.eslot == EQUIPSLOTS.HEAD then
					set_bonus_enabled(inst, false)
				end
			end
			inst:ListenForEvent("equip", inst._onownerequip, owner)
			inst:ListenForEvent("unequip", inst._onownerunequip, owner)

			local hat = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
			if hat then
				if hat.prefab == "lunarplanthat" then
					set_bonus_enabled(inst, true)
					inst:SetLunarState(true)
				elseif hat.prefab == "voidclothhat" then
					set_bonus_enabled(inst, true)
					inst:SetLunarState(false)
				end
			end
		end
	end
end

local function set_fx_owner(inst, owner)
	if inst._fxowner ~= nil and inst._fxowner.components.colouradder ~= nil then
		inst._fxowner.components.colouradder:DetachChild(inst.blade1)
		inst._fxowner.components.colouradder:DetachChild(inst.blade2)
	end
	inst._fxowner = owner
	if owner ~= nil then
		inst.blade1.entity:SetParent(owner.entity)
		inst.blade2.entity:SetParent(owner.entity)
		inst.blade1.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 0, 3)
		inst.blade2.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 5, 8)
		inst.blade1.components.highlightchild:SetOwner(owner)
		inst.blade2.components.highlightchild:SetOwner(owner)
		if owner.components.colouradder ~= nil then
			owner.components.colouradder:AttachChild(inst.blade1)
			owner.components.colouradder:AttachChild(inst.blade2)
		end
	else
		inst.blade1.entity:SetParent(inst.entity)
		inst.blade2.entity:SetParent(inst.entity)
		--For floating
		inst.blade1.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 0, 3)
		inst.blade2.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 5, 8)
		inst.blade1.components.highlightchild:SetOwner(inst)
		inst.blade2.components.highlightchild:SetOwner(inst)
	end
end

local function push_idle_loop(inst)
	if inst.components.finiteuses:GetUses() > 0 then
		inst.AnimState:PushAnimation("idle")
	end
end

local function on_stop_floating(inst)
	if inst.components.finiteuses:GetUses() > 0 then
		inst.blade1.AnimState:SetFrame(0)
		inst.blade2.AnimState:SetFrame(0)
		inst:DoTaskInTime(0, push_idle_loop) --#V2C: #HACK restore the looping anim, timing issues
	end
end

local function onequip(inst, owner)
	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("equipskinneditem", inst:GetSkinName())
		owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_sword_lunarplant", inst.GUID, "sword_lunarplant")
	else
		owner.AnimState:OverrideSymbol("swap_object", "sword_lunarplant", "swap_sword_lunarplant")
	end
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
	set_fx_owner(inst, owner)
	set_bonus_owner(inst, owner)
	if inst.components.container then
		inst.components.container:Open(owner)
	end
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("unequipskinneditem", inst:GetSkinName())
	end
	set_fx_owner(inst, nil)
	set_bonus_owner(inst, nil)
	if inst.components.container then
		inst.components.container:Close()
	end
end

local function refresh_bonus(inst)
	if inst._owner then
		local inv = inst._owner.components.inventory
		local hat = inv and inv:GetEquippedItem(EQUIPSLOTS.HEAD)
		if hat and hat.prefab == (inst.state:value() and "lunarplanthat" or "voidclothhat") then
			set_bonus_enabled(inst, true)
		else
			set_bonus_enabled(inst, false)
		end
		inst._owner:PushEvent("equip", { item = inst, eslot = EQUIPSLOTS.HANDS, no_animation = true })
	end
end

local function set_lunar(inst)
	if not inst.state:value() then
		inst.state:set(true)
		inst.components.forgerepairable:SetRepairMaterial(FORGEMATERIALS.LUNARPLANT)
		inst.components.planardamage:SetBaseDamage(TUNING.LUNARSHADOW.LUNAR_PLANAR_DAMAGE)
		inst.components.damagetypebonus:RemoveBonus("lunar_aligned", inst, "lunarshadow")
		inst.components.damagetypebonus:AddBonus("shadow_aligned", inst, TUNING.LUNARSHADOW.ALIGN_VS_MULT, "lunarshadow")
		inst:AddComponent("lunarplant_tentacle_weapon")
		inst:RemoveComponent("shadowlevel")
		inst:RemoveTag("shadow_item")
		refresh_bonus(inst)
		-- anim and icon --
		local STATE_BUILD = "lunarshadow"
		inst.AnimState:SetBuild(STATE_BUILD)
		inst.blade1.AnimState:SetBuild(STATE_BUILD)
		inst.blade2.AnimState:SetBuild(STATE_BUILD)
		inst.components.inventoryitem:ChangeImageName(STATE_BUILD)
	end
end

local function set_shadow(inst)
	if inst.state:value() then
		inst.state:set(false)
		inst.components.forgerepairable:SetRepairMaterial(FORGEMATERIALS.VOIDCLOTH)
		inst.components.planardamage:SetBaseDamage(TUNING.LUNARSHADOW.SHADOW_PLANAR_DAMAGE)
		inst.components.damagetypebonus:RemoveBonus("shadow_aligned", inst, "lunarshadow")
		inst.components.damagetypebonus:AddBonus("lunar_aligned", inst, TUNING.LUNARSHADOW.ALIGN_VS_MULT, "lunarshadow")
		inst:RemoveComponent("lunarplant_tentacle_weapon")
		inst:AddComponent("shadowlevel")
		inst.components.shadowlevel:SetDefaultLevel(TUNING.LUNARSHADOW.SHADOW_LEVEL)
		inst:AddTag("shadow_item")
		refresh_bonus(inst)
		-- anim and icon --
		local STATE_BUILD = "lunarshadow_shadow"
		inst.AnimState:SetBuild(STATE_BUILD)
		inst.blade1.AnimState:SetBuild(STATE_BUILD)
		inst.blade2.AnimState:SetBuild(STATE_BUILD)
		inst.components.inventoryitem:ChangeImageName(STATE_BUILD)
	end
end

local function set_lunarstate(inst, islunar)
	if islunar then
		set_lunar(inst)
	else
		set_shadow(inst)
	end
end

local function validate_battery_value(inst, battery_prefab, set_state)
	if battery_prefab then
		local power = TUNING.LUNARSHADOW.BATTERIES[battery_prefab]
		-- if set_state then
		--	 set_lunarstate(inst, power > 0)
		-- end
		return math.abs(power)
	end
	return 0
end

local function get_current_battery(inst)
	return inst.components.container:GetItemInSlot(1)
end

local function auto_refill(inst, prev_item_prefab)
	if not inst.components.container:IsEmpty() then
		return
	end
	local owner = inst.components.inventoryitem.owner
	local inv = owner.components.inventory
	local container = inst.components.container
	local hat = inv and inv:GetEquippedItem(EQUIPSLOTS.HEAD)
	local hat_container = hat and hat.prefab == "alterguardianhat" and hat.components.container
	local item_fn = function(item)
		return item.prefab == prev_item_prefab
	end
	local new_item = inv and inv:FindItem(item_fn)
	if new_item then
		inv:RemoveItem(new_item, true)
		container:GiveItem(new_item)
	elseif hat_container then
		local new_hat_item = hat_container:FindItem(item_fn)
		if new_hat_item then
			hat_container:RemoveItem(new_hat_item, true)
			container:GiveItem(new_hat_item)
		end
	end
end

local function can_consume_battery(inst)
	local current_item = get_current_battery(inst)
	if not current_item then
		return
	end
	local power = validate_battery_value(inst, current_item.prefab)
	-- total is max uses
	return inst.components.finiteuses.total - inst.components.finiteuses:GetUses() >= power
end

local function set_buffed_atks(inst, amount)
	inst.buffed_atks = math.clamp(amount, 0, TUNING.LUNARSHADOW.USES)
	if inst.buffed_atks > 0 then
		inst.buffed:set(true)
		inst.base_damage = TUNING.LUNARSHADOW.BUFFED_DAMAGE
		inst:AddTag("ignore_planar_entity")
	else
		inst.buffed:set(false)
		inst.base_damage = TUNING.LUNARSHADOW.BASE_DAMAGE
		inst:RemoveTag("ignore_planar_entity")
	end
	inst.components.weapon:SetDamage(inst._bonusenabled and inst.base_damage * TUNING.LUNARSHADOW.SETBONUS_DAMAGE_MULT or inst.base_damage)
end

local function try_consume_battery(inst)
	local current_item = get_current_battery(inst)
	if not current_item then
		return
	end
	-- total is max uses
	local power = validate_battery_value(inst, current_item.prefab)
	if inst.components.finiteuses.total - inst.components.finiteuses:GetUses() >= power then
		inst:ChargeWithItem(current_item)
		if current_item.components.stackable then
			current_item.components.stackable:Get():Remove()
		else
			current_item:Remove()
		end
		auto_refill(inst, current_item.prefab)
		return true
	end
end

local function calc_consume_mult(attacker)
	-- local base_mult = TUNING.MOONLIGHT_SHADOW.CONSUME_RATE.MOONGLASS.MULT
	local damagemult = attacker.components.combat.damagemultiplier or 1
	damagemult = math.clamp(damagemult, 1, 2)
	local electricmult = attacker.components.electricattacks and 0.5 or 0
	return 0.5 * (damagemult + 1) + electricmult
end

local function do_consume(inst, attacker)
	local mult = calc_consume_mult(attacker)
	inst.components.finiteuses:Use(inst.buffed:value() and mult or 1)
	set_buffed_atks(inst, inst.buffed_atks - mult)
	try_consume_battery(inst)
end

local target_testfn = Utils.TargetTestFn
local function onattack(inst, attacker, target)
	do_consume(inst, attacker)
	if target and target:IsValid() then
		local spark = SpawnPrefab("hitsparks_fx")
		if inst.state:value() then
			spark:Setup(attacker, target)
		else
			local hitsparks_fx_colouroverride = { 1, 0, 0 }
			spark:Setup(attacker, target, nil, hitsparks_fx_colouroverride)
			spark.black:set(true)
		end
	end
end

local FLOAT_SCALE_BROKEN = { 1, 0.7, 1 }
local FLOAT_SCALE = { 1, 0.4, 1 }

local function on_isbroken_dirty(inst)
	if inst.isbroken:value() then
		inst.components.floater:SetSize("small")
		inst.components.floater:SetVerticalOffset(0.05)
		inst.components.floater:SetScale(FLOAT_SCALE_BROKEN)
	else
		inst.components.floater:SetSize("med")
		inst.components.floater:SetVerticalOffset(0.05)
		inst.components.floater:SetScale(FLOAT_SCALE)
	end
end

local SWAP_DATA_BROKEN = { bank = "lunarshadow", anim = "broken" }
local SWAP_DATA = { bank = "lunarshadow", sym_build = "lunarshadow", sym_name = "swap_lunarshadow" }
local SWAP_DATA_SHADOW = { bank = "lunarshadow", sym_build = "lunarshadow_shadow", sym_name = "swap_lunarshadow" }

local function set_isbroken(inst, isbroken)
	if isbroken then
		inst.components.floater:SetBankSwapOnFloat(false, nil, SWAP_DATA_BROKEN)
	else
		inst.components.floater:SetBankSwapOnFloat(true, -17.5, inst.state:value() and SWAP_DATA or SWAP_DATA_SHADOW)
	end
	inst.isbroken:set(isbroken)
	on_isbroken_dirty(inst)
end

local function setup_equippable(inst)
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
end

local function disable_equippable(inst)
	inst:RemoveComponent("equippable")
end

local function onbroken(inst)
	if inst.components.equippable ~= nil then
		local owner = inst.components.inventoryitem.owner
		if owner then -- FTK MEMES
			if owner.components.talker then
				owner.components.talker:Say(STRINGS.ANNOUNCE_GLASSIC_BROKE, nil, true)
			end
			owner:PushEvent("toolbroke", { tool = inst })
		end
		set_buffed_atks(inst, 0)
		disable_equippable(inst)
		inst.AnimState:PlayAnimation("broken")
		set_isbroken(inst, true)
		inst:AddTag("broken")
		inst.components.inspectable.nameoverride = "BROKEN_FORGEDITEM"
	end
end

local function onrepaired(inst)
	if inst.components.equippable == nil then
		setup_equippable(inst)
		inst.blade1.AnimState:SetFrame(0)
		inst.blade2.AnimState:SetFrame(0)
		inst.AnimState:PlayAnimation("idle", true)
		set_isbroken(inst, false)
		inst:RemoveTag("broken")
		inst.components.inspectable.nameoverride = nil
	end
end

local function charge_with_item(inst, battery, amount)
	amount = amount or 1
	local power = validate_battery_value(inst, battery.prefab, true)
	inst.components.finiteuses:Repair(power * amount)
	set_buffed_atks(inst, inst.buffed_atks + power * amount)
	if inst.isbroken:value() then
		onrepaired(inst)
	end
end

local function cancel_charge_task(inst)
	if inst.try_charge_task then
		inst.try_charge_task:Cancel()
		inst.try_charge_task = nil
	end
end

local function try_charge_task(inst)
	try_consume_battery(inst)
	if not can_consume_battery(inst) then
		cancel_charge_task(inst)
	end
end

local function on_battery_change(inst, data)
	cancel_charge_task(inst)
	if data and data.item then
		if can_consume_battery(inst) then
			inst.try_charge_task = inst:DoPeriodicTask(1, try_charge_task, math.random(30) * FRAMES)
		end
		inst.slotempty:set(false)
	else
		inst.slotempty:set(true)
	end
end

local function onload(inst, data)
	if data then
		if data.buffed_atks then
			set_buffed_atks(inst, data.buffed_atks)
		end
		if data.state ~= nil then -- DO NOT DELETE "~= nil"
			set_lunarstate(inst, data.state)
		end
	end
end

local function onsave(inst, data)
	data.buffed_atks = inst.buffed_atks > 0 and inst.buffed_atks
	data.state = inst.state:value()
end

local function get_status(inst)
	return inst.state:value() and "lunar" or "shadow"
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("lunarshadow")
	inst.AnimState:SetBuild("lunarshadow")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetSymbolBloom("pb_energy_loop01")
	inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", 0.5)
	inst.AnimState:SetLightOverride(0.1)

	inst:SetPrefabName("lunarshadow")

	--weapon (from weapon component) added to pristine state for optimization
	inst:AddTag("weapon")
	inst:AddTag("sharp")
	inst:AddTag("show_broken_ui")

	inst.buffed = net_bool(inst.GUID, "lunarshadow.buffed", "lunarshadow_buffdirty")
	inst.state = net_bool(inst.GUID, "lunarshadow.state", "lunarshadow_statedirty")
	inst.slotempty = net_bool(inst.GUID, "lunarshadow.slotempty", "lunarshadow_slotdirty")

	inst:AddComponent("floater")
	inst.isbroken = net_bool(inst.GUID, "lunarshadow.isbroken", "isbrokendirty")
	set_isbroken(inst, false)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("isbrokendirty", on_isbroken_dirty)
		return inst
	end

	local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
	inst.AnimState:SetFrame(frame)
	inst.blade1 = SpawnPrefab("lunarshadow_blade_fx")
	inst.blade2 = SpawnPrefab("lunarshadow_blade_fx")
	inst.blade2.AnimState:PlayAnimation("swap_loop2", true)
	inst.blade1.AnimState:SetFrame(frame)
	inst.blade2.AnimState:SetFrame(frame)
	set_fx_owner(inst, nil)
	inst:ListenForEvent("floater_stopfloating", on_stop_floating)

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("moonlight_shadow")
	inst.components.container.canbeopened = false

	inst:AddComponent("preserver")
	inst.components.preserver:SetPerishRateMultiplier(0)

	inst:ListenForEvent("itemget", on_battery_change)
	inst:ListenForEvent("itemlose", on_battery_change)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.LUNARSHADOW.USES)
	inst.components.finiteuses:SetUses(TUNING.LUNARSHADOW.USES)
	inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true) -- We handle this ourselfs

	inst.base_damage = TUNING.LUNARSHADOW.BASE_DAMAGE
	inst.buffed_atks = 0

	inst:AddComponent("lunarshadowstate")
	inst:AddComponent("planardamage")
	inst:AddComponent("damagetypebonus")

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = get_status

	inst:AddComponent("inventoryitem")

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(inst._bonusenabled and inst.base_damage * TUNING.LUNARSHADOW.SETBONUS_DAMAGE_MULT or inst.base_damage)
	inst.components.weapon:SetOnAttack(onattack)

	setup_equippable(inst)
	inst.slotempty:set(true)

	MakeForgeRepairable(inst, FORGEMATERIALS.LUNARPLANT, onbroken, onrepaired)
	set_lunar(inst)

	MakeHauntableLaunch(inst)

	inst.SetLunarState = set_lunarstate

	inst.OnSave = onsave
	inst.OnLoad = onload

	inst.ChargeWithItem = charge_with_item

	if rawget(_G, "EncodeDrawNameCode") then
		EncodeDrawNameCode(inst)
	end

	return inst
end

local function fxfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.AnimState:SetBank("lunarshadow")
	inst.AnimState:SetBuild("lunarshadow")
	inst.AnimState:PlayAnimation("swap_loop1", true)
	inst.AnimState:SetSymbolBloom("pb_energy_loop01")
	inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", 0.5)
	inst.AnimState:SetLightOverride(0.1)

	inst:AddComponent("highlightchild")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("colouradder")

	inst.persists = false

	return inst
end

return Prefab("lunarshadow", fn, assets, prefabs), Prefab("lunarshadow_blade_fx", fxfn, assets)
