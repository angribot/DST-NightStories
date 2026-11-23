local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function OnUpdateDapperness(owner)
	local inst = owner and owner.components.inventory and owner.components.inventory.equipslots and owner.components.inventory.equipslots[EQUIPSLOTS.HEAD]
	-- if inst.components.equippable == nil then return end
	if inst then
		if inst.lunarseedsmaxed then
			local _, jewel_count = inst.components.container:Has("lunar_seed", 5)
			inst.components.equippable.dapperness = TUNING.LUNAR_SEED_DAPPERNESS * jewel_count
		else
			inst.components.equippable.dapperness = -TUNING.CRAZINESS_SMALL
		end
	end
end

AddPrefabPostInit("alterguardianhat", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	if inst.components.equippable then
		local onequip = inst.components.equippable.onequipfn
		local onunequip = inst.components.equippable.onunequipfn
		local spawn_gestalt

		inst.components.equippable:SetOnEquip(function(_inst, _owner)
			onequip(_inst, _owner)
			if spawn_gestalt == nil then
				spawn_gestalt = inst.alterguardian_spawngestalt_fn
				inst:RemoveEventCallback("onhitother", spawn_gestalt, _owner)
				-- Vanilla prefabs/hats.lua:alterguardian_onequip (762172): reuses inst.alterguardian_spawngestalt_fn, which alterguardian_onunequip removes
				inst.alterguardian_spawngestalt_fn = function(__owner, __data)
					if not (__owner.components.debuffable and __owner.components.debuffable:HasDebuff("buff_glash"))
						and not (__data and __data.weapon and __data.weapon:HasTag("glash")) then
						return spawn_gestalt(__owner, __data)
					end
				end
				inst:ListenForEvent("onhitother", inst.alterguardian_spawngestalt_fn, _owner)
			end
			inst:ListenForEvent("sanitydelta", OnUpdateDapperness, _owner)
		end)

		inst.components.equippable:SetOnUnequip(function(_inst, _owner)
			onunequip(_inst, _owner)
			inst:RemoveEventCallback("sanitydelta", OnUpdateDapperness, _owner)
		end)
	end
end)
