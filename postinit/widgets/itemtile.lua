local UIAnim = require("widgets/uianim")
local ItemTile = require("widgets/itemtile")
local FX = {
	LUNAR = "inventory_fx_lunar",
	SHADOW = "inventory_fx_shadow",
}

local function update_fx(self, show, bank_and_build)
	if show then
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

-- Vanilla widgets/itemtile.lua:ItemTile:ToggleShadowFX (762172): shows its one shadow FX layer while showequipshadowfx is set
local function toggle_shadow_fx(self, show)
	local showequipshadowfx = self.showequipshadowfx
	self.showequipshadowfx = show or nil
	ItemTile.ToggleShadowFX(self)
	self.showequipshadowfx = showequipshadowfx
end

local function toggle_king_cane_shadow_fx(self)
	toggle_shadow_fx(self, self.showequipshadowfx or self.item._corrupted:value())
end

local function toggle_lunarshadow_shadow_fx(self)
	local item = self.item
	toggle_shadow_fx(self, not item.state:value() and (item.buffed:value() or self.isequip and ThePlayer:HasTag("shadowmagic")))
end

local function set_lunarshadow_is_equip(self, isequip)
	self.isequip = isequip
	self:ToggleShadowFX()
end

local function upadte_lunarshadow(self)
	update_fx(self, self.item.buffed:value() and self.item.state:value(), FX.LUNAR)
	self:ToggleShadowFX()
	update_meter(self)
end

AddClassPostConstruct("widgets/itemtile", function(self)
	if self.item.prefab == "lunarshadow" then
		self.ToggleShadowFX = toggle_lunarshadow_shadow_fx
		self.SetIsEquip = set_lunarshadow_is_equip
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
		update_fx(self, self.item.toggled:value(), FX.SHADOW)
		self.inst:ListenForEvent("friendshiptotem.toggledirty", function()
			update_fx(self, self.item.toggled:value(), FX.SHADOW)
		end, self.item)
	elseif self.item.prefab == "friendshiptotem_light" then
		update_fx(self, self.item.toggled:value(), FX.LUNAR)
		self.inst:ListenForEvent("friendshiptotem.toggledirty", function()
			update_fx(self, self.item.toggled:value(), FX.LUNAR)
		end, self.item)
	elseif self.item.prefab == "king_cane" then
		self.ToggleShadowFX = toggle_king_cane_shadow_fx
		self:ToggleShadowFX()
		self.inst:ListenForEvent("king_cane.corrupteddirty", function()
			self:ToggleShadowFX()
		end, self.item)
	end
end)
