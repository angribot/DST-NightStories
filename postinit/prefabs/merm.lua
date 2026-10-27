local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local Bluefish = require("nightstories/bluefish")

local function refresh_skin(inst, showfx)
	-- Keep the last visible outfit through death and corpse creation.
	if not inst:IsValid() or inst.components.health:IsDead() or inst._ns_bluefish_changing then
		return
	end
	local follower = inst.components.follower
	local leader = follower ~= nil and follower:GetLeader() or nil
	local active = inst._ns_bluefish_selected and leader ~= nil and leader:IsValid() and leader:HasTag("player")
	if inst._ns_bluefish_active == active then
		return
	end
	local skinname = active and Bluefish.skins[inst.prefab] or nil
	inst._ns_bluefish_changing = true
	local ok, err = pcall(function()
		TheSim:ReskinEntity(inst.GUID, inst.skinname, skinname, nil, leader ~= nil and leader.userid or "")
	end)
	inst._ns_bluefish_changing = false
	if not ok then
		error(err)
	end
	if showfx then
		Bluefish.PlayFX(inst)
	end
end

local function set_selected(inst, selected, showfx)
	inst._ns_bluefish_selected = selected == true
	refresh_skin(inst, showfx)
end

local function on_leader_changed(inst)
	refresh_skin(inst, not inst._ns_bluefish_loading)
end

local function on_initialize(inst)
	inst._ns_bluefish_loading = false
	refresh_skin(inst, false)
end

-- These vanilla transformations spawn their replacement synchronously. Scope the
-- transfer to the expected prefab without replacing the global SpawnPrefab.
local transfer
local function wrap_transfer(inst, method, destination)
	local original = inst[method]
	if original == nil then
		return
	end
	inst[method] = function(self, ...)
		local previous = transfer
		transfer = { prefab = destination, selected = self._ns_bluefish_selected }
		local args = { ... }
		local count = select("#", ...)
		local result = { pcall(function()
			return original(self, unpack(args, 1, count))
		end) }
		transfer = previous
		if not result[1] then
			error(result[2])
		end
		return unpack(result, 2)
	end
end

local function postinit(inst)
	if not TheWorld.ismastersim then
		return
	end
	-- Skin init can run before this hook; preserve any state it already set.
	inst._ns_bluefish_selected = inst._ns_bluefish_selected == true
	inst._ns_bluefish_active = inst._ns_bluefish_active == true
	inst._ns_bluefish_loading = true
	inst.SetBluefishSkinSelected = set_selected
	inst:ListenForEvent("leaderchanged", on_leader_changed)
	inst:DoTaskInTime(0, on_initialize)

	local onsave = inst.OnSave
	inst.OnSave = function(self, data, ...)
		data.ns_bluefish = self._ns_bluefish_selected or nil
		if onsave ~= nil then
			return onsave(self, data, ...)
		end
	end
	local onload = inst.OnLoad
	inst.OnLoad = function(self, data, ...)
		if onload ~= nil then
			onload(self, data, ...)
		end
		set_selected(self, (data ~= nil and data.ns_bluefish == true) or self.skinname == Bluefish.skins[self.prefab], false)
	end

	if transfer ~= nil and transfer.prefab == inst.prefab then
		set_selected(inst, transfer.selected, false)
	end
	wrap_transfer(inst, "DoLunarMutation", "merm_lunar")
	wrap_transfer(inst, "TestForShadowDeath", "merm_shadow")
	if inst.prefab == "merm_lunar" then
		-- Vanilla calls its local DoLunarRevert from this callback, before
		-- leaderchanged, and removes the old entity synchronously.
		local follower = inst.components.follower
		wrap_transfer(follower, "OnChangedLeader", "merm")
		local onchangedleader = follower.OnChangedLeader
		follower.OnChangedLeader = function(self, new_leader, previous_leader)
			if new_leader == nil then
				refresh_skin(self, not self._ns_bluefish_loading)
			end
			return onchangedleader(self, new_leader, previous_leader)
		end
	end

	local savecorpse = inst.SaveCorpseData
	inst.SaveCorpseData = function(self, corpse, ...)
		local data = savecorpse(self, corpse, ...) or {}
		if self._ns_bluefish_selected then
			data.ns_bluefish = { selected = true, active = self._ns_bluefish_active, prefab = self.prefab }
		end
		return data
	end
	local loadcorpse = inst.LoadCorpseData
	inst.LoadCorpseData = function(self, corpse, ...)
		local data = corpse.corpsedata and corpse.corpsedata.ns_bluefish
		set_selected(self, data ~= nil and data.selected, false)
		local result = loadcorpse(self, corpse, ...)
		refresh_skin(self, false)
		return result
	end
end

for prefab in pairs(Bluefish.builds) do
	AddPrefabPostInit(prefab, postinit)
end

AddPrefabPostInit("mermcorpse", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	local function applycorpse(self)
		local data = self.corpsedata and self.corpsedata.ns_bluefish
		if data ~= nil and data.active then
			Bluefish.Apply(self, data.prefab, true)
		end
	end
	local setdata = inst.SetCorpseData
	inst.SetCorpseData = function(self, ...)
		local result = setdata(self, ...)
		applycorpse(self)
		return result
	end
	local onload = inst.OnLoad
	inst.OnLoad = function(self, ...)
		local result = onload(self, ...)
		applycorpse(self)
		return result
	end
end)
