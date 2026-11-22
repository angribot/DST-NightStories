GLOBAL.setfenv(1, GLOBAL)
local UpvalueUtil = GlassicAPI.UpvalueUtil

local DryingRack = require("components/dryingrack")
local on_done_drying, fn_i, scope_fn = UpvalueUtil.GetUpvalue(DryingRack.LongUpdate, "OnDoneDrying")

local function OnDoneDrying(inst, self, item)
	local stacksize = item and item.components.stackable and item.components.stackable.stacksize or 1
	if stacksize <= 1 then
		return on_done_drying(inst, self, item)
	end

	-- Resize the product as vanilla hands it to the slot, so itemget listeners
	-- (e.g. the Large Drying Rack's salt collector) see the whole dried stack.
	local container = self.container
	local give_item = rawget(container, "GiveItem")
	container.GiveItem = function(_, product, ...)
		container.GiveItem = give_item
		if product.components.stackable then
			product.components.stackable:SetStackSize(stacksize)
		end
		return container:GiveItem(product, ...)
	end
	local product = on_done_drying(inst, self, item)
	container.GiveItem = give_item
	return product
end

debug.setupvalue(scope_fn, fn_i, OnDoneDrying)

local function InstantDry(item, container)
	local slot = container:GetItemSlot(item)
	local product = item.components.dryable and item.components.dryable:GetProduct() or nil
	local stacksize = item and item.components.stackable and item.components.stackable.stacksize or 1
	if slot and product then
		product = SpawnPrefab(product)
		if product then
			if product.components.stackable then
				product.components.stackable:SetStackSize(stacksize)
			end
			LaunchAt(product, container.inst, nil, 0.25, 1)
		end
		item:Remove()
	end
end

function DryingRack:OnBurnt() --Called by DefaultStructureBurntFn
	self.container:ForEachItem(InstantDry, self.container)
end
