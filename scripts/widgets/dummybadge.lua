local Badge = require("widgets/badge")
local UIAnim = require("widgets/uianim")

local SANITY_TINT = { 174 / 255, 21 / 255, 21 / 255, 1 }
local INDUCEDINSANITY_TINT = { 123 / 255, 0 / 255, 177 / 255, 1 }
local LUNACY_TINT = { 191 / 255, 232 / 255, 240 / 255, 1 }

local function OnGhostDeactivated(inst)
	if inst.AnimState:IsCurrentAnimation("ghost_deactivate") then
		inst.widget:Hide()
	end
end

local function OnEffigyDeactivated(inst)
	if inst.AnimState:IsCurrentAnimation("effigy_deactivate") then
		inst.widget:Hide()
	end
end

local DummyBadge = Class(Badge, function(self, owner)
	Badge._ctor(self, nil, owner, SANITY_TINT, "status_sanity", nil, nil, true)

	self.OVERRIDE_SYMBOL_BUILD = {} -- modders can add symbols-build pairs to this table by calling SetBuildForSymbol
	self.default_symbol_build = "status_abigail"

	self.sanitymode = SANITY_MODE_INSANITY
	self.inducedinsanity = false
	self.target_sanitymode = self.sanitymode
	self.target_inducedinsanity = self.inducedinsanity

	self.topperanim = self.underNumber:AddChild(UIAnim())
	self.topperanim:GetAnimState():SetBank("status_meter")
	self.topperanim:GetAnimState():SetBuild("status_meter")
	self.topperanim:GetAnimState():PlayAnimation("anim")
	self.topperanim:GetAnimState():AnimateWhilePaused(false)
	self.topperanim:GetAnimState():SetMultColour(0, 0, 0, 1)
	self.topperanim:SetScale(1, -1, 1)
	self.topperanim:SetClickable(false)
	self.topperanim:GetAnimState():SetPercent("anim", 1)

	if self.circleframe ~= nil then
		self.circleframe:GetAnimState():Hide("frame")
	else
		self.anim:GetAnimState():Hide("frame")
	end

	self.circleframe2 = self.underNumber:AddChild(UIAnim())
	self.circleframe2:GetAnimState():SetBank("status_sanity")
	self.circleframe2:GetAnimState():SetBuild("status_sanity")
	self.circleframe2:GetAnimState():OverrideSymbol("frame_circle", "status_meter", "frame_circle")
	self.circleframe2:GetAnimState():Hide("FX")
	self.circleframe2:GetAnimState():PlayAnimation("frame")
	self.circleframe2:GetAnimState():AnimateWhilePaused(false)

	self.sanityarrow = self.underNumber:AddChild(UIAnim())
	self.sanityarrow:GetAnimState():SetBank("sanity_arrow")
	self.sanityarrow:GetAnimState():SetBuild("sanity_arrow")
	self.sanityarrow:GetAnimState():PlayAnimation("neutral")
	self.sanityarrow:GetAnimState():AnimateWhilePaused(false)
	self.sanityarrow:SetClickable(false)

	self.ghostanim = self.underNumber:AddChild(UIAnim())
	self.ghostanim:GetAnimState():SetBank("status_sanity")
	self.ghostanim:GetAnimState():SetBuild("status_sanity")
	self.ghostanim:GetAnimState():PlayAnimation("ghost_deactivate")
	self.ghostanim:GetAnimState():AnimateWhilePaused(false)
	self.ghostanim:Hide()
	self.ghostanim:SetClickable(false)
	self.ghostanim.inst:ListenForEvent("animover", OnGhostDeactivated)

	self.val = 100
	self.max = 100
	self.penaltypercent = 0
	self.ghost = false

	self.effigyanim = self.underNumber:AddChild(UIAnim())
	self.effigyanim:GetAnimState():SetBank("status_health")
	self.effigyanim:GetAnimState():SetBuild("status_health")
	self.effigyanim:GetAnimState():PlayAnimation("effigy_deactivate")
	self.effigyanim:Hide()
	self.effigyanim:SetClickable(false)
	self.effigyanim:GetAnimState():AnimateWhilePaused(false)
	self.effigyanim.inst:ListenForEvent("animover", OnEffigyDeactivated)

	self.gravestoneeffigyanim = self.underNumber:AddChild(UIAnim())
	self.gravestoneeffigyanim:GetAnimState():SetBank("status_wendy_gravestone")
	self.gravestoneeffigyanim:GetAnimState():SetBuild("status_wendy_gravestone")
	self.gravestoneeffigyanim:GetAnimState():PlayAnimation("effigy_deactivate")
	self.gravestoneeffigyanim:Hide()
	self.gravestoneeffigyanim:SetClickable(false)
	self.gravestoneeffigyanim:GetAnimState():AnimateWhilePaused(false)
	self.gravestoneeffigyanim.inst:ListenForEvent("animover", OnEffigyDeactivated)

	self.effigy = false
	self.effigybreaksound = nil

	self.bufficon = self.underNumber:AddChild(UIAnim())
	self.bufficon:GetAnimState():SetBank("status_abigail")
	self.bufficon:GetAnimState():SetBuild("status_abigail")
	self.bufficon:GetAnimState():PlayAnimation("buff_none")
	self.bufficon:GetAnimState():AnimateWhilePaused(false)
	self.bufficon:SetClickable(false)
	self.bufficon:SetScale(-1, 1, 1)
	self.buffsymbol = 0

	self.poisonanim = self.underNumber:AddChild(UIAnim())
	self.poisonanim:GetAnimState():SetBank("poison")
	self.poisonanim:GetAnimState():SetBuild("poison_meter_overlay")
	self.poisonanim:GetAnimState():PlayAnimation("deactivate")
	self.poisonanim:Hide()
	self.poisonanim:SetClickable(false)
	self.poison = false -- So it doesn't trigger on load

	self.inst:ListenForEvent("isacidsizzling", function(owner, isacidsizzling)
		if isacidsizzling == nil then
			isacidsizzling = owner:IsAcidSizzling()
		end
		if isacidsizzling then
			if self.acidsizzling == nil then
				self.acidsizzling = self.underNumber:AddChild(UIAnim())
				self.acidsizzling:GetAnimState():SetBank("inventory_fx_acidsizzle")
				self.acidsizzling:GetAnimState():SetBuild("inventory_fx_acidsizzle")
				self.acidsizzling:GetAnimState():PlayAnimation("idle", true)
				self.acidsizzling:GetAnimState():SetMultColour(0.65, 0.62, 0.17, 0.8)
				self.acidsizzling:GetAnimState():SetTime(math.random())
				self.acidsizzling:SetScale(0.2)
				self.acidsizzling:GetAnimState():AnimateWhilePaused(false)
				self.acidsizzling:SetClickable(false)
			end
		else
			if self.acidsizzling ~= nil then
				self.acidsizzling:Kill()
				self.acidsizzling = nil
			end
		end
	end, owner)

	self.inst:ListenForEvent("dummyhealthpulseup", function(_, data)
		self:PulseGreen()
		if not data.silent then
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
		end
	end, owner)
	self.inst:ListenForEvent("dummyhealthpulsedown", function(_, data)
		self:PulseRed()
		if not data.silent then
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_down")
		end
	end, owner)

	self:StartUpdating()
end)

