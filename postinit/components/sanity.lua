local AddPrefabPostInit = AddPrefabPostInit
local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

-- netvars --
AddPrefabPostInit("player_classified", function(inst)
	inst.sanityrate = net_float(inst.GUID, "sanity.rate")
	inst.inducedinsanity = net_bool(inst.GUID, "sanity.inducedinsanity")
end)
local Sanity = require("components/sanity")
local sanity_recalc = Sanity.Recalc
function Sanity:Recalc(dt)
	sanity_recalc(self, dt)
	self.inst.replica.sanity:SetRate(self.rate)
end

function Sanity:GetRate()
	return self.rate
end

local sanity_get_percent = Sanity.GetPercent
function Sanity:GetPercent()
	if self.inst.prefab == "dummy" then
		return self:GetRealPercent()
	end
	return sanity_get_percent(self)
end

local set_induced_insanity = Sanity.SetInducedInsanity
function Sanity:SetInducedInsanity(src, val)
	set_induced_insanity(self, src, val)
	self.inst.replica.sanity:SetInducedInsanity(self.inducedinsanity == true)
end

-- Sanity Replica --
local SanityReplica = require("components/sanity_replica")
function SanityReplica:SetRate(rate)
	if self.classified then
		self.classified.sanityrate:set(rate)
	end
end

function SanityReplica:GetRate()
	if self.inst.components.sanity then
		return self.inst.components.sanity:GetRate()
	elseif self.classified then
		return self.classified.sanityrate:value()
	else
		return 0
	end
end

function SanityReplica:SetInducedInsanity(val)
	if self.classified then
		self.classified.inducedinsanity:set(val)
	end
end

function SanityReplica:GetIsInducedInsanity()
	if self.inst.components.sanity then
		return self.inst.components.sanity.inducedinsanity
	elseif self.classified then
		return self.classified.inducedinsanity:value()
	else
		return false
	end
end

-- Dummy restores sanity from others --
local function sanity_aura_post_init(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst.prefab == "dummy" then
		return
	end

	if not inst.components.sanityaura then
		inst:AddComponent("sanityaura")
		inst.components.sanityaura.aura = TUNING.DUMMY_SANITY_AURA
	end

	local aurafn = inst.components.sanityaura.aurafn
	inst.components.sanityaura.aurafn = function(inst, observer, ...)
		if observer.prefab == "dummy" then
			return inst.components.sanityaura.aura
		elseif aurafn then
			return aurafn(inst, observer, ...)
		else
			return 0
		end
	end
end

AddPlayerPostInit(sanity_aura_post_init)
