-- Independent flags preserve feedback priority across a replication batch.
-- Overtime updates must not erase an earlier hit or audible heal.
local PULSES = {
	{ field = "_dummyhealquiet", event = "dummyhealthpulseup", silent = true },
	{ field = "_dummyheal", event = "dummyhealthpulseup", silent = false },
	{ field = "_dummyhurt", event = "dummyhealthpulsedown", silent = false },
}

local function Play(owner, pulse)
	owner:PushEvent(pulse.event, { silent = pulse.silent })
end

local function Push(owner, up, silent)
	local pulse = PULSES[up and (silent and 1 or 2) or 3]
	local classified = owner.player_classified
	if classified ~= nil then
		local flag = classified[pulse.field]
		flag:set_local(true)
		flag:set(true)
	end
	if not TheNet:IsDedicated() then
		Play(owner, pulse)
	end
end

local function OnHealthDirty(inst)
	local selected
	for _, pulse in ipairs(PULSES) do
		local flag = inst[pulse.field]
		if flag:value() then
			selected = pulse
		end
		flag:set_local(false)
	end
	local owner = inst._parent
	if selected ~= nil and owner ~= nil and owner.prefab == "dummy" then
		Play(owner, selected)
	end
end

local function RegisterListener(inst)
	-- Initial deserialization is state, not a new feedback event.
	for _, pulse in ipairs(PULSES) do
		inst[pulse.field]:set_local(false)
	end
	inst:ListenForEvent("healthdirty", OnHealthDirty)
end

local function InitializeClassified(inst)
	-- The owner may not be attached yet. Declare the same fields everywhere.
	for _, pulse in ipairs(PULSES) do
		inst[pulse.field] = net_bool(inst.GUID, "dummy." .. pulse.field, "healthdirty")
	end
	if not TheWorld.ismastersim then
		inst:DoStaticTaskInTime(0, RegisterListener)
	end
	-- Hosts already play synchronously and must never relay network echoes.
end

return { Push = Push, InitializeClassified = InitializeClassified }
