local function zheng(zh, en)
	local LOC = {
		zh = zh,
		zht = zh,
	}
	return LOC[locale] or en
end

version = "1.66.1"
-- basic info --
name = zheng("暗夜故事集", "Night Stories")
author = zheng("鸭子乐园", "Ducklantis")
changelog = zheng(
	[[
- 澪为腐化国王魔杖缩减冷却改为一次完成，并优先消耗噩梦燃料
- 澪的暗影传送可以使用船上的燃料
- 修复了鼹鼠帽和螺旋桨只剩一份燃料时被免费充能的问题
- 修复了与岛屿冒险同时开启时背包里的燃料被重复计算的问题

最近更新：
- 澪在燃料加速状态下使用懒人魔杖改为暗影传送：不消耗精神，并优先消耗噩梦燃料或纯粹恐惧代替耐久
- 澪在燃料加速状态下为懒人魔杖自动充能时，每份燃料恢复的耐久减半
]],
	[[
- Mio now clears a corrupted King's Staff's cooldown in one go, spending Nightmare Fuel first
- Mio's Shadowpoofs can use fuel stored on her boat
- Fixed Moggles and the Iron Wind refueling for free with only one fuel left
- Fixed backpack fuel being counted twice with Island Adventures enabled

Recent Changes:
- Mio's Lazy Explorer casts become Shadowpoofs while fuel-boosted: they cost no sanity and spend Nightmare Fuel or Pure Horror before durability
- Mio's fuel-boosted auto refuel now restores half as much Lazy Explorer durability per fuel
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