-- StatusDisplays updates values and warnings before calling HealthDelta.
-- Only server-classified events may pulse; ignore the legacy pulse stream.
function DummyBadge:HealthDelta() end
function DummyBadge:ForceHealthPulse() end

function DummyBadge:SetBuildForSymbol(build, symbol)
	self.OVERRIDE_SYMBOL_BUILD[symbol] = build
end

function DummyBadge:ShowBuff(symbol)
	if symbol == 0 then
		if self.buffsymbol ~= 0 then
			self.bufficon:GetAnimState():PlayAnimation("buff_deactivate")
			self.bufficon:GetAnimState():PushAnimation("buff_none", false)
		end
	elseif symbol ~= self.buffsymbol then
		self.bufficon:GetAnimState():OverrideSymbol("buff_icon", self.OVERRIDE_SYMBOL_BUILD[symbol] or self.default_symbol_build, symbol)

		self.bufficon:GetAnimState():PlayAnimation("buff_activate")
		self.bufficon:GetAnimState():PushAnimation("buff_idle", false)
	end

	self.buffsymbol = symbol
end

function DummyBadge:UpdateBuff(symbol)
	self:ShowBuff(symbol)
end

function DummyBadge:ShowEffigy(effigy_type)
	if effigy_type ~= "grave" and not self.effigyanim.shown then
		self.effigyanim:GetAnimState():PlayAnimation("effigy_activate")
		self.effigyanim:GetAnimState():PushAnimation("effigy_idle", false)
		self.effigyanim:Show()
	elseif effigy_type == "grave" and not self.gravestoneeffigyanim.shown then
		self.gravestoneeffigyanim:GetAnimState():PlayAnimation("effigy_activate")
		self.gravestoneeffigyanim:GetAnimState():PushAnimation("effigy_idle", false)
		self.gravestoneeffigyanim:Show()
	end
	self.effigy = true
