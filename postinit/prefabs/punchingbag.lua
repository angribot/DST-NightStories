local AddPrefabPostInit = AddPrefabPostInit
local UpvalueUtil = GlassicAPI.UpvalueUtil
GLOBAL.setfenv(1, GLOBAL)

local PUNCHINGBAGS = {
	"punchingbag",
	"punchingbag_lunar",
	"punchingbag_shadow",
}

local NUM_DIGITS, MAX_NUM = 4, 9999
local function do_digits(inst)
	local number = math.min(MAX_NUM, inst._digits_num or 0)

	for digit_index = NUM_DIGITS, 1, -1 do
		local digit = number % 10
		number = math.floor(number / 10)
		inst.AnimState:OverrideSymbol("column" .. digit_index, "punchingbag", "number" .. digit .. "_black")
	end

	if not (inst.components.burnable and inst.components.burnable:IsBurning()) then
		inst.SoundEmitter:PlaySound("farming/common/farm/veggie_scale/place")
	end

	inst._digits_task = nil
	inst._digits_num = nil
end

local function pre_digits(inst, number)
	inst._digits_num = inst._digits_num and (inst._digits_num + number) or number

	if inst._digits_task == nil then
		inst._digits_task = inst:DoTaskInTime(0, do_digits)
	end
end

--------------------------------------------------------------------------------
local function new_health_delta(inst, data)
	if data.amount <= 0 then
		pre_digits(inst, math.floor(math.abs(data.amount)))
	end
end

for _, prefab in ipairs(PUNCHINGBAGS) do
	AddPrefabPostInit(prefab, function(inst)
		if not TheWorld.ismastersim then
			return
		end
		for _, fn in ipairs(inst.event_listeners["healthdelta"][inst]) do
			local prev_do_digits = UpvalueUtil.GetUpvalue(fn, "do_digits")
			if prev_do_digits then
				inst:RemoveEventCallback("healthdelta", fn)
			end
		end
		inst:ListenForEvent("healthdelta", new_health_delta)
	end)
end
