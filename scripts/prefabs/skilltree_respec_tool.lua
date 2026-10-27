local SKILLTREE_DEFS = require("prefabs/skilltree_defs").SKILLTREE_DEFS

-- DST 760178: these effects lack a complete in-place deactivation path.
-- Keep this list limited to effects of skills removed by this respec, not
-- historical save repair. Other skills use the vanilla callbacks and events.
local function RefreshWillow(player, removed)
	if removed.willow_controlled_burn_1 then
		player:RemoveTag("controlled_burner")
	end
	if removed.willow_embers then
		player:RemoveTag("ember_master")
	end
	for _, alignment in ipairs({ "lunar", "shadow" }) do
		local key = "willow_allegiance_" .. alignment
		if removed[key .. "_fire"] or removed[key .. "_bernie"] then
			player:RemoveTag("player_" .. alignment .. "_aligned")
			if player.components.damagetyperesist then
				player.components.damagetyperesist:RemoveResist(alignment .. "_aligned", player, key)
			end
			if player.components.damagetypebonus then
				local opposite = alignment == "lunar" and "shadow" or "lunar"
				player.components.damagetypebonus:RemoveBonus(opposite .. "_aligned", player, key)
			end
		end
	end

	local bernies = {}
	for bernie in pairs(player.bigbernies or {}) do
		bernies[#bernies + 1] = bernie
	end
	for _, bernie in ipairs(bernies) do
		if bernie:IsValid() then
			if removed.willow_burnignbernie then
				-- onLeaderChanged only adds canlight and its private listener;
				-- ending a burning task also re-adds canlight. Use the vanilla
				-- inactive transition to discard both, including active flames.
				bernie:GoInactive()
			else
				bernie:onLeaderChanged(player)
			end
		end
	end
end

local function RefreshWolfgang(player, removed)
	local changed = false
	for i = 1, 5 do
		local skill = "wolfgang_overbuff_" .. i
		if removed[skill] then
			player:RemoveTag(skill)
			changed = true
		end
	end
	if changed then
		local mightiness = player.components.mightiness
		mightiness:SetOverMax(0)
		if mightiness:GetCurrent() > mightiness:GetMax() then
			mightiness:DoDelta(mightiness:GetMax() - mightiness:GetCurrent())
		end
	end
end

local function RefreshWoodie(player, removed)
	if player:IsWerebeaver() then
		if removed.woodie_curse_beaver_1 and player.components.worker then
			player.components.worker:SetAction(ACTIONS.MINE, 0.5)
		end
		if removed.woodie_curse_beaver_2 and player.components.worker then
			player.components.worker:SetAction(ACTIONS.CHOP, 4)
		end
		if removed.woodie_curse_beaver_3 then
			player:RemoveTag("toughworker")
		end
	elseif player:IsWeremoose() then
		if removed.woodie_curse_moose_2 then
			player.components.health:RemoveRegenSource(player, "weremoose_skill")
		end
		if removed.woodie_curse_epic_moose then
			player.components.planardefense:RemoveBonus(player, "weremoose_skill")
		end
	elseif player:IsWeregoose() then
		if removed.woodie_curse_goose_2 then
			player.components.moisture:SetInherentWaterproofness(TUNING.WATERPROOFNESS_LARGE)
		end
		if removed.woodie_curse_goose_3 then
			player:RemoveComponent("attackdodger")
		end
	end
end

local function RefreshWathgrithr(player, removed)
	local inspiration = player.components.singinginspiration
	local songs = inspiration.active_songs
	local first_removed
	for i, song in ipairs(songs) do
		if song.REQUIRE_SKILL and removed[song.REQUIRE_SKILL] then
			first_removed = i
			break
		end
	end
	if first_removed then
		local keep = {}
		for i = first_removed, #songs do
			local song = songs[i]
			if not (song.REQUIRE_SKILL and removed[song.REQUIRE_SKILL]) then
				keep[#keep + 1] = song
			end
		end
		for i = #songs, first_removed, -1 do
			inspiration:PopSong()
		end
		for _, song in ipairs(keep) do
			inspiration:AddSong(song, true)
		end
	end
end

local REFRESH = {
	wathgrithr = RefreshWathgrithr,
	willow = RefreshWillow,
	wolfgang = RefreshWolfgang,
	woodie = RefreshWoodie,
	wilson = function(player, removed)
		if removed.wilson_beard_7 and player.components.beard then
			player.components.beard:UpdateBeardInventory()
		end
	end,
	wormwood = function(player, removed)
		if removed.wormwood_blooming_speed1 or removed.wormwood_blooming_speed2 then
			local bloomness = player.components.bloomness
			bloomness:SetDurations(TUNING.WORMWOOD_BLOOM_STAGE_DURATION, bloomness.full_bloom_duration)
		end
	end,
}

local function ResetSkillTree(player)
	local updater = player and player.components.skilltreeupdater
	if not updater or not SKILLTREE_DEFS[player.prefab] then
		return
	end

	-- Snapshot before callbacks mutate the selection; never pass locks or
	-- infographic nodes to DeactivateSkill. Preserve accumulated insight XP.
	local skills, removed = {}, {}
	for skill in pairs(updater:GetActivatedSkills() or {}) do
		skills[#skills + 1] = skill
	end
	if #skills == 0 then
		return
	end
	table.sort(skills)
	for _, skill in ipairs(skills) do
		updater:DeactivateSkill(skill)
		if not updater:IsActivated(skill) then
			removed[skill] = true
		end
	end
	local refresh = REFRESH[player.prefab]
	if refresh then
		refresh(player, removed)
	end
	player:PushEvent("unlockrecipe")
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst:AddTag("CLASSIFIED")

	-- Non-networked crafting action, not a persistent inventory item.
	inst.persists = false
	inst:DoTaskInTime(0, inst.Remove)

	if not TheWorld.ismastersim then
		return inst
	end

	inst.OnBuiltFn = function(inst, builder)
		ResetSkillTree(builder)
	end
	return inst
end

return Prefab("skilltree_respec_tool", fn)
