local function zheng(zh, en)
	local LOC = {
		zh = zh,
		zht = zh,
	}
	return LOC[locale] or en
end

version = "1.61.11"
-- basic info --
name = zheng("暗夜故事集", "Night Stories")
author = zheng("鸭子乐园", "Ducklantis")
changelog = zheng(
	[[
- 使用者精神值不低于50%时，黑洞法杖的吸取范围翻倍

最近更新：
- 修复技能树重置后部分技能效果未正确清除的问题
- 澪在增益状态下使用国王魔杖闪现不再消耗精神值
- 友谊戒指现在支持物品随从、大伯尼、玩家建造的戍卫塔和友方螨地爬
- 同步版本760178的猪王交易逻辑
- 修复达米的精神/血量控件的一些问题
- 月之力与梦魇之力的附加攻击不再触发启迪之冠召唤小月灵
- 国王魔杖可以腐化影背包
- 澪的自动充能可以作用于冷却中的腐化国王魔杖
- 修复人物动画包缺少部分脸部动画帧的问题
- 修复月之力与梦魇之力的附加攻击触发伏特羊电击反伤的问题
- 优化恐惧锁链的攻击联动
- 月之力与梦魇之力的附加伤害不再被查理拦截或反弹
- 女王火炬改为远程范围攻击
- 澪手持女王火炬时自动获得并维持燃料增益
]],
	[[
- The Blackhole Staff's pickup range doubles while the user's sanity is at least 50%

Recent Changes:
- Fixed some skill effects not being properly removed when resetting skill trees
- Mio no longer spends sanity when blinking with the King's Staff while boosted
- The Ring of Friendship now supports item-linked followers, Big Bernie, player-built Guard Towers, and friendly Terramites
- Sync Pig King trading logic from game ver 760178
- Fix some issue with Dummy's Health-sanity badge
- Bonus attacks from moon and nightmare powers no longer trigger Gestalt summons from the Enlightened Crown
- The King's Staff can corrupt Night Packs
- Mio's automatic recharging now works on a corrupted King's Staff while it is on cooldown
- Fix issue that anim packs miss some face frames
- Fixed moon and nightmare bonus attacks triggering Volt Goat electric retaliation
- Improved Horror Chain attack interactions
- Bonus damage from moon and nightmare powers is no longer blocked or reflected by Charlie
- The Queen's Torch now deals ranged area damage
- Mio automatically gains and sustains her fuel buff while holding the Queen's Torch
]]
)
description = zheng("版本: ", "Version: ")
	.. version
	.. zheng("\n\n本次更新:\n", "\n\nChanges:\n")
	.. changelog
	.. "\n"
	.. zheng("“黑夜将至，你准备好了吗？”", '"Night is coming, aren\'t you ready yet?"')

priority = 25

api_version = 10
dst_compatible = true
all_clients_require_mod = true

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

mod_dependencies = {
	{
		workshop = "workshop-2521851770", -- Glassic API
		["GlassicAPI"] = false,
		["Glassic API - DEV"] = true,
	},
}
folder_name = folder_name or "workshop-"
if not folder_name:find("workshop-") then
	name = name .. " - DEV"
end
