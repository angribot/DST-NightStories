local Utils = require("nightstories/utils")
local SpDamageUtil = require("components/spdamageutil")

local CHAIN_TAG = "horrorchain"
-- The Horror Chain weapon prefab also carries this tag, so require combat.
local MEMBER_MUST_TAGS = { CHAIN_TAG, "_combat" }

local DISABLED_WEAPONS = {
	glash = true,
	shadowglash = true,
	alterguardianhat = true,
}

local DISABLED_ENTITIES = {
	alterguardianhat_projectile = true,
}

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

-------------------------------------------------------------------------
-- Attack scopes
--
-- A scope is one logical attack within a single frame. Every target it
-- damages is recorded once. Chain members hit directly become anchors; once
-- the attack's own hits resolve, each anchor replays the hit on nearby
-- members not yet damaged. Contexts nest inside the scope and flush their
-- own anchors on exit. Multi-frame attacks start a new scope every frame.
-------------------------------------------------------------------------

local scope
local contexts = {}

local function propagate(ctx)
	local anchors = ctx.anchors
	local i = ctx.flushed + 1
	while anchors[i] ~= nil do
		local anchor = anchors[i]
		ctx.flushed = i
		for _, member in ipairs(anchor.members) do
			if not scope.hits[member] and anchor:CanHit(member) then
				scope.hits[member] = true
				scope.propagating = member
				anchor:Hit(member)
				scope.propagating = true
			end
		end
		i = i + 1
	end
end

local function flush(ctx)
	if ctx.anchors[ctx.flushed + 1] == nil then
		return
	end
	local previous = scope.propagating
	scope.propagating = true
	local ok, err = pcall(propagate, ctx)
	scope.propagating = previous
	if not ok then
		error(err, 0)
	end
end

-- Flush before the source entity is removed so replays still see it valid.
local function intercept_remove(ctx, inst)
	local own = rawget(inst, "Remove")
	ctx.restore_remove = function()
		if rawget(inst, "Remove") == ctx.remove_interceptor then
			inst.Remove = own
		end
		ctx.restore_remove = nil
	end
	ctx.remove_interceptor = function(...)
		ctx.restore_remove()
		local ok, err = pcall(flush, ctx)
		inst:Remove(select(2, ...))
		if not ok then
			error(err, 0)
		end
	end
	inst.Remove = ctx.remove_interceptor
end

