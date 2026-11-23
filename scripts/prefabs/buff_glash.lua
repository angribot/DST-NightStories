local Utils = require("nightstories/utils")

-------------------------------------------------------------------------
-------------------------- moonlight functions --------------------------
-------------------------------------------------------------------------

local TARGET_NOT_TAGS = { "balloon", "smashable", "deck_of_cards" }

local function owner_testfn(owner)
	return owner ~= nil and (owner.components.health == nil or not owner.components.health:IsDead())
end

local GLASH_MELEE_TARGETS = {
	charlie_boss = true,
}

local function get_glash(attacker, glash_prefab, enhanced)
	local tick = GetTick()
	local cache = attacker._ns_glash_cache
	if cache == nil or cache.tick ~= tick then
		cache = { tick = tick, weapons = {} }
		attacker._ns_glash_cache = cache
	end
	local weapons = cache.weapons[glash_prefab]
	if weapons == nil then
		weapons = {}
		cache.weapons[glash_prefab] = weapons
	end
	local key = enhanced == true and "enhanced" or "normal"
	local cached = weapons[key]
	-- Never reuse a glash mid-attack, e.g. from nested damage callbacks.
	if cached ~= nil and cached:IsValid() and not cached._ns_in_attack then
		return cached
	end

	local glash = SpawnPrefab(glash_prefab)
	if glash.SetEnhanced ~= nil then
		glash:SetEnhanced(enhanced)
	end
	glash.entity:SetParent(attacker.entity)
	weapons[key] = glash
	return glash
end

local function do_glash_attack(attacker, target, glash_prefab, enhanced)
	local glash = get_glash(attacker, glash_prefab, enhanced)
	glash:AddOrRemoveTag("pseudorangedweapon", not GLASH_MELEE_TARGETS[target.prefab])

	local combat = attacker.components.combat
	local damagemultiplier = combat.damagemultiplier
	combat.damagemultiplier = math.max(1, (damagemultiplier or 1))
	glash._ns_in_attack = true
	local ok, err = pcall(combat.DoAttack, combat, target, glash, glash)
	glash._ns_in_attack = nil
	combat.damagemultiplier = damagemultiplier
	if not ok then
		error(err, 0)
	end
end

local function target_testfn(target)
	return Utils.TargetTestFn(target) and not target:HasAnyTag(TARGET_NOT_TAGS)
end

local function base_onhitother(owner, data, glash_prefab, enhanced)
	-- Vanilla components/combat.lua:Combat:DoAttack (762172): sends reflected damage as a from_doattack hit by the defender
	if not (data and data.from_doattack) or data.redirected or not Utils.IsAttackSource(owner) then
		return
	end
	local target = data.target
	local weapon = data.weapon
	if weapon and weapon:HasTag("glash") then
		return
	end
	if owner_testfn(owner) and target and target ~= owner and target_testfn(target) then
		do_glash_attack(owner, target, glash_prefab, enhanced)
	end
end

local function onhitother(owner, data)
	base_onhitother(owner, data, "glash")
end

local function onhitother_shadow(owner, data)
	local buff = owner:GetDebuff("buff_shadowglash")
	base_onhitother(owner, data, "shadowglash", buff ~= nil and buff.enhanced)
end

local function attack_attach(inst, target)
	if target.components.combat then
		inst:ListenForEvent("onhitother", onhitother, target)
	end
end

local function attack_detach(inst, target)
	inst:RemoveEventCallback("onhitother", onhitother, target)
end

local function extend_shadow(inst, target, data)
	if data ~= nil then
		inst.enhanced = data.enhanced == true
	end
end

local function attack_attach_shadow(inst, target, data)
	extend_shadow(inst, target, data)
	if target.components.combat then
		inst:ListenForEvent("onhitother", onhitother_shadow, target)
	end
end

local function attack_detach_shadow(inst, target)
	inst:RemoveEventCallback("onhitother", onhitother_shadow, target)
end

-------------------------------------------------------------------------
----------------------- Prefab building functions -----------------------
-------------------------------------------------------------------------

local function OnTimerDone(inst, data)
	if data.name == "buffover" then
		inst.components.debuff:Stop()
	end
end

local function MakeBuff(name, onattachedfn, onextendedfn, ondetachedfn, duration, priority, prefabs, oninitfn)
	local function OnAttached(inst, target, followsymbol, followoffset, data)
		inst.entity:SetParent(target.entity)
		inst.Transform:SetPosition(0, 0, 0) --in case of loading
		inst:ListenForEvent("death", function()
			inst.components.debuff:Stop()
		end, target)

		target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_" .. string.upper(name), priority = priority })
		if onattachedfn ~= nil then
			onattachedfn(inst, target, data)
		end
	end

	local function OnExtended(inst, target, followsymbol, followoffset, data)
		inst.components.timer:StopTimer("buffover")
		inst.components.timer:StartTimer("buffover", duration)

		target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_" .. string.upper(name), priority = priority })
		if onextendedfn ~= nil then
			onextendedfn(inst, target, data)
		end
	end

	local function OnDetached(inst, target)
		if ondetachedfn ~= nil then
			ondetachedfn(inst, target)
		end

		target:PushEvent("foodbuffdetached", { buff = "ANNOUNCE_DETACH_BUFF_" .. string.upper(name), priority = priority })
		inst:Remove()
	end

	local function fn()
		local inst = CreateEntity()

		if not TheWorld.ismastersim then
			-- Not meant for client!
			inst:DoTaskInTime(0, inst.Remove)
			return inst
		end

		inst.entity:AddTransform()

		--[[Non-networked entity]]
		--inst.entity:SetCanSleep(false)
		inst.entity:Hide()
		inst.persists = false

		inst:AddTag("CLASSIFIED")

		inst:AddComponent("debuff")
		inst.components.debuff:SetAttachedFn(OnAttached)
		inst.components.debuff:SetDetachedFn(OnDetached)
		inst.components.debuff:SetExtendedFn(OnExtended)
		inst.components.debuff.keepondespawn = true

		inst:AddComponent("timer")
		inst.components.timer:StartTimer("buffover", duration)
		inst:ListenForEvent("timerdone", OnTimerDone)

		if oninitfn ~= nil then
			oninitfn(inst)
		end

		return inst
	end

	return Prefab("buff_" .. name, fn, nil, prefabs)
end

local function shadow_onsave(inst, data)
	data.enhanced = inst.enhanced
end

local function shadow_onload(inst, data)
	inst.enhanced = data ~= nil and data.enhanced == true
end

local function shadow_init(inst)
	inst.enhanced = false
	-- Vanilla components/debuffable.lua:Debuffable:OnSave (762172): saves every debuff, even non-persistent ones
	inst.OnSave = shadow_onsave
	inst.OnLoad = shadow_onload
end

return MakeBuff("glash", attack_attach, nil, attack_detach, TUNING.BUFF_GLASH_DURATION, 1),
	MakeBuff("shadowglash", attack_attach_shadow, extend_shadow, attack_detach_shadow, TUNING.BUFF_SHADOWGLASH_DURATION, 1, nil, shadow_init)
