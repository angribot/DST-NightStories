local HorrorChainUtil = require("nightstories/horrorchainutil")

local assets = {
	Asset("ANIM", "anim/horrorchain.zip"),
}

local function set_buff_enabled(inst, enabled)
	if enabled then
		if not inst._bonusenabled then
			inst._bonusenabled = true
			if inst.components.weapon then
				inst.components.weapon:SetDamage(TUNING.HORRORCHAIN_DAMAGE * TUNING.WEAPONS_VOIDCLOTH_SETBONUS_DAMAGE_MULT)
			end
			inst.components.planardamage:AddBonus(inst, TUNING.WEAPONS_VOIDCLOTH_SETBONUS_PLANAR_DAMAGE, "setbonus")
		end
	elseif inst._bonusenabled then
		inst._bonusenabled = nil
		if inst.components.weapon then
			inst.components.weapon:SetDamage(TUNING.HORRORCHAIN_DAMAGE)
		end
		inst.components.planardamage:RemoveBonus(inst, "setbonus")
	end
end

local function set_buff_owner(inst, owner)
	if inst._owner ~= owner then
		if inst._owner then
			inst:RemoveEventCallback("equip", inst._onownerequip, inst._owner)
			inst:RemoveEventCallback("unequip", inst._onownerunequip, inst._owner)
			inst._onownerequip = nil
			inst._onownerunequip = nil
			set_buff_enabled(inst, false)
		end
		inst._owner = owner
		if owner then
			inst._onownerequip = function(owner, data)
				if data then
					if data.item and data.item.prefab == "voidclothhat" then
						set_buff_enabled(inst, true)
					elseif data.eslot == EQUIPSLOTS.HEAD then
						set_buff_enabled(inst, false)
					end
				end
			end
			inst._onownerunequip = function(owner, data)
				if data and data.eslot == EQUIPSLOTS.HEAD then
					set_buff_enabled(inst, false)
				end
			end
			inst:ListenForEvent("equip", inst._onownerequip, owner)
			inst:ListenForEvent("unequip", inst._onownerunequip, owner)

			local hat = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
			if hat and hat.prefab == "voidclothhat" then
				set_buff_enabled(inst, true)
			end
		end
	end
end

local function onequip(inst, owner)
	local skin_build = inst:GetSkinBuild()
	if skin_build then
		owner:PushEvent("equipskinneditem", inst:GetSkinName())
		owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_chain", inst.GUID, "swap_chain")
		owner.AnimState:OverrideItemSkinSymbol("whipline", skin_build, "chainline", inst.GUID, "swap_chain")
	else
		owner.AnimState:OverrideSymbol("swap_object", "horrorchain", "swap_chain")
		owner.AnimState:OverrideSymbol("whipline", "horrorchain", "chainline")
	end
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
	set_buff_owner(inst, owner)
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
	local skin_build = inst:GetSkinBuild()
	if skin_build then
		owner:PushEvent("unequipskinneditem", inst:GetSkinName())
	end
	set_buff_owner(inst, nil)
end

local function get_bonus_mult(inst)
	local mult = inst._bonusenabled and 1.5 or 1
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if owner and owner.prefab == "dummy" then
		mult = mult + 0.5
	end
	return mult
end

local hitsparks_fx_colouroverride = { 1, 0, 0 }
local function onattack(inst, attacker, target)
	if target and target:IsValid() then
		-- Hit Sound
		if target.SoundEmitter then
			target.SoundEmitter:PlaySound(inst.skin_atk_sound or "wanda2/characters/wanda/watch/weapon/shadow_hit_old")
		end
		-- chain_target
		HorrorChainUtil.AddMember(target, TUNING.HORRORCHAIN_DRUATION * get_bonus_mult(inst))
		-- target hit fx
		local spark = SpawnPrefab("hitsparks_fx")
		spark:Setup(attacker, target, nil, hitsparks_fx_colouroverride)
		spark.black:set(true)
	end
end

local function disable_components(inst)
	inst:RemoveComponent("equippable")
	inst:RemoveComponent("weapon")
end

local function setup_components(inst)
	inst:AddComponent("equippable")
	inst.components.equippable.dapperness = -TUNING.DAPPERNESS_MED
	inst.components.equippable.is_magic_dapperness = true
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(inst._bonusenabled and TUNING.HORRORCHAIN_DAMAGE * TUNING.WEAPONS_VOIDCLOTH_SETBONUS_DAMAGE_MULT or TUNING.HORRORCHAIN_DAMAGE)
	inst.components.weapon:SetRange(TUNING.HORRORCHAIN_RANGE)
	inst.components.weapon:SetOnAttack(onattack)
end

local function on_broken(inst)
	if inst.components.equippable then
		disable_components(inst)
		-- inst.AnimState:PlayAnimation("broken")
		-- SetIsBroken(inst, true)
		inst:AddTag("broken")
		inst.components.inspectable.nameoverride = "BROKEN_FORGEDITEM"
	end
end

local function on_repaired(inst)
	if inst.components.equippable == nil then
		setup_components(inst)
		inst.AnimState:PlayAnimation("idle")
		-- SetIsBroken(inst, false)
		inst:RemoveTag("broken")
		inst.components.inspectable.nameoverride = nil
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	-- inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("horrorchain")
	inst.AnimState:SetBuild("horrorchain")
	inst.AnimState:PlayAnimation("idle")

	-- inst:AddTag("chain_horror") -- ?
	inst:AddTag("shadow_item")
	inst:AddTag("show_broken_ui")

	inst:AddTag("whip") -- ATK SG
	--weapon (from weapon component) added to pristine state for optimization
	inst:AddTag("weapon")

	--shadowlevel (from shadowlevel component) added to pristine state for optimization
	inst:AddTag("shadowlevel")

	MakeInventoryFloatable(inst, "med", nil, 0.9)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.HORRORCHAIN_USES)
	inst.components.finiteuses:SetUses(TUNING.HORRORCHAIN_USES)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")

	inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.HORRORCHAIN_PLANAR_DAMAGE)

	inst:AddComponent("damagetypebonus")
	inst.components.damagetypebonus:AddBonus("lunar_aligned", inst, TUNING.WEAPONS_VOIDCLOTH_VS_LUNAR_BONUS)

	setup_components(inst)

	inst:AddComponent("shadowlevel")
	inst.components.shadowlevel:SetDefaultLevel(TUNING.HORRORCHAIN_SHADOW_LEVEL)

	MakeForgeRepairable(inst, FORGEMATERIALS.VOIDCLOTH, on_broken, on_repaired)
	-- inst.components.finiteuses:SetOnFinished(on_broken)

	MakeHauntableLaunch(inst)

	return inst
end

local function fx_fn() end

return Prefab("horrorchain", fn, assets)
