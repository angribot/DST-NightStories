local Utils = require("nightstories/utils")
local SpDamageUtil = require("components/spdamageutil")

local CHAIN_TAG = "horrorchain"
-- The Horror Chain weapon prefab also carries this tag, so require combat.
local MEMBER_MUST_TAGS = { CHAIN_TAG, "_combat" }

-- Follow-up damage triggered by hits. Its own hits never spread, but a spread
-- hit triggers it on every member like a direct hit would.
local DISABLED_WEAPONS = {
	glash = true,
	shadowglash = true,
	alterguardianhat = true,
}

local DISABLED_ENTITIES = {
	alterguardianhat_projectile = true,
}

local WEAK_KEYS = { __mode = "k" }

local function weak_table()
	return setmetatable({}, WEAK_KEYS)
end

-------------------------------------------------------------------------
-- Membership
-------------------------------------------------------------------------

local function is_member(target)
	return target ~= nil and target.components.horrorchain ~= nil
end

local function add_member(target, duration)
	if not Utils.TargetTestFn(target) then
		return
	end
	local chain = target.components.horrorchain or target:AddComponent("horrorchain")
	chain:SetMinDuration(duration)
end

-- Members within range of a member, excluding the member itself.
local function get_nearby_members(member)
	local members = {}
	if not is_member(member) then
		return members
	end
	local x, y, z = member.Transform:GetWorldPosition()
	for _, ent in ipairs(TheSim:FindEntities(x, y, z, TUNING.HORRORCHAIN_DIST, MEMBER_MUST_TAGS)) do
		if ent ~= member and is_member(ent) then
			members[#members + 1] = ent
		end
	end
	return members
end

local function is_alive(target)
	return target:IsValid() and not target:IsInLimbo() and not (target.components.health ~= nil and target.components.health:IsDead())
end

-------------------------------------------------------------------------
-- Scoped state
-------------------------------------------------------------------------

-- spread_target: the member a spread hit is being replayed on
-- suppressed: hits never spread, e.g. periodic aura ticks
-- boundary: attacks owned by the innermost attack boundary
-- moose_smasher: the Weremoose whose smash is resolving
local state = {}

local function restore_state(key, previous, ok, ...)
	state[key] = previous
	if not ok then
		error((...), 0)
	end
	return ...
end

local function with_state(key, value, fn, ...)
	local previous = state[key]
	state[key] = value
	return restore_state(key, previous, pcall(fn, ...))
end

-------------------------------------------------------------------------
-- Attack identity
--
-- An attack is the damage one attacker deals with one weapon in one tick, so
-- a vanilla area attack that hits each target through its own call is still
-- one attack. Each target takes at most one hit from it, directly or spread.
-- Boundaries separate attacks that deal damage on an owner's behalf and would
-- otherwise share that identity.
-------------------------------------------------------------------------

local NO_WEAPON = {}
local attacks_tick
local tick_attacks

local function get_attack(attacker, weapon)
	local attacks = state.boundary
	if attacks == nil then
		local tick = GetTick()
		if attacks_tick ~= tick then
			attacks_tick = tick
			tick_attacks = weak_table()
		end
		attacks = tick_attacks
	end
	local by_weapon = attacks[attacker]
	if by_weapon == nil then
		by_weapon = weak_table()
		attacks[attacker] = by_weapon
	end
	weapon = weapon or NO_WEAPON
	local attack = by_weapon[weapon]
	if attack == nil then
		-- hits: every target hit; spread: targets hit by spreading
		attack = { hits = weak_table(), spread = weak_table() }
		by_weapon[weapon] = attack
	end
	return attack
end

-------------------------------------------------------------------------
-- Explosive resistance
--
-- Sources that deduct explosive resistance query it, report the resisted
-- damage, then hit with the same source. Recording that lets a spread hit
-- restore the base damage and deduct each member's own resistance instead.
-------------------------------------------------------------------------

local resist_tick
local queried_resistances
local resisted_hits

local function get_resist_records()
	local tick = GetTick()
	if resist_tick ~= tick then
		resist_tick = tick
		queried_resistances = weak_table()
		resisted_hits = weak_table()
	end
end

local function note_resistance(target, resistance)
	get_resist_records()
	queried_resistances[target] = resistance
end

local function note_explosive_damage(target, source)
	get_resist_records()
	local resistance = queried_resistances[target]
	if resistance ~= nil then
		resisted_hits[target] = { source = source, resistance = resistance }
	end
end

-- Returns the resistance deducted from this hit, or nil if none was.
local function take_resistance(target, attacker)
	get_resist_records()
	local record = resisted_hits[target]
	if record == nil then
		return
	end
	resisted_hits[target] = nil
	if record.source == attacker then
		return record.resistance
	end
end

-- Applies and accumulates a target's explosive resistance, as vanilla explosions do.
local function apply_explosive_resist(target, damage, source)
	local explosiveresist = target.components.explosiveresist
	if explosiveresist == nil then
		return damage
	end
	damage = damage * (1 - explosiveresist:GetResistance())
	explosiveresist:OnExplosiveDamage(damage, source)
	return damage
end

-------------------------------------------------------------------------
-- Call frames
--
-- Combat calls push frames so a hit knows which call produced it, and so
-- damage dealt back to an attacker mid-hit is recognized as retaliation.
-------------------------------------------------------------------------

local frames = {}

local function push_frame(frame)
	frames[#frames + 1] = frame
end

local function pop_frame(ok, ...)
	frames[#frames] = nil
	if not ok then
		error((...), 0)
	end
	return ...
end

-- Synchronous retaliation: the victim is hitting back at whoever is hitting it.
local function is_retaliation(victim, attacker)
	for i = #frames, 1, -1 do
		local frame = frames[i]
		if frame.victim == attacker and frame.attacker == victim then
			return true
		end
	end
	return false
end

-- The combat call that produced this hit, or nil for redirected damage.
local function get_producing_frame(combat, attacker)
	local frame = frames[#frames]
	if frame == nil or frame.attacker ~= attacker then
		return
	elseif frame.kind == "area" then
		return combat.inst ~= attacker and frame or nil
	elseif frame.kind == "attack" or frame.kind == "attacked" then
		return combat.inst == frame.victim and frame or nil
	end
end

-------------------------------------------------------------------------
-- Anchors
--
-- An anchor is a chain member hit directly. Spreading replays the hit that
-- produced it on each nearby member through the same kind of call, so the hit
-- keeps its special effects and computes damage for each member.
-------------------------------------------------------------------------

local AttackAnchor = {}
AttackAnchor.__index = AttackAnchor

function AttackAnchor:CanHit(member)
	local attacker = self.combat.inst
	local weapon = self.weapon
	return attacker:IsValid()
		and is_alive(member)
		and member.components.combat ~= nil
		and member.components.combat:CanBeAttacked(attacker)
		and (weapon == nil or (weapon:IsValid() and weapon.components.weapon ~= nil))
end

-- Weremoose smash adds its planar bonus only against planar targets, and a
-- tackle multiplies damage only against the structure it collides with.
local function adapt_to_member(anchor, member)
	local attacker = anchor.combat.inst
	local restores = {}

	local multipliers = anchor.combat.externaldamagemultipliers
	if multipliers:HasModifier(attacker, "tackler") then
		local tackle = multipliers:CalculateModifierFromSource(attacker, "tackler")
		multipliers:RemoveModifier(attacker, "tackler")
		restores[#restores + 1] = function()
			multipliers:SetModifier(attacker, tackle, "tackler")
		end
	end

	local planardamage = anchor.moose_smash and attacker.components.planardamage or nil
	if planardamage ~= nil then
		local bonuses = planardamage.externalbonuses
		local bonus = bonuses:HasModifier(attacker, "weremoose_smash") and bonuses:CalculateModifierFromSource(attacker, "weremoose_smash") or nil
		if member.components.planarentity ~= nil then
			planardamage:AddBonus(attacker, TUNING.SKILLS.WOODIE.MOOSE_SMASH_PLANAR_DAMAGE, "weremoose_smash")
		else
			planardamage:RemoveBonus(attacker, "weremoose_smash")
		end
		restores[#restores + 1] = function()
			if bonus ~= nil then
				planardamage:AddBonus(attacker, bonus, "weremoose_smash")
			else
				planardamage:RemoveBonus(attacker, "weremoose_smash")
			end
		end
	end

	return restores
end

local function restore_attack(combat, ignorehitrange, finiteuses, ignoreloss, restores, ok, ...)
	for i = #restores, 1, -1 do
		restores[i]()
	end
	if finiteuses ~= nil then
		finiteuses.ignorecombatdurabilityloss = ignoreloss
	end
	combat.ignorehitrange = ignorehitrange
	if not ok then
		error((...), 0)
	end
end

function AttackAnchor:Hit(member)
	local combat = self.combat
	-- Range is measured from the anchor, which the attack already reached.
	local ignorehitrange = combat.ignorehitrange
	combat.ignorehitrange = true
	-- One launch uses durability once; the projectile only flew to the anchor.
	local finiteuses = self.projectile ~= nil and self.weapon ~= nil and self.weapon.components.finiteuses or nil
	local ignoreloss
	if finiteuses ~= nil then
		ignoreloss = finiteuses.ignorecombatdurabilityloss
		finiteuses.ignorecombatdurabilityloss = true
	end
	local restores = adapt_to_member(self, member)
	restore_attack(combat, ignorehitrange, finiteuses, ignoreloss, restores, pcall(combat.DoAttack, combat, member, self.weapon, self.projectile, self.stimuli, self.instancemult))
end

local AreaAnchor = {}
AreaAnchor.__index = AreaAnchor

function AreaAnchor:CanHit(member)
	local combat = self.combat
	local attacker = combat.inst
	return attacker:IsValid()
		and member.components.combat ~= nil
		and combat:IsValidTarget(member)
		and not (self.excludetags ~= nil and member:HasAnyTag(self.excludetags))
		and (self.validfn == nil or self.validfn(member, attacker))
end

-- Mirrors one target of Combat:DoAreaAttack.
function AreaAnchor:Hit(member)
	local combat = self.combat
	local attacker = combat.inst
	Utils.WithAttackSource(attacker, function()
		attacker:PushEvent("onareaattackother", { target = member, weapon = self.weapon, stimuli = self.stimuli })
		local damage, spdamage = combat:CalcDamage(member, self.weapon, combat.areahitdamagepercent)
		member.components.combat:GetAttacked_Internal(attacker, damage, self.weapon, self.stimuli, spdamage, true)
	end)
end

local AttackedAnchor = {}
AttackedAnchor.__index = AttackedAnchor

function AttackedAnchor:CanHit(member)
	local attacker = self.attacker
	return attacker:IsValid() and is_alive(member) and member.components.combat ~= nil and member.components.combat:CanBeAttacked(attacker)
end

function AttackedAnchor:Hit(member)
	local damage = self.damage
	if self.resist then
		damage = apply_explosive_resist(member, damage, self.attacker)
	end
	member.components.combat:GetAttacked(self.attacker, damage, self.weapon, self.stimuli, self.spdamage)
end

local ExplosionAnchor = {}
ExplosionAnchor.__index = ExplosionAnchor

function ExplosionAnchor:CanHit(member)
	local bomb = self.bomb
	local explosive = bomb.components.explosive
	return bomb:IsValid()
		and explosive ~= nil
		and is_alive(member)
		and member.components.combat ~= nil
		and member.components.combat:CanBeAttacked()
		and (explosive.pvpattacker == nil or member == explosive.pvpattacker or not member.isplayer)
end

function ExplosionAnchor:Hit(member)
	local bomb = self.bomb
	local explosive = bomb.components.explosive
	-- Calculate fresh damage for each target's alignment bonus and defenses.
	local stacksize = bomb.components.stackable ~= nil and bomb.components.stackable:StackSize() or 1
	local mult = bomb.components.damagetypebonus ~= nil and bomb.components.damagetypebonus:GetBonus(member) or 1
	local damage = apply_explosive_resist(member, explosive.explosivedamage * stacksize * mult, bomb)
	local spdamage = SpDamageUtil.ApplyMult(SpDamageUtil.CollectSpDamage(bomb), mult * stacksize)
	member.components.combat:GetAttacked(bomb, damage, nil, nil, spdamage)

	local attacker = explosive.attacker or explosive.pvpattacker
	if
		attacker ~= nil
		and attacker:IsValid()
		and member:IsValid()
		and member.components.combat ~= nil
		and not (member.components.health ~= nil and member.components.health:IsDead())
	then
		member.components.combat:SuggestTarget(attacker)
	end
end

local function can_spread_from(attacker, weapon)
	return (attacker.components.combat ~= nil or attacker.components.explosive ~= nil)
		and not DISABLED_ENTITIES[attacker.prefab]
		and not (weapon ~= nil and DISABLED_WEAPONS[weapon.prefab])
end

-- Capture members before a lethal hit removes the anchor's chain membership.
local function create_anchor(frame, attack, target, attacker, damage, weapon, stimuli, spdamage, resistance)
	local members = get_nearby_members(target)
	for i = #members, 1, -1 do
		if members[i] == attacker then
			table.remove(members, i)
		end
	end
	if members[1] == nil then
		return
	end

	local anchor
	if frame.kind == "attack" then
		anchor = setmetatable({
			combat = frame.combat,
			weapon = weapon,
			projectile = frame.projectile,
			stimuli = stimuli,
			instancemult = frame.instancemult,
			moose_smash = state.moose_smasher == attacker,
		}, AttackAnchor)
	elseif frame.kind == "area" then
		anchor = setmetatable({
			combat = frame.combat,
			weapon = weapon,
			stimuli = stimuli,
			validfn = frame.validfn,
			excludetags = frame.excludetags,
		}, AreaAnchor)
	elseif attacker.components.explosive ~= nil then
		anchor = setmetatable({ bomb = attacker }, ExplosionAnchor)
	else
		-- A fully resisted anchor took no damage, so its base damage is
		-- unknown and the hit does not spread.
		if resistance ~= nil and resistance >= 1 then
			return
		end
		anchor = setmetatable({
			attacker = attacker,
			damage = (damage or 0) / (1 - (resistance or 0)),
			resist = resistance ~= nil,
			weapon = weapon,
			stimuli = stimuli,
			spdamage = spdamage,
		}, AttackedAnchor)
	end
	anchor.attack = attack
	anchor.members = members
	return anchor
end

-- Replays the anchor's hit on each nearby member not hit by this attack yet.
local function spread_members(anchor)
	local attack = anchor.attack
	for _, member in ipairs(anchor.members) do
		if not attack.hits[member] and member:IsValid() and anchor:CanHit(member) then
			attack.hits[member] = true
			attack.spread[member] = true
			with_state("spread_target", member, anchor.Hit, anchor, member)
		end
	end
end

local function spread(anchors)
	for _, anchor in ipairs(anchors) do
		spread_members(anchor)
	end
end

-------------------------------------------------------------------------
-- Combat entry points, called by the Combat hooks
-------------------------------------------------------------------------

-- Anchors from a call spread once the call has resolved its own hits, so a
-- weapon cannot break between dealing damage and its OnAttack.
local function finish_call(frame, ok, ...)
	frames[#frames] = nil
	if not ok then
		error((...), 0)
	end
	spread(frame.anchors)
	return ...
end

local function run_call(frame, fn, ...)
	frame.anchors = {}
	push_frame(frame)
	return finish_call(frame, pcall(fn, ...))
end

local function do_attack(combat, target, weapon, projectile, instancemult, fn, ...)
	local attacker = combat.inst
	weapon = weapon or combat:GetWeapon()
	-- The target already took this attack through spreading.
	if target ~= nil and target ~= state.spread_target and get_attack(attacker, weapon).spread[target] then
		return
	end
	return run_call({
		kind = "attack",
		combat = combat,
		attacker = attacker,
		victim = target,
		projectile = projectile,
		instancemult = instancemult,
	}, fn, ...)
end

local function do_area_attack(combat, validfn, excludetags, fn, ...)
	return run_call({
		kind = "area",
		combat = combat,
		attacker = combat.inst,
		validfn = validfn,
		excludetags = excludetags,
	}, fn, ...)
end

local function get_attacked(combat, attacker, fn, ...)
	return run_call({
		kind = "attacked",
		combat = combat,
		attacker = attacker,
		victim = combat.inst,
	}, fn, ...)
end

-- Projectile anchors spread right after their hit: they cannot break the
-- weapon, and the projectile may be removed before its DoAttack returns.
local function finish_hit(frame, anchor, ok, ...)
	frames[#frames] = nil
	if not ok then
		error((...), 0)
	end
	if anchor ~= nil then
		if anchor.projectile ~= nil then
			spread_members(anchor)
		else
			frame.anchors[#frame.anchors + 1] = anchor
		end
	end
	return ...
end

local function get_attacked_internal(combat, attacker, damage, weapon, stimuli, spdamage, fn, ...)
	-- Damage without an attacker, such as darkness, never spreads.
	if attacker == nil then
		return fn(...)
	end
	local target = combat.inst
	local resistance = take_resistance(target, attacker)
	local hit_frame = { attacker = attacker, victim = target }
	-- Suppressed hits are not part of any attack, so they cannot block one.
	if state.suppressed then
		push_frame(hit_frame)
		return pop_frame(pcall(fn, ...))
	end
	local attack = get_attack(attacker, weapon)

	if state.spread_target ~= nil then
		-- Damage nested in a spread hit may only reach the member it is aimed
		-- at among the targets this attack already hit.
		if target ~= state.spread_target and attack.hits[target] then
			return false
		end
		attack.hits[target] = true
		attack.spread[target] = true
		push_frame(hit_frame)
		return pop_frame(pcall(fn, ...))
	end

	-- The target already took this attack through spreading.
	if attack.spread[target] then
		return false
	end

	local frame, anchor
	if not attack.hits[target] then
		attack.hits[target] = true
		frame = get_producing_frame(combat, attacker)
		if frame ~= nil and is_member(target) and is_alive(target) and can_spread_from(attacker, weapon) and not is_retaliation(target, attacker) then
			anchor = create_anchor(frame, attack, target, attacker, damage, weapon, stimuli, spdamage, resistance)
		end
	end

	push_frame(hit_frame)
	return finish_hit(frame, anchor, pcall(fn, ...))
end

-------------------------------------------------------------------------
-- Scopes, called by source hooks
-------------------------------------------------------------------------

local function suppress(fn, ...)
	return with_state("suppressed", true, fn, ...)
end

local function run_boundary(fn, ...)
	return with_state("boundary", weak_table(), fn, ...)
end

local function run_moose_smash(inst, fn, ...)
	return with_state("moose_smasher", inst, fn, inst, ...)
end

return {
	AddMember = add_member,
	GetNearbyMembers = get_nearby_members,
	DoAttack = do_attack,
	DoAreaAttack = do_area_attack,
	GetAttacked = get_attacked,
	GetAttackedInternal = get_attacked_internal,
	NoteResistance = note_resistance,
	NoteExplosiveDamage = note_explosive_damage,
	Suppress = suppress,
	RunBoundary = run_boundary,
	RunMooseSmash = run_moose_smash,
}
