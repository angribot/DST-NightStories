local function zheng(zh, en)
	local LOC = {
		zh = zh,
		zht = zh,
	}
	return LOC[locale] or en
end

version = "1.60.1"
-- basic info --
name = zheng("暗夜故事集", "Night Stories")
author = zheng("鸭子乐园", "Ducklantis")
-- stylua: ignore
changelog = zheng([[
- 修复月影配方解锁，改为击败天体后裔后在概念制造器制作，材料不变
- 月影配方排序调整至火花柜之后

最近更新：
- 暗影魔术箱共享空间内的书籍可像书架一样缓慢恢复耐久
- 任一有效魔术箱、魔术帽或暗影切斯特附近有图书管理员时加速恢复，效果不叠加
]], [[
- Fix Lunar Shadow's recipe unlock: craft it at the Notional Fabricator after defeating the Celestial Scion, with unchanged ingredients
- Sort Lunar Shadow's recipe immediately after the Spark Ark

Recent Changes:
- Books in shared shadow storage slowly recover durability as on a bookshelf
- A librarian near any eligible Magician's Chest, magician's top hat, or Shadow Chester speeds up recovery without stacking
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
