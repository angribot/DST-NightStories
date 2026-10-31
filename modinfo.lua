local function zheng(zh, en)
	local LOC = {
		zh = zh,
		zht = zh,
	}
	return LOC[locale] or en
end

version = "1.62.5"
-- basic info --
name = zheng("暗夜故事集", "Night Stories")
author = zheng("鸭子乐园", "Ducklantis")
changelog = zheng(
	[[
- 调整了部分配方

最近更新：
- 澪在燃料加速状态下不再受装备的精神值降低效果影响
- 恐惧锁链现在可传递亮茄炸弹的爆炸伤害，同一枚炸弹不会重复伤害同一目标
- 修复“收获的季节”会破坏WX-78扩展空间格子并取走其中物品的问题
- 调整了部分配方
- 修复WX-78“农作物”皮肤的面部动画缺帧与时长异常
- 修复猪王万圣节交易的南瓜炸弹奖励数量，与游戏版本760944保持一致
- 达米新增配方：灵魂剥离 Ⅱ
- 修复澪在燃料加速状态下使用懒人魔杖时未能消耗噩梦燃料来免除精神与耐久消耗的问题
]],
	[[
- Tweak some recipes

Recent Changes:
- Mio is no longer affected by sanity drain from equipment while fuel-boosted
- Horror Chain now spreads Brightshade Bomb explosion damage without the same bomb damaging a target more than once
- Fixed Season of Harvest destroying WX-78's expanded inventory slots and taking their contents
- Tweak some recipes
- Fixed missing facial frames and incorrect timing in WX-78's Crop skin
- Fixed Pig King's Halloween Pumpkin Bomb reward counts to match game version 760944
- Dummy has a new recipe: Soul Split Ⅱ
- Fixed Mio's Lazy Explorer not consuming Nightmare Fuel to prevent sanity and durability loss while fuel-boosted
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
