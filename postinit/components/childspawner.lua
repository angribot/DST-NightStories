local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

-- Vanilla homes retain counts, not individual entities. Remember selected skin
-- slots by prefab and population type, consuming a slot only on successful spawn.
AddComponentPostInit("childspawner", function(self)
	local takein = self.TakeInChild
	self.TakeInChild = function(spawner, child, emergency, ...)
		if child.SetBluefishSkinSelected ~= nil and child._ns_bluefish_selected then
			spawner._ns_bluefish = spawner._ns_bluefish or {}
			local key = (emergency and "emergency:" or "normal:") .. child.prefab
			spawner._ns_bluefish[key] = (spawner._ns_bluefish[key] or 0) + 1
		end
		return takein(spawner, child, emergency, ...)
	end
	local spawn = self.DoSpawnChild
	self.DoSpawnChild = function(spawner, target, prefab, radius, emergency, ...)
		local child = spawn(spawner, target, prefab, radius, emergency, ...)
		if child ~= nil and child.SetBluefishSkinSelected ~= nil and spawner._ns_bluefish ~= nil then
			local key = (emergency and "emergency:" or "normal:") .. child.prefab
			local count = spawner._ns_bluefish[key] or 0
			if count > 0 then
				spawner._ns_bluefish[key] = count > 1 and count - 1 or nil
				child:SetBluefishSkinSelected(true, false)
			end
		end
		return child
	end
	local save = self.OnSave
	self.OnSave = function(spawner, ...)
		local data, refs = save(spawner, ...)
		if spawner._ns_bluefish ~= nil and next(spawner._ns_bluefish) ~= nil then
			data.ns_bluefish = shallowcopy(spawner._ns_bluefish)
		end
		return data, refs
	end
	local load = self.OnLoad
	self.OnLoad = function(spawner, data, ...)
		spawner._ns_bluefish = data ~= nil and data.ns_bluefish ~= nil and shallowcopy(data.ns_bluefish) or nil
		return load(spawner, data, ...)
	end
end)
