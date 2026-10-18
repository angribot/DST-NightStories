local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local shadow_accessors = {}

local function GetAccessorPosition(inst, container)
	if not inst:IsValid() or inst:HasTag("burnt") or (inst.components.health ~= nil and inst.components.health:IsDead()) then
		return
	end

	if inst.prefab == "tophat" then
		if inst.components.magiciantool == nil then
			return
		end

		local inventoryitem = inst.components.inventoryitem
		local owner = inventoryitem.owner
		if owner ~= nil then
			local grandowner = inventoryitem:GetGrandOwner()
			local inventory = grandowner ~= nil and grandowner.components.inventory or nil
			if
				inventory ~= nil
				and grandowner:HasTag("player")
				and (owner == grandowner or (owner.components.container ~= nil and inventory:GetOverflowContainer() == owner.components.container))
			then
				return grandowner
			end
		elseif not inst:IsInLimbo() then
			return inst
		end
	else
		local proxy = inst.components.container_proxy
		if proxy ~= nil and proxy:GetMaster() == container and proxy:CanBeOpened() and not inst:IsInLimbo() then
			return inst
		end
	end
end

local function GetWickerBonus(inst)
	for accessor in pairs(shadow_accessors) do
		local position = GetAccessorPosition(accessor, inst)
		if position ~= nil then
			local x, y, z = position.Transform:GetWorldPosition()
			local players = FindPlayersInRange(x, y, z, TUNING.BOOKSTATION_BONUS_RANGE, true)
			for _, player in ipairs(players) do
				if player:HasTag("bookbuilder") then
					return TUNING.BOOKSTATION_WICKER_BONUS
				end
			end
		end
	end
	return 1
end

local function RestoreBooks(inst)
	local amount = TUNING.BOOKSTATION_RESTORE_AMOUNT * GetWickerBonus(inst)
	for _, item in pairs(inst.components.container.slots) do
		if item:HasTag("book") and item.components.finiteuses ~= nil then
			local percent = item.components.finiteuses:GetPercent()
			if percent < 1 then
				item.components.finiteuses:SetPercent(math.min(1, percent + amount))
			end
		end
	end
end

local function UpdateRestoreTask(inst)
	if inst.components.container:HasItemWithTag("book", 1) then
		if inst._ns_bookrestoretask == nil then
			inst._ns_bookrestoretask = inst:DoPeriodicTask(TUNING.BOOKSTATION_RESTORE_TIME, RestoreBooks)
		end
	elseif inst._ns_bookrestoretask ~= nil then
		inst._ns_bookrestoretask:Cancel()
		inst._ns_bookrestoretask = nil
	end
end

local function OnRemoveAccessor(inst)
	shadow_accessors[inst] = nil
end

local function AccessorPostInit(inst)
	if not TheWorld.ismastersim then
		return
	end

	shadow_accessors[inst] = true
	inst:ListenForEvent("onremove", OnRemoveAccessor)
end

AddPrefabPostInit("magician_chest", AccessorPostInit)
AddPrefabPostInit("chester", AccessorPostInit)
-- Magician hats are converted from ordinary top hats after prefab initialization.
AddPrefabPostInit("tophat", AccessorPostInit)

AddPrefabPostInit("shadow_container", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst:ListenForEvent("itemget", UpdateRestoreTask)
	inst:ListenForEvent("itemlose", UpdateRestoreTask)
	UpdateRestoreTask(inst)
end)