local function finish(ctx, owns_scope, ok, ...)
	if ctx.restore_remove ~= nil then
		ctx.restore_remove()
	end
	local flush_ok, flush_err = true, nil
	if ok then
		flush_ok, flush_err = pcall(flush, ctx)
	end
	contexts[#contexts] = nil
	if owns_scope then
		scope = nil
	end
	if not ok then
		error((...), 0)
	elseif not flush_ok then
		error(flush_err, 0)
	end
	return ...
end

-- Runs fn as one attack, or as part of the attack already in progress.
-- opts (all optional):
--   attacked: let combat:GetAttacked hits become anchors
--   resist: record explosive resistance to rescale replayed damage
--   explosive: replay hits as this explosive's damage
--   flush_on_remove: flush before this entity is removed
--   suppress: never create anchors, e.g. periodic aura ticks
local function run(opts, fn, ...)
	local owns_scope = scope == nil
	if owns_scope then
		scope = { hits = {} }
	end

	local parent = contexts[#contexts]
	local ctx = {
		anchors = {},
		flushed = 0,
		attacked = opts.attacked,
		resist = opts.resist,
		explosive = opts.explosive,
		suppress = opts.suppress or (parent ~= nil and parent.suppress),
	}
	contexts[#contexts + 1] = ctx
	if opts.flush_on_remove ~= nil then
		intercept_remove(ctx, opts.flush_on_remove)
	end
	return finish(ctx, owns_scope, pcall(fn, ...))
end

local NO_OPTS = {}

-- Combat calls join the open attack, or start a single-call attack.
local function join(fn, ...)
	if contexts[1] ~= nil then
		return fn(...)
	end
	return run(NO_OPTS, fn, ...)
end

-- Records a hit and returns the context that should own its anchor.
-- Only a target's first hit in the scope can become an anchor.
local function claim(target)
	local ctx = contexts[#contexts]
	if ctx == nil or ctx.suppress or scope.hits[target] then
		return
	end
	scope.hits[target] = true
	if scope.propagating == nil then
		return ctx
	end
end

local function note_resistance(target, resistance)
	local ctx = contexts[#contexts]
	if ctx ~= nil and ctx.resist then
		ctx.resistances = ctx.resistances or {}
		ctx.resistances[target] = resistance
	end
end

-------------------------------------------------------------------------
-- Combat frames tell GetAttacked_Internal which call produced a hit.
-------------------------------------------------------------------------

local frames = {}

local function pop_frame(ok, ...)
	frames[#frames] = nil
	if not ok then
		error((...), 0)
	end
	return ...
end

local function with_frame(frame, fn, ...)
	frames[#frames + 1] = frame
	return pop_frame(pcall(fn, ...))
end

local function matches_frame(frame, combat, attacker)
	if frame == nil or attacker ~= frame.attacker then
		return false
	elseif frame.kind == "attack" then
		return combat.inst == frame.target
	elseif frame.kind == "area" then
		return combat.inst ~= attacker
	end
	return combat == frame.combat
end

local function is_alive(target)
	return target:IsValid() and not target:IsInLimbo() and not (target.components.health ~= nil and target.components.health:IsDead())
end

-------------------------------------------------------------------------
-- Anchor kinds replay the anchor's hit on each nearby member.
-------------------------------------------------------------------------

local function calc_attack_damage(combat, target, weapon, stimuli)
	-- Mirror DoAttack's electric multiplier; CalcDamage receives it as a multiplier.
	local mult = 1
	local weapon_cmp = weapon ~= nil and weapon.components.weapon or nil
	if (stimuli == "electric" or (weapon_cmp ~= nil and weapon_cmp.stimuli == "electric")) and not IsEntityElectricImmune(target) then
		local electric_damage_mult = weapon_cmp ~= nil and weapon_cmp.electric_damage_mult or TUNING.ELECTRIC_DAMAGE_MULT
		local electric_wet_damage_mult = weapon_cmp ~= nil and weapon_cmp.electric_wet_damage_mult or TUNING.ELECTRIC_WET_DAMAGE_MULT
		mult = electric_damage_mult + electric_wet_damage_mult * target:GetWetMultiplier()
	end
	local damage, spdamage = combat:CalcDamage(target, weapon, mult)
	return { damage = damage, spdamage = spdamage }
end

-- Damage is snapshotted when the anchor is hit, while transient attack
-- state such as catapult elements or Weremoose smash damage still applies.
local function snapshot_damage(anchor, calc)
	anchor.damage = {}
	for _, member in ipairs(anchor.members) do
		anchor.damage[member] = calc(member)
	end
end

local AttackAnchor = {}
AttackAnchor.__index = AttackAnchor

function AttackAnchor:CanHit(member)
	local combat = self.combat
	return member ~= combat.inst
		and combat.inst:IsValid()
		and is_alive(member)
		and member.components.combat ~= nil
		and member.components.combat:CanBeAttacked(combat.inst)
		and (self.weapon == nil or (self.weapon:IsValid() and self.weapon.components.weapon ~= nil))
end

local function restore_attack(combat, calc_damage, ignorehitrange, finiteuses, ignoreloss, ok, ...)
	combat.CalcDamage = calc_damage
	combat.ignorehitrange = ignorehitrange
	if finiteuses ~= nil then
		finiteuses.ignorecombatdurabilityloss = ignoreloss
	end
	if not ok then
		error((...), 0)
	end
end

function AttackAnchor:Hit(member)
	local combat = self.combat
	local weapon = self.weapon
	local snapshot = self.damage[member]
	local calc_damage = rawget(combat, "CalcDamage")
	local class_calc_damage = getmetatable(combat).CalcDamage
	combat.CalcDamage = function(cmp, target, weapon_arg, ...)
		if target == member and weapon_arg == weapon then
			return snapshot.damage, snapshot.spdamage
		end
		return (calc_damage or class_calc_damage)(cmp, target, weapon_arg, ...)
	end
	-- Range is measured from the anchor, which the attack already reached.
	local ignorehitrange = combat.ignorehitrange
	combat.ignorehitrange = true
	-- Projectile hits consume durability on launch, not per propagated hit.
	local finiteuses = self.projectile ~= nil and weapon ~= nil and weapon.components.finiteuses or nil
	local ignoreloss = finiteuses ~= nil and finiteuses.ignorecombatdurabilityloss or nil
	if finiteuses ~= nil then
		finiteuses.ignorecombatdurabilityloss = true
	end
	restore_attack(combat, calc_damage, ignorehitrange, finiteuses, ignoreloss, pcall(combat.DoAttack, combat, member, weapon, self.projectile, self.stimuli, self.instancemult))
end

local AreaAnchor = {}
AreaAnchor.__index = AreaAnchor

function AreaAnchor:CanHit(member)
	local combat = self.combat
	local attacker = combat.inst
	return member ~= attacker
		and attacker:IsValid()
		and member.components.combat ~= nil
		and combat:IsValidTarget(member)
		and not (self.excludetags ~= nil and member:HasAnyTag(self.excludetags))
		and (self.validfn == nil or self.validfn(member, attacker))
end

function AreaAnchor:Hit(member)
	local attacker = self.combat.inst
	local snapshot = self.damage[member]
	Utils.WithAttackSource(attacker, function()
		attacker:PushEvent("onareaattackother", { target = member, weapon = self.weapon, stimuli = self.stimuli })
		member.components.combat:GetAttacked_Internal(attacker, snapshot.damage, self.weapon, self.stimuli, snapshot.spdamage, true)
	end)
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

local AttackedAnchor = {}
AttackedAnchor.__index = AttackedAnchor

function AttackedAnchor:CanHit(member)
	return member ~= self.attacker and is_alive(member) and member.components.combat ~= nil and member.components.combat:CanBeAttacked(self.attacker)
end

function AttackedAnchor:Hit(member)
	local damage = self.base_damage
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
	return member ~= bomb
		and bomb:IsValid()
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

local function is_disabled(attacker, weapon)
	return DISABLED_ENTITIES[attacker.prefab] or (weapon ~= nil and DISABLED_WEAPONS[weapon.prefab])
end

local function get_members(target, attacker)
	local members = get_nearby_members(target)
	for i = #members, 1, -1 do
		if members[i] == attacker then
			table.remove(members, i)
		end
	end
	return members
end

local function add_anchor(ctx, frame, target, attacker, damage, weapon, stimuli, spdamage)
	if is_disabled(attacker, weapon) then
		return
	end
	-- Capture before a lethal hit removes the anchor's chain membership.
	local members = get_members(target, attacker)
	if members[1] == nil then
		return
	end

	local anchor
	if frame.kind == "attack" then
		local combat = frame.combat
		anchor = setmetatable({
			combat = combat,
			weapon = weapon,
			projectile = frame.projectile,
			stimuli = stimuli,
			instancemult = frame.instancemult,
			members = members,
		}, AttackAnchor)
		snapshot_damage(anchor, function(member)
			return calc_attack_damage(combat, member, weapon, stimuli)
		end)
	elseif frame.kind == "area" then
		local combat = frame.combat
		anchor = setmetatable({
			combat = combat,
			weapon = weapon,
			stimuli = stimuli,
			validfn = frame.validfn,
			excludetags = frame.excludetags,
			members = members,
		}, AreaAnchor)
		snapshot_damage(anchor, function(member)
			local member_damage, member_spdamage = combat:CalcDamage(member, weapon, combat.areahitdamagepercent)
			return { damage = member_damage, spdamage = member_spdamage }
		end)
	elseif ctx.explosive ~= nil then
		if attacker ~= ctx.explosive then
			return
		end
		anchor = setmetatable({ bomb = attacker, members = members }, ExplosionAnchor)
	elseif ctx.attacked then
		-- Recover the damage before the anchor's explosive resistance. A fully
		-- resisted anchor took no damage, so its base damage is unknown and the
		-- hit does not spread.
		local resistance = ctx.resistances ~= nil and ctx.resistances[target] or 0
		if resistance >= 1 then
			return
		end
		anchor = setmetatable({
			attacker = attacker,
			base_damage = (damage or 0) / (1 - resistance),
			resist = ctx.resist,
			weapon = weapon,
			stimuli = stimuli,
			spdamage = spdamage,
			members = members,
		}, AttackedAnchor)
	else
		return
	end
	ctx.anchors[#ctx.anchors + 1] = anchor
end

-------------------------------------------------------------------------
-- Combat entry points, called by the Combat hooks
-------------------------------------------------------------------------

local function do_attack(combat, target, projectile, instancemult, fn, ...)
	local frame = { kind = "attack", combat = combat, attacker = combat.inst, target = target, projectile = projectile, instancemult = instancemult }
	return join(with_frame, frame, fn, ...)
end

local function do_area_attack(combat, validfn, excludetags, fn, ...)
	local frame = { kind = "area", combat = combat, attacker = combat.inst, validfn = validfn, excludetags = excludetags }
	return join(with_frame, frame, fn, ...)
end

-- Outside an attack, GetAttacked never propagates.
local function get_attacked(combat, attacker, fn, ...)
	if contexts[1] == nil then
		return fn(...)
	end
	return with_frame({ kind = "attacked", combat = combat, attacker = attacker }, fn, ...)
end

-- Returns false when the hit must be dropped.
local function on_hit(combat, attacker, damage, weapon, stimuli, spdamage)
	local target = combat.inst
	-- During propagation, nested damage may not reach targets already hit,
	-- except the member currently being propagated to.
	if scope ~= nil and scope.propagating ~= nil and scope.propagating ~= target and scope.hits[target] then
		return false
	end
	local frame = frames[#frames]
	-- Only the hit a combat frame made counts; thorns and redirects do not.
	if attacker ~= nil and matches_frame(frame, combat, attacker) and is_alive(target) then
		local ctx = claim(target)
		if ctx ~= nil and is_member(target) then
			add_anchor(ctx, frame, target, attacker, damage, weapon, stimuli, spdamage)
		end
	end
	return true
end

return {
	IsMember = is_member,
	AddMember = add_member,
	GetNearbyMembers = get_nearby_members,
	Run = run,
	NoteResistance = note_resistance,
	DoAttack = do_attack,
	DoAreaAttack = do_area_attack,
	GetAttacked = get_attacked,
	OnHit = on_hit,
}