end

local function PlayEffigyBreakSound(inst, self)
	inst.task = nil
	if self:IsVisible() and inst.AnimState:IsCurrentAnimation("effigy_deactivate") then
		--Don't use FE sound since it's not a 2D sfx
		TheFocalPoint.SoundEmitter:PlaySound(self.effigybreaksound)
	end
end

function DummyBadge:HideEffigy(effigy_type)
	self.effigy = false
	if effigy_type ~= "grave" and self.effigyanim.shown then
		self.effigyanim:GetAnimState():PlayAnimation("effigy_deactivate")
		if self.effigyanim.inst.task ~= nil then
			self.effigyanim.inst.task:Cancel()
		end
		self.effigyanim.inst.task = self.effigyanim.inst:DoTaskInTime(7 * FRAMES, PlayEffigyBreakSound, self)
	end

	if effigy_type == "grave" and self.gravestoneeffigyanim.shown then
		self.gravestoneeffigyanim:GetAnimState():PlayAnimation("effigy_deactivate")
		if self.gravestoneeffigyanim.inst.task ~= nil then
			self.gravestoneeffigyanim.inst.task:Cancel()
		end
		self.gravestoneeffigyanim.inst.task = self.gravestoneeffigyanim.inst:DoTaskInTime(7 * FRAMES, PlayEffigyBreakSound, self)
	end
end

function DummyBadge:DoTransition()
	local sanity = self.owner.replica.sanity
	local new_sanity_mode = sanity:GetSanityMode()
	self.inducedinsanity = sanity:GetIsInducedInsanity() == true
	self.target_sanitymode = new_sanity_mode
	self.target_inducedinsanity = self.inducedinsanity
	if self.sanitymode ~= new_sanity_mode then
		self.sanitymode = new_sanity_mode
		if self.sanitymode == SANITY_MODE_INSANITY then
			self.backing:GetAnimState():ClearOverrideSymbol("bg")
			self.circleframe:GetAnimState():OverrideSymbol("icon", "status_sanity", "icon")
		else
			self.backing:GetAnimState():OverrideSymbol("bg", "status_sanity", "lunacy_bg")
			self.circleframe:GetAnimState():OverrideSymbol("icon", "status_sanity", "lunacy_icon")
		end
	end

	self.anim:GetAnimState():SetMultColour(unpack(self.inducedinsanity and INDUCEDINSANITY_TINT or (self.sanitymode == SANITY_MODE_INSANITY and SANITY_TINT or LUNACY_TINT)))
	Badge.SetPercent(self, self.val, self.max)

	self.transition_task = nil
end

local function RemoveFX(fxinst)
	fxinst.widget:Kill()
end

