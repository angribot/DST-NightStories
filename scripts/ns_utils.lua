local function get_rate_from_table(t)
	local rate = 0
	local time = GetTime() - 1

	local j = 1
	for i = 1, #t do
		local val = t[i]
		if val.time < time then
			t[i] = nil
		else
			rate = rate + val.amount
			if i ~= j then
				t[j] = val
				t[i] = nil
			end
			j = j + 1
		end
	end

	return rate
end

local function table_insert_rate(t, amount)
	t[#t + 1] = { amount = amount, time = GetTime() }
end

local function get_aura_rate(inst)
	local aura_delta = 0
	local sanity = inst.components.sanity
	if sanity then
		local aura_names = {}
		local function add_aura(source)
			local baseauraname = source.components.sanityaura.baseauraname
			if baseauraname then
				if aura_names[baseauraname] then
					return
				end
				aura_names[baseauraname] = true
			end
			local aura_val = source.components.sanityaura:GetAura(inst)
			aura_val = (aura_val < 0 and (sanity.neg_aura_absorb > 0 and sanity.neg_aura_absorb * -aura_val or aura_val) * sanity:GetAuraMultipliers() or aura_val)
			aura_delta = aura_delta + ((aura_val < 0 and sanity.neg_aura_immune_sources:Get()) and 0 or aura_val)
		end

		if not sanity.sanity_aura_immune_sources:Get() then
			local x, y, z = inst.Transform:GetWorldPosition()
			local ents = TheSim:FindEntities(x, y, z, TUNING.SANITY_AURA_SEACH_RANGE, { "sanityaura" }, { "FX", "NOCLICK", "DECOR", "INLIMBO" })
			for i, v in ipairs(ents) do
				if v.components.sanityaura ~= nil and v ~= inst then
					local is_aura_immune = false
					if sanity.sanity_aura_immunities ~= nil then
						for tag, sources in pairs(sanity.sanity_aura_immunities) do
							if sources:Get() and v:HasTag(tag) then
								is_aura_immune = true
								break
							end
						end
					end

					if not is_aura_immune then
						add_aura(v)
					end
				end
			end
		end

		local mount = inst.components.rider and inst.components.rider:IsRiding() and inst.components.rider:GetMount() or nil
		if mount ~= nil and mount.components.sanityaura ~= nil then
			add_aura(mount)
		end
	end
	return aura_delta < 0 and 0.5 or 2
end

local function owner_testfn(owner)
	return owner ~= nil and (owner.components.health == nil or not owner.components.health:IsDead())
end

local function target_testfn(target)
	if not target then
		return
	end
	if (not TheNet:GetPVPEnabled()) and target:HasTag("player") then
		return
	end
	return target:IsValid()
		and (target.components.health == nil or not target.components.health:IsDead())
		and (target:HasTag("spiderden") or target:HasTag("wooden") or not target:HasTag("structure"))
		and not target:HasTag("wall")
end

local function get_glash(attacker, glash_prefab, enhanced)
	local cache
	local key = enhanced == true and "enhanced" or "normal"
	if glash_prefab == "shadowglash" then
		local tick = GetTick()
		cache = attacker._ns_shadowglash_cache
		if cache == nil or cache.tick ~= tick then
			cache = { tick = tick }
			attacker._ns_shadowglash_cache = cache
		end
		local glash = cache[key]
		if glash ~= nil and glash:IsValid() and not glash._ns_in_attack then
			return glash
		end
	end

	local glash = SpawnPrefab(glash_prefab)
	if glash.SetEnhanced ~= nil then
		glash:SetEnhanced(enhanced)
	end
	glash.entity:SetParent(attacker.entity)
	-- Keep the prefab's next-update removal. Never mutate an in-flight weapon's
	-- enhancement, or share it between attackers or nested damage callbacks.
	if cache ~= nil then
		cache[key] = glash
	end
	return glash
end

local function do_glash_attack(attacker, target, glash_prefab, enhanced)
	local glash = get_glash(attacker, glash_prefab, enhanced)
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

local attack_source

local function restore_attack_source(previous, ok, ...)
	attack_source = previous
	if not ok then
		error((...), 0)
	end
	return ...
end

local function with_attack_source(source, fn, ...)
	local previous = attack_source
	attack_source = source
	-- Restore the outer attack even when a nested attack fails.
	return restore_attack_source(previous, pcall(fn, ...))
end

local function is_attack_source(attacker)
	return attacker ~= nil and attack_source == attacker
end

return {
	GetRateFromTable = get_rate_from_table,
	TableInsertRate = table_insert_rate,
	GetAuraRate = get_aura_rate,
	OwnerTestFn = owner_testfn,
	TargetTestFn = target_testfn,
	DoGlashAttack = do_glash_attack,
	WithAttackSource = with_attack_source,
	IsAttackSource = is_attack_source,
}
