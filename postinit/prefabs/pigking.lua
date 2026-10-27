local AddPrefabPostInit = AddPrefabPostInit
local UpvalueUtil = GlassicAPI.UpvalueUtil
GLOBAL.setfenv(1, GLOBAL)

local function get_reward(giver, item)
	if giver.prefab == "miotan" then
		return "nightmarefuel", 2
		--[[ Removed due to new feature.
	elseif TheWorld.state.isalterawake then
		return TheWorld.state.islunarhailing and item and item.components.tradable.goldvalue > 1 and "moonglass_charged" or "moonglass", 1
	]]
	end
	return "goldnugget"
end

local function launchitem(item, angle)
	-- copied from pigking.lua --
	local speed = math.random() * 4 + 2
	angle = (angle + math.random() * 60 - 30) * DEGREES
	item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
end

local function ontradeforitem(inst, item, giver, ...)
	-- copied from pigking.lua (synced with game version 760178) --
	AwardPlayerAchievement("pigking_trader", giver)

	local x, y, z = inst.Transform:GetWorldPosition()
	y = 4.5

	local angle
	if giver ~= nil and giver:IsValid() then
		angle = 180 - giver:GetAngleToPoint(x, 0, z)
	else
		local down = TheCamera:GetDownVec()
		angle = math.atan2(down.z, down.x) / DEGREES
		giver = nil
	end

	-- CHANGED PART --
	local stacksize = item.components.stackable and item.components.stackable.stacksize or 1
	local reward, max_num = get_reward(giver, item)
	local amount = max_num and math.min(max_num, item.components.tradable.goldvalue) or item.components.tradable.goldvalue
	for k = 1, amount * stacksize do
		local nug = SpawnPrefab(reward)
		nug.Transform:SetPosition(x, y, z)
		launchitem(nug, angle)
	end

	if item.components.tradable.tradefor ~= nil then
		for _, v in pairs(item.components.tradable.tradefor) do
			for k = 1, stacksize do
				local item = SpawnPrefab(v)
				if item ~= nil then
					item.Transform:SetPosition(x, y, z)
					launchitem(item, angle)
				end
			end
		end
	end

	if IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) then
		for k = 1, stacksize do
			-- pick out up to 3 types of candies to throw out
			local candytypes = { math.random(NUM_HALLOWEENCANDY), math.random(NUM_HALLOWEENCANDY), math.random(NUM_HALLOWEENCANDY) }
			local numcandies = (item.components.tradable.halloweencandyvalue or 1) + math.random(2) + 2

			-- only people in costumes get a good amount of candy!
			if giver ~= nil and giver.components.skinner ~= nil then
				for _, item in pairs(giver.components.skinner:GetClothing()) do
					if DoesItemHaveTag(item, "COSTUME") or DoesItemHaveTag(item, "HALLOWED") then
						numcandies = numcandies + math.random(4) + 2
						break
					end
				end
			end

			local numbombs = math.floor(numcandies % 6)

			for k = 1, numcandies do
				local candy = SpawnPrefab("halloweencandy_" .. GetRandomItem(candytypes))
				candy.Transform:SetPosition(x, y, z)
				launchitem(candy, angle)
			end

			if numbombs > 0 and TryLuckRoll(giver, TUNING.PUMPKIN_BOMB_PIGKING_TRADE_CHANCE, LuckFormulas.LootDropperChance) then
				for k = 1, numbombs do
					local bomb = SpawnPrefab("pumpkin_bomb")
					bomb.Transform:SetPosition(x, y, z)
					launchitem(bomb, angle)
				end
			end

			if TryLuckRoll(giver, TUNING.HALLOWEEN_PUMPKINCARVER_PIGKING_TRADE_CHANCE, LuckFormulas.LootDropperChance) then
				local pumpkincarver = SpawnPrefab("pumpkincarver" .. math.random(NUM_HALLOWEEN_PUMPKINCARVERS))
				pumpkincarver.Transform:SetPosition(x, y, z)
				launchitem(pumpkincarver, angle)
			end
		end
	end
	-- end --
end

AddPrefabPostInit("pigking", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	UpvalueUtil.SetUpvalue(inst.components.trader.onaccept, "ontradeforgold", ontradeforitem)
end)