function DummyBadge:SpawnTransitionFX(anim)
	if self.parent ~= nil then
		local fx = self.parent:AddChild(UIAnim())
		fx:SetPosition(self:GetPosition())
		fx:SetClickable(false)
		fx.inst:ListenForEvent("animover", RemoveFX)
		fx:GetAnimState():SetBank("status_sanity")
		fx:GetAnimState():SetBuild("status_sanity")
		fx:GetAnimState():Hide("frame")
		fx:GetAnimState():PlayAnimation(anim)
	end
end

local function DoTransitionTask(self)
	if self.transition_task ~= nil then
		self.transition_task:Cancel()
		self.transition_task = nil
	end
	if not self:IsVisible() or (self.target_sanitymode == self.sanitymode and self.target_inducedinsanity == self.inducedinsanity) then
		self:DoTransition()
		return
	end
	if self.target_sanitymode ~= self.sanitymode then
		if self.target_sanitymode == SANITY_MODE_INSANITY then
			self.circleframe2:GetAnimState():PlayAnimation("transition_sanity")
			self:SpawnTransitionFX("transition_sanity")
		else
			self.circleframe2:GetAnimState():PlayAnimation("transition_lunacy")
			self:SpawnTransitionFX("transition_lunacy")
		end
		self.circleframe2:GetAnimState():PushAnimation("frame", false)
	end
	self.transition_task = self.owner:DoTaskInTime(6 * FRAMES, function()
		self:DoTransition()
	end)
end

function DummyBadge:SetPercent(val, max, penaltypercent)
	self.val = val
	self.max = max
	Badge.SetPercent(self, self.val, self.max)

	self.penaltypercent = penaltypercent or 0
	self.topperanim:GetAnimState():SetPercent("anim", 1 - self.penaltypercent)
end

function DummyBadge:OnUpdate(dt)
	if TheNet:IsServerPaused() then
		return
	end

	local sanity = self.owner.replica.sanity
	local sanitymode = sanity:GetSanityMode()
	local inducedinsanity = sanity:GetIsInducedInsanity() == true
	if self.target_sanitymode ~= sanitymode or self.target_inducedinsanity ~= inducedinsanity then
		self.target_sanitymode = sanitymode
		self.target_inducedinsanity = inducedinsanity
		DoTransitionTask(self)
	end

	local health_rate = self.owner._resource_rate:value()

	local anim = (health_rate > 0.99 and "arrow_loop_increase_most")
		or (health_rate > 0.49 and "arrow_loop_increase_more")
		or (health_rate > 0.02 and "arrow_loop_increase")
		or (health_rate < -0.99 and "arrow_loop_decrease_most")
		or (health_rate < -0.49 and "arrow_loop_decrease_more")
		or (health_rate < -0.02 and "arrow_loop_decrease")
		or "neutral"

	if health_rate > 0 and self.owner.replica.health:GetPercent() >= 1 then
		anim = "neutral"
	end

	if self.arrowdir ~= anim then
		self.arrowdir = anim
		self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
	end

	local ghost = self.owner.replica.sanity and self.owner.replica.sanity:IsGhostDrain() or false
	if self.ghost ~= ghost then
		self.ghost = ghost
		if ghost then
			self.ghostanim:GetAnimState():PlayAnimation("ghost_activate")
			self.ghostanim:GetAnimState():PushAnimation("ghost_idle", true)
			self.ghostanim:Show()
		else
			self.ghostanim:GetAnimState():PlayAnimation("ghost_deactivate")
		end
	end

	local poison = self.owner.ispoisoned or (self.owner.player_classified and self.owner.player_classified.ispoisoned and self.owner.player_classified.ispoisoned:value())
	if self.poison ~= poison then
		self.poison = poison
		if poison then
			self.poisonanim:GetAnimState():PlayAnimation("activate")
			self.poisonanim:GetAnimState():PushAnimation("idle", true)
			self.poisonanim:Show()
		else
			self.owner.SoundEmitter:PlaySound("ia/common/antivenom_use")
			self.poisonanim:GetAnimState():PlayAnimation("deactivate")
		end
	end
end

return DummyBadge
