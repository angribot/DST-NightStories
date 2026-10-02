local function zheng(zh, en)
	local LOC = {
		zh = zh,
		zht = zh,
	}
	return LOC[locale] or en
end

version = "1.58.8"
-- basic info --
name = zheng("暗夜故事集", "Night Stories")
author = zheng("鸭子乐园", "Ducklantis")
-- stylua: ignore
changelog = zheng([[
- 恢复 Dummy 的梦魇强化：自身引发的陆地理智生物固定为恐怖尖喙，附近遗迹生成的梦魇固定为潜伏梦魇，保留原版生成时机。

最近更新：
- 修复精神光环计算，适配游戏更新。
- 修复月影配方未出现的问题。
- 修复一处数据错误。
- 【极地熊獾桶】永鲜。
- 调整了【月影】的配方要求。
- 调整了入侵溯源表的动作。
- 【注能光明图腾】也能作用于装备对精神的影响了。
- 移除了【暗影破碎枪】。
- 新增【梦魇之力】。
]], [[
- Restore Dummy's nightmare upgrades: personal land sanity spawns become Terrorbeaks, and nearby ruins nightmare spawns become Lurking Nightmares, preserving upstream spawn timing.

Recent Changes:
- Fix sanity aura calculations and update game compatibility.
- Fix issue that the recipe of Lunar Shadow disappears.
- Fix some data error
- Polar Bearger Bin keeps freshness forerver.
- Tweak requirement of the recipe of Lunar Shadow.
- Tweak action for hacking Backtrek Watch.
- Infused Light Totem now buffs equipment dapperness.
- Remove Nightmare Spear.
- Add Power of Nightmare.
]])
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
