local assets = {
	Asset("ANIM", "anim/blackholestaff.zip"),
}

local prefabs = {

	blackhole = {
		"shadow_puff",
	},
}

---------- BLACKHOLE STAFF ----------

local PICKUP_MUST_TAGS = { "_inventoryitem" }
local PICKUP_CANT_TAGS = {
	"INLIMBO",
	"NOCLICK",
	"irreplaceable",
	"knockbackdelayinteraction",
	"minesprung",
	"mineactive",
	"catchable",
	"fire",
	"spider",
	"cursed",
	"paired",
}
local function pickup(staff, target, pos)
	local caster = staff.components.inventoryitem.owner
	if caster == nil then
		return
	end

	local px, py, pz, prange, t_prefab = 0, 0, 0, 4, nil
	if target == nil and pos ~= nil then
		px, py, pz = pos:Get()
	elseif target == nil and pos == nil then
		px, py, pz = caster.Transform:GetWorldPosition()
	elseif target ~= nil and target == caster then
		px, py, pz = target.Transform:GetWorldPosition()
	elseif target ~= nil and target.components.inventoryitem then
		px, py, pz = target.Transform:GetWorldPosition()
		prange = 28
		t_prefab = target.prefab
	else
		return
	end

	local sanity = caster.components.sanity
	if sanity ~= nil and sanity:GetPercent() >= TUNING.BLACKHOLESTAFF_SANITY_THRESHOLD then
		prange = prange * TUNING.BLACKHOLESTAFF_RANGE_MULT
	end

	local ba = caster:GetBufferedAction()
	local ents = TheSim:FindEntities(px, py, pz, prange, PICKUP_MUST_TAGS, PICKUP_CANT_TAGS)
	--for i=1, #ents do
	for i, v in ipairs(ents) do
		if
			v.components.container == nil -- Containers are most likely sorted and placed by the player do not pick them up.
			and v.components.inventoryitem ~= nil
			and v.components.inventoryitem.canbepickedup
			and v.components.inventoryitem.cangoincontainer
			and not v.components.inventoryitem:IsHeld()
			and (v.components.bait == nil or v.components.bait.trap == nil) -- Do not steal baits.
			and (t_prefab == nil or (v.prefab == t_prefab))
			--local num = v.components.stackable and v.components.stackable.stacksize or 1
			and caster.components.inventory:CanAcceptCount(v, 60) > 0
			and (ba == nil or (ba.action ~= ACTIONS.PICKUP and ba.action ~= ACTIONS.CHECKTRAP) or ba.target ~= v)
		then
			local fx = SpawnPrefab("shadow_puff")
			if fx then
				fx.Transform:SetPosition(v.Transform:GetWorldPosition())
				fx.Transform:SetScale(0.7, 0.7, 0.7)
			end
			if v.components.stackable ~= nil then
				local num = caster.components.inventory:CanAcceptCount(v, 60)
				v = v.components.stackable:Get(num)
			end
			--end

			if v.components.trap and v.components.trap:IsSprung() and v.components.trap:HasLoot() then
				v.components.trap:Harvest(caster)
			else
				caster.components.inventory:GiveItem(v, nil, v:GetPosition())
			end
		end
	end

	if caster.components.sanity ~= nil then
		caster.components.sanity:DoDelta(-TUNING.SANITY_LARGER)
	end
	staff.components.finiteuses:Use(1)
end
---------Can Cast Fn---------
-- local function can_cast_fn(doer, target, pos)
--	 return target and target.components.inventoryitem or target:HasTag("player")
-- end

---------COMMON FUNCTIONS---------
local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function onunequip_skinned(inst, owner)
	if inst:GetSkinBuild() ~= nil then
		owner:PushEvent("unequipskinneditem", inst:GetSkinName())
	end

	onunequip(inst, owner)
end

---------- SPECIFIC FUNC ----------
local function blackhole()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("staffs")
	inst.AnimState:SetBuild("blackholestaff")
	--inst.AnimState:OverrideSymbol("grass", "swap_nightcane", "grass")
	inst.AnimState:PlayAnimation("blackholestaff")
	-- inst.AnimState:SetManualBB(15, -75, 100, 225)

	inst:AddTag("nopunch")
	inst:AddTag("allow_action_on_impassable")

	local swap_data = { sym_build = "blackholestaff", sym_name = "swap_blackholestaff", bank = "staffs", anim = "blackholestaff" }
	MakeInventoryFloatable(inst, "med", 0.1, { 0.9, 0.4, 0.9 }, true, -13, swap_data)

	-- inst.drawatlasoverride = "images/inventoryimages/blackholestaff.xml"
	-- inst.drawimageoverride = "blackholestaff"

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetOnFinished(function(inst)
		inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
		inst:Remove()
	end)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	-- inst.components.inventoryitem.imagename = "blackholestaff"
	-- inst.components.inventoryitem.atlasname = resolvefilepath("images/inventoryimages/blackholestaff.xml")

	inst:AddComponent("tradable")

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(function(inst, owner)
		owner.AnimState:OverrideSymbol("swap_object", "blackholestaff", "swap_blackholestaff")
		owner.AnimState:Show("ARM_carry")
		owner.AnimState:Hide("ARM_normal")
	end)

	inst.components.equippable:SetOnUnequip(onunequip)

	inst.fxcolour = { 1 / 255, 1 / 255, 1 / 255 }

	-- inst.spellfn = pickup
	inst:AddComponent("spellcaster")
	inst.components.spellcaster.canuseonpoint = true
	inst.components.spellcaster.canuseonpoint_water = true
	inst.components.spellcaster.canuseontargets = false
	inst.components.spellcaster.canusefrominventory = true
	inst.components.spellcaster:SetSpellFn(pickup)
	-- inst.components.spellcaster:SetCanCastFn(can_cast_fn)

	inst.components.finiteuses:SetMaxUses(TUNING.BLACKHOLESTAFF_USES)
	inst.components.finiteuses:SetUses(TUNING.BLACKHOLESTAFF_USES)

	MakeHauntableLaunch(inst)

	return inst
end

-- return Prefab("blackholestaff", blackhole, assets, prefabs.blackhole),
--	 Prefab("nightmarestaff", nightmare, assets, prefabs.nightmare)
return Prefab("blackholestaff", blackhole, assets, prefabs.blackhole)
