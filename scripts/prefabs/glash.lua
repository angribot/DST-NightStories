local function setup_fx(attacker, target, is_shadow)
	if is_shadow then
		-- Only coalesce presentation; every hit still deals damage and refreshes its chain.
		local tick = GetTick()
		if target._ns_shadowglash_fx_tick == tick then
			return
		end
		target._ns_shadowglash_fx_tick = tick
		local spark = SpawnPrefab("hitsparks_fx")
		spark:Setup(attacker, target, nil, { 1, 0, 0 })
		spark.black:set(true)
	else
		local fx = SpawnPrefab("planar_hit_fx")
		fx.Transform:SetScale(0.7, 0.7, 0.7)
		fx.entity:SetParent(target.entity)
	end
end

local function on_attack(inst, attacker, target)
	if attacker and target and target:IsValid() then
		setup_fx(attacker, target)
	end
end

local function on_attack_shadow(inst, attacker, target)
	if attacker and target and target:IsValid() then
		setup_fx(attacker, target, true)
		if inst.enhanced then
			TheWorld.components.horrorchainmanager:AddMember(target, TUNING.SHADOWGLASH_CHAIN_DURATION)
		end
	end
end

local function common_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()

	inst:AddTag("glash")
	inst:AddTag("CLASSIFIED")

	inst.persists = false
	inst:DoTaskInTime(0, inst.Remove)

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("projectile")

	inst:AddComponent("weapon")
	inst.components.weapon:SetRange(TUNING.GLASH_HIT_RANGE)

	return inst
end

local function fn()
	local inst = common_fn()

	inst:AddTag("ignore_planar_entity")

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.weapon:SetDamage(TUNING.GLASH_BASE_DAMAGE)
	inst.components.weapon:SetOnAttack(on_attack)

	return inst
end

local function set_enhanced(inst, enhanced)
	inst.enhanced = enhanced == true
	inst.components.planardamage:SetBaseDamage(inst.enhanced and TUNING.SHADOWGLASH_ENHANCED_PLANAR_DAMAGE or TUNING.SHADOWGLASH_PLANAR_DAMAGE)
end

local function fn_shadow()
	local inst = common_fn()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.weapon:SetDamage(0)
	inst.components.weapon:SetOnAttack(on_attack_shadow)

	inst:AddComponent("planardamage")
	inst.SetEnhanced = set_enhanced
	inst:SetEnhanced(false)

	return inst
end

------------------------- Glash Builder -------------------------
local function builder_onbuilt(inst, builder)
	if builder then
		local component = builder.components.builder
		local build = component and component.shadowglash_build
		builder:AddDebuff("buff_shadowglash", "buff_shadowglash", { enhanced = build ~= nil and build.fuel == "horrorfuel" })
	end
end

local function fn_builder()
	local inst = CreateEntity()

	inst.entity:AddTransform()

	inst:AddTag("CLASSIFIED")

	--[[Non-networked entity]]
	inst.persists = false

	--Auto-remove if not spawned by builder
	inst:DoTaskInTime(0, inst.Remove)

	if not TheWorld.ismastersim then
		return inst
	end

	inst.pettype = "shadowglash"
	inst.OnBuiltFn = builder_onbuilt

	return inst
end

------------------------- Glash FX -------------------------

local function play_sound(inst, sound)
	inst.SoundEmitter:PlaySound(sound)
end

local function MakeFx(t)
	local function startfx(proxy, name)
		local inst = CreateEntity(t.name)

		inst.entity:AddTransform()
		inst.entity:AddAnimState()

		inst:AddTag("FX")

		--[[Non-networked entity]]
		inst.entity:SetCanSleep(false)
		inst.persists = false

		inst.Transform:SetFromProxy(proxy.GUID)

		if t.sound then
			inst.entity:AddSoundEmitter()
			inst:DoTaskInTime(t.sounddelay or 0, play_sound, t.sound)
		end

		local anim_state = inst.AnimState
		anim_state:SetBank(t.bank)
		anim_state:SetBuild(t.build)
		anim_state:PlayAnimation(FunctionOrValue(t.anim)) -- THIS IS A CLIENT SIDE FUNCTION
		anim_state:SetMultColour(0.85, 0.85, 0.85, 0.85)
		anim_state:SetBloomEffectHandle("shaders/anim.ksh")
		anim_state:SetSortOrder(3)

		if t.fn then
			t.fn(inst)
		end

		inst:ListenForEvent("animover", inst.Remove)
	end

	local function fx_fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddNetwork()

		if not TheNet:IsDedicated() then
			inst:DoTaskInTime(0, startfx, inst)
		end

		inst:AddTag("FX")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst.persists = false
		inst:DoTaskInTime(1, inst.Remove)

		return inst
	end

	return Prefab(t.name, fx_fn)
end

local glash_fx = {
	name = "glash_fx",
	bank = "glash_fx",
	build = "glash_fx",
	anim = function()
		return "idle_med_" .. math.random(3)
	end,
	sound = "wanda2/characters/wanda/watch/weapon/nightmare_FX",
	fn = function(inst)
		inst.AnimState:SetFinalOffset(1)
	end,
}

local glash_big_fx = {
	name = "glash_big_fx",
	bank = "glash_fx",
	build = "glash_fx",
	anim = function()
		return "idle_big_" .. math.random(3)
	end,
	sound = "wanda2/characters/wanda/watch/weapon/shadow_hit_old",
	-- sound = "dontstarve/common/gem_shatter",
	fn = function(inst)
		inst.AnimState:SetFinalOffset(1)
	end,
}

return Prefab("glash", fn, nil, { "planar_hit_fx" }),
	Prefab("shadowglash", fn_shadow, nil, { "hitsparks_fx" }),
	Prefab("shadowglash_builder", fn_builder, nil, { "shadowglash" }),
	MakeFx(glash_fx),
	MakeFx(glash_big_fx)
