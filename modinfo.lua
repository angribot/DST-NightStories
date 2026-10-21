local function zheng(zh, en)
	local LOC = {
		zh = zh,
		zht = zh,
	}
	return LOC[locale] or en
end

version = "1.60.3"
-- basic info --
name = zheng("暗夜故事集", "Night Stories")
author = zheng("鸭子乐园", "Ducklantis")
changelog = zheng(
	[[
- 优化了所有动画材质

最近更新：
- 修复雨衣和月光玻璃斧重复触发装备皮肤事件的问题
- 月光玻璃镐和月光玻璃锤卸下时补齐皮肤卸下事件
- 简化配方过滤器配置，适配 Glassic API 的默认规则
- 修复月影配方解锁，改为击败天体后裔后在概念制造器制作，材料不变
- 月影配方排序调整至火花柜之后
]],
	[[
- Optimize all anim packs

Recent Changes:
- Fix duplicate equip-skin events for the raincoat and moon glass axe
- Emit the unequip-skin event when the moon glass pickaxe or hammer is unequipped
- Simplify recipe filter configuration to match Glassic API defaults
- Fix Lunar Shadow's recipe unlock: craft it at the Notional Fabricator after defeating the Celestial Scion, with unchanged ingredients
- Sort Lunar Shadow's recipe immediately after the Spark Ark
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
