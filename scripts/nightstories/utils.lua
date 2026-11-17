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
	TargetTestFn = target_testfn,
	WithAttackSource = with_attack_source,
	IsAttackSource = is_attack_source,
}
