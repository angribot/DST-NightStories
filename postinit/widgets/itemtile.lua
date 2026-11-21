local UIAnim = require("widgets/uianim")
local ItemTile = require("widgets/itemtile")
local FX = {
	LUNAR = "inventory_fx_lunar",
	SHADOW = "inventory_fx_shadow",
}

local function update_fx(self, var, bank_and_build)
	if self.item[var]:value() then
		if not self.itemtile_fx then
			self.itemtile_fx = self.image:AddChild(UIAnim())
			self.itemtile_fx:GetAnimState():SetBank(bank_and_build)
			self.itemtile_fx:GetAnimState():SetBuild(bank_and_build)
			self.itemtile_fx:GetAnimState():PlayAnimation("idle", true)
			self.itemtile_fx:GetAnimState():SetTime(math.random() * self.itemtile_fx:GetAnimState():GetCurrentAnimationTime())
			self.itemtile_fx:SetScale(0.25)
			self.itemtile_fx:GetAnimState():AnimateWhilePaused(false)
			self.itemtile_fx:SetClickable(false)
		else
			self.itemtile_fx:GetAnimState():SetBank(bank_and_build)
			self.itemtile_fx:GetAnimState():SetBuild(bank_and_build)
		end
	else
		if self.itemtile_fx then
			self.itemtile_fx:Kill()
			self.itemtile_fx = nil
		end
	end
end

local function is_empty(item)
	if item.components.container then
		return item.components.container:IsEmpty()
	else
		return item.replica.container.classified ~= nil and item.replica.container.classified:IsEmpty()
	end
end

local function percent_show(self)
	if self.percent then
		self.percent:Show()
	end
	self:Refresh()
end

local function percent_hide(self)
	if self.percent then
		self.percent:Hide()
	end
end

local function update_meter(self, force_show)
	if force_show then
		percent_show(self)
	elseif self.item.buffed:value() and not self.item.slotempty:value() then
		self.bg:Hide()
		self.spoilage:Hide()
		percent_hide(self)
	else
		percent_show(self)
	end
end

local function upadte_lunarshadow(self)
	update_fx(self, "buffed", self.item.state:value() and FX.LUNAR or FX.SHADOW)
	update_meter(self)
end

-- Count full corruption as a vanilla shadow FX condition so it shares one layer with the equip FX.
local function toggle_king_cane_shadow_fx(self)
	local showequipshadowfx = self.showequipshadowfx
	if self.item._corrupted:value() then
		self.showequipshadowfx = true
	end
	ItemTile.ToggleShadowFX(self)
	self.showequipshadowfx = showequipshadowfx
end

AddClassPostConstruct("widgets/itemtile", function(self)
	if self.item.prefab == "lunarshadow" then
		upadte_lunarshadow(self)
		self.inst:ListenForEvent("lunarshadow_buffdirty", function()
			upadte_lunarshadow(self)
		end, self.item)
		self.inst:ListenForEvent("lunarshadow_statedirty", function()
			upadte_lunarshadow(self)
		end, self.item)
		self.inst:ListenForEvent("itemget", function()
			update_meter(self)
		end, self.item)
		self.inst:ListenForEvent("itemlose", function()
			update_meter(self, true)
		end, self.item)
	elseif self.item.prefab == "friendshiptotem_dark" then
		update_fx(self, "toggled", FX.SHADOW)
		self.inst:ListenForEvent("friendshiptotem.toggledirty", function()
			update_fx(self, "toggled", FX.SHADOW)
		end, self.item)
	elseif self.item.prefab == "friendshiptotem_light" then
		update_fx(self, "toggled", FX.LUNAR)
		self.inst:ListenForEvent("friendshiptotem.toggledirty", function()
			update_fx(self, "toggled", FX.LUNAR)
		end, self.item)
	elseif self.item.prefab == "king_cane" then
		self.ToggleShadowFX = toggle_king_cane_shadow_fx
		self:ToggleShadowFX()
		self.inst:ListenForEvent("king_cane.corrupteddirty", function()
			self:ToggleShadowFX()
		end, self.item)
	end
end)
