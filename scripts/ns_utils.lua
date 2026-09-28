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

local function do_glash_attack(attacker, target, glash_prefab)
	local glash = SpawnPrefab(glash_prefab)
	glash.entity:SetParent(attacker.entity)
	local damagemultiplier = attacker.components.combat.damagemultiplier
	attacker.components.combat.damagemultiplier = math.max(1, (damagemultiplier or 1))
	attacker.components.combat:DoAttack(target, glash, glash)
	attacker.components.combat.damagemultiplier = damagemultiplier
end

local function launching_projectile(data)
	return data.weapon ~= nil
		and data.projectile == nil
		and (data.weapon.components.projectile ~= nil or data.weapon.components.complexprojectile ~= nil or data.weapon.components.weapon:CanRangedAttack())
end

return {
	GetRateFromTable = get_rate_from_table,
	TableInsertRate = table_insert_rate,
	GetAuraRate = get_aura_rate,
	OwnerTestFn = owner_testfn,
	TargetTestFn = target_testfn,
	DoGlashAttack = do_glash_attack,
	LaunchingProjectile = launching_projectile,
}
