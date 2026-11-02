local function zheng(zh, en)
	local LOC = {
		zh = zh,
		zht = zh,
	}
	return LOC[locale] or en
end

version = "1.63.4"
-- basic info --
name = zheng("暗夜故事集", "Night Stories")
author = zheng("鸭子乐园", "Ducklantis")
changelog = zheng(
	[[
- 修复恐惧锁链在部分攻击后可能导致崩溃的问题

最近更新：
- 补齐启迪之冠“交叉手指”皮肤的升级火焰特效
- 注能黑暗图腾和注能光明图腾开启时会在作用范围边缘显示烟雾圈
- 绿影背包改为12格
- 恐惧锁链的传递范围扩大到30
- 恐惧锁链现在可传递薇诺娜的投石机、哑铃、火药、弹弓等范围攻击的伤害
- 同一次攻击不会通过恐惧锁链重复伤害同一目标
- 击杀被锁链的目标时，这次攻击仍会传递给附近被锁链的目标
]],
	[[
- Fixed a crash that could occur after certain attacks involving Horror Chain

Recent Changes:
- Added missing upgraded flame effects to the Enlightened Crown's Crossed Fingers skin
- Infused Dark Totem and Infused Light Totem now show a smoke ring at the edge of their range while active
- Green Night Pack now has 12 slots
- Horror Chain now spreads damage up to 30 units away
- Horror Chain now spreads damage from area attacks such as Winona's Catapult, Dumbbells, Gunpowder and Slingshot ammo
- A single attack no longer damages the same target more than once through Horror Chain
- Killing a chained target still spreads that attack to nearby chained targets
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
