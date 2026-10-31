local AddRecipe2 = AddRecipe2
local AddCharacterRecipe = AddCharacterRecipe
local SortAfter = GlassicAPI.RecipeSortAfter
local SortBefore = GlassicAPI.RecipeSortBefore
local AddDeconstructRecipe = AddDeconstructRecipe
local AddPlayerPostInit = AddPlayerPostInit
local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function add_tech(tech_name, merge_table, brainjelly, bonus_available)
	if tech_name then
		GlassicAPI.AddTech(tech_name, bonus_available)
		if type(merge_table) == "table" then
			for target, bonus in pairs(merge_table) do
				GlassicAPI.MergeTechBonus(target, tech_name, bonus)
			end
		end
		if brainjelly then
			TECH.LOST[tech_name] = 10
		end
	end
end

local MERGE_TABLES = {
	CIVI = {
		MOONORB_LOW = 1,
		MOONORB_UPGRADED = 2,
		MOON_ALTAR_FULL = 2,
		OBSIDIAN_BENCH = 2,
	},
	DUMMY = {
		ANCIENTALTAR_HIGH = 1,
		OBSIDIAN_BENCH = 1,
	},
}
add_tech("CIVITECH", MERGE_TABLES.CIVI, true, true)
add_tech("DUMMYTECH", MERGE_TABLES.DUMMY, true, true)
local CIVITECH_ONE = { CIVITECH = 1 }
local CIVITECH_TWO = { CIVITECH = 2 }
local DUMMYTECH_ONE = { DUMMYTECH = 1 }

STRINGS.NAMES.CIVI_REDGEM = STRINGS.NAMES.REDGEM
STRINGS.NAMES.CIVI_BLUEGEM = STRINGS.NAMES.BLUEGEM
STRINGS.NAMES.CIVI_DARKCRYSTAL = STRINGS.NAMES.DARKCRYSTAL
STRINGS.NAMES.CIVI_LIGHTCRYSTAL = STRINGS.NAMES.LIGHTCRYSTAL

--------------------
------- Civi -------
--------------------
-- 红宝石 --
AddRecipe2("civi_redgem", { Ingredient("bluegem", 1), Ingredient("nightmarefuel", 1) }, CIVITECH_ONE, {
	nounlock = true,
	builder_tag = "ns_builder_civi",
	product = "redgem",
})

-- 蓝宝石 --
AddRecipe2("civi_bluegem", { Ingredient("redgem", 1), Ingredient("nightmarefuel", 1) }, CIVITECH_ONE, {
	nounlock = true,
	builder_tag = "ns_builder_civi",
	product = "bluegem",
})
SortAfter("civi_bluegem", "civi_redgem")

-- 黑水晶
AddCharacterRecipe("darkcrystal", { Ingredient("purplegem", 1), Ingredient("nightmarefuel", 4) }, TECH.NONE, { builder_tag = "ns_builder_civi", no_deconstruction = true })
SortAfter("darkcrystal", "purplegem")

-- 白水晶
AddCharacterRecipe("lightcrystal", { Ingredient("purplegem", 1), Ingredient("moonglass", 4) }, TECH.NONE, { builder_tag = "ns_builder_civi", no_deconstruction = true })
SortAfter("lightcrystal", "darkcrystal")

-- 纯粹辉煌
AddRecipe2("civi_purebrilliance", { Ingredient("horrorfuel", 1), Ingredient("moonglass", 1) }, TECH.LUNARFORGING_TWO, {
	nounlock = true,
	builder_tag = "ns_builder_civi",
	product = "purebrilliance",
})
SortAfter("civi_purebrilliance", "lunarplant_kit")

-- 亮茄外壳
AddRecipe2("civi_lunarplant_husk", { Ingredient("voidcloth", 1), Ingredient("purebrilliance", 1) }, TECH.LUNARFORGING_TWO, {
	nounlock = true,
	builder_tag = "ns_builder_civi",
	product = "lunarplant_husk",
})
SortAfter("civi_lunarplant_husk", "civi_purebrilliance")

-- 纯粹恐惧
AddRecipe2("civi_horrorfuel", { Ingredient("purebrilliance", 1), Ingredient("nightmarefuel", 1) }, TECH.SHADOWFORGING_TWO, {
	nounlock = true,
	builder_tag = "ns_builder_civi",
	product = "horrorfuel",
})
SortAfter("civi_horrorfuel", "voidcloth_kit")

-- 暗影碎布
AddRecipe2("civi_voidcloth", { Ingredient("lunarplant_husk", 1), Ingredient("horrorfuel", 1) }, TECH.SHADOWFORGING_TWO, {
	nounlock = true,
	builder_tag = "ns_builder_civi",
	product = "voidcloth",
})
SortAfter("civi_voidcloth", "civi_horrorfuel")

-- 影背包 --
AddRecipe2("nightpack", { Ingredient("darkcrystal", 1), Ingredient("lightcrystal", 1), Ingredient("nightmarefuel", 5) }, CIVITECH_ONE, {
	nounlock = true,
	builder_tag = "ns_builder_civi",
	no_deconstruction = function(inst)
		return inst:HasTag("nightpack_blighted")
	end,
})
SortAfter("nightpack", "civi_bluegem")

-- 友爱戒指
AddRecipe2("friendshipring", { Ingredient("moonrocknugget", 4), Ingredient("moonglass", 4), Ingredient("nightmarefuel", 4) }, CIVITECH_TWO, { nounlock = true, builder_tag = "ns_builder_civi" })
SortAfter("friendshipring", "nightpack")

-- 注能图腾
AddDeconstructRecipe("friendshiptotem_dark", { Ingredient("moonrocknugget", 4), Ingredient("moonglass", 4), Ingredient("nightmarefuel", 4), Ingredient("darkcrystal", 1) })
AddDeconstructRecipe("friendshiptotem_light", { Ingredient("moonrocknugget", 4), Ingredient("moonglass", 4), Ingredient("nightmarefuel", 4), Ingredient("lightcrystal", 1) })

AddDeconstructRecipe("darkgem", { Ingredient("darkcrystal", 1) })
AddDeconstructRecipe("lightgem", { Ingredient("lightcrystal", 1) })
AddDeconstructRecipe("darkmagatama", { Ingredient("darkcrystal", 1), Ingredient("nightmarefuel", 1) })
AddDeconstructRecipe("lightmagatama", { Ingredient("lightcrystal", 1), Ingredient("nightmarefuel", 1) })
AddDeconstructRecipe("darkamulet", { Ingredient("thulecite", 2), Ingredient("darkcrystal", 1), Ingredient("nightmarefuel", 4) })
AddDeconstructRecipe("lightamulet", { Ingredient("thulecite", 2), Ingredient("lightcrystal", 1), Ingredient("nightmarefuel", 4) })
---------------------
------- Dummy -------
---------------------

-- 灵魂剥离 --
AddCharacterRecipe("dummy_soulsplit_1", { Ingredient(CHARACTER_INGREDIENT.HEALTH, 20, nil, nil, "decrease_sanity.tex") }, TECH.NONE, {
	builder_tag = "ns_builder_dummy",
	product = "nightmarefuel",
	nameoverride = "dummy_soulsplit_1",
	actionstr = "SOULSPLIT",
})

AddCharacterRecipe("dummy_soulsplit_2", { Ingredient(CHARACTER_INGREDIENT.HEALTH, 60, nil, nil, "decrease_sanity.tex") }, TECH.LOST, {
	builder_tag = "ns_builder_dummy",
	product = "horrorfuel",
	nameoverride = "dummy_soulsplit_2",
	actionstr = "SOULSPLIT",
	canbuild = function(recipe, builder)
		return builder:HasTag("ns_builder_dummy") and TheWorld._atriumgate_repaired
	end,
})
SortAfter("dummy_soulsplit_2", "dummy_soulsplit_1")

-- 梦魇之力 --
AddCharacterRecipe(
	"shadowglash_builder",
	{ Ingredient("nightmarefuel", 1) },
	TECH.NONE,
	{ builder_tag = "ns_builder_dummy", no_deconstruction = true, sg_state = "domediumaction" }
)

-- 收获的季节 --
AddCharacterRecipe(
	"book_harvest",
	{ Ingredient("papyrus", 2), Ingredient(CHARACTER_INGREDIENT.HEALTH, 15, nil, nil, "decrease_sanity.tex") },
	TECH.SCIENCE_TWO,
	{ builder_tag = "ns_builder_dummy" }
)

-- 雨神的眷恋 --
AddCharacterRecipe(
	"book_toggledownfall",
	{ Ingredient("papyrus", 2), Ingredient(CHARACTER_INGREDIENT.HEALTH, 30, nil, nil, "decrease_sanity.tex") },
	TECH.MAGIC_THREE,
	{ builder_tag = "ns_builder_dummy" }
)

-- 黑洞法杖 --
AddRecipe2(
	"blackholestaff",
	{ Ingredient("livinglog", 2), Ingredient("orangegem", 2), Ingredient("nightmarefuel", 4) },
	DUMMYTECH_ONE,
	{ nounlock = true, builder_tag = "ns_builder_dummy" }
)
SortAfter("blackholestaff", "greenstaff")
---------------------
------- Other -------
---------------------

-- Reset Skill Tree --
AddCharacterRecipe("skilltree_respec_tool", { Ingredient("moonglass", 1), Ingredient("nightmarefuel", 1) }, TECH.NONE, { builder_tag = "skilltree_characters" })
SortBefore("skilltree_respec_tool", "transmute_log")

-- 月影 --
AddRecipe2(
	"lunarshadow",
	{ Ingredient("lunar_seed", 5), Ingredient("sword_lunarplant", 1), Ingredient("voidcloth_scythe", 1) },
	TECH.WAGPUNK_WORKSTATION_TWO,
	{
		nounlock = true,
		-- `buffed` is a net_bool, so this check works on both master and clients.
		no_deconstruction = function(inst)
			return inst.buffed ~= nil and inst.buffed:value()
		end,
	}
)
SortAfter("lunarshadow", "wagpunk_workstation_security_pulse_cage")

-- 恐惧锁链 --
AddRecipe2("horrorchain", { Ingredient("horrorfuel", 4), Ingredient("voidcloth", 2) }, TECH.SHADOWFORGING_TWO, { nounlock = true, station_tag = "shadow_forge" })
SortAfter("horrorchain", "voidcloth_scythe")

-- 厨师礼物包装 & 厨师包锅
AddCharacterRecipe(
	"cookpackagewrap",
	{ Ingredient("portablecookpot_item", 1), Ingredient("bundlewrap", 4) },
	TECH.NONE,
	{ builder_tag = "masterchef", numtogive = 4 },
	{ "COOKING" }
)
SortAfter("cookpackagewrap", "portablespicer_item")
AddCharacterRecipe("cookgiftwrap", { Ingredient("portablecookpot_item", 1), Ingredient("giftwrap", 4) }, TECH.NONE, { builder_tag = "masterchef", numtogive = 4 }, { "COOKING" })
SortAfter("cookgiftwrap", "cookpackagewrap")

-- 仙人掌粉 --
AddRecipe2(
	"spice_cactus",
	{ Ingredient("cactus_meat", 2), Ingredient("cactus_flower", 1) },
	TECH.FOODPROCESSING_ONE,
	{ nounlock = true, numtogive = 2, builder_tag = "professionalchef", no_deconstruction = true }
)
SortAfter("spice_cactus", "spice_salt")

-- 月光粉 --
AddRecipe2(
	"spice_moonglass",
	{ Ingredient("purebrilliance", 3) },
	TECH.FOODPROCESSING_ONE,
	{ nounlock = true, numtogive = 2, builder_tag = "professionalchef", no_deconstruction = true }
)
SortAfter("spice_moonglass", "spice_cactus")

-- 便携衣柜 & 魔法礼装 --
AddRecipe2("portable_wardrobe_wrap", { Ingredient("giftwrap", 1), Ingredient("nightmarefuel", 1) }, TECH.MAGIC_THREE, { no_deconstruction = true }, { "MAGIC", "DECOR" })
SortAfter("portable_wardrobe_wrap", "wardrobe", "DECOR")
AddRecipe2("portable_wardrobe_item", { Ingredient("portable_wardrobe_wrap", 3), Ingredient("boards", 4) }, TECH.MAGIC_THREE, { no_deconstruction = true }, { "MAGIC", "DECOR" })
SortAfter("portable_wardrobe_item", "portable_wardrobe_wrap")

-- 鸭子雕像 --
AddRecipe2(
	"chesspiece_headuck_builder",
	{ Ingredient(TECH_INGREDIENT.SCULPTING, 2), Ingredient("rocks", 2) },
	TECH.LOST,
	{ nounlock = true, actionstr = "SCULPTING", image = "chesspiece_headuck.tex" }
)

-- THE 潮涌 --
AddRecipe2(
	"book_wetness",
	{ Ingredient("book_rain", 1), Ingredient("book_temperature", 1), Ingredient("malbatross_feather", 10) },
	TECH.BOOKCRAFT_ONE,
	{ nounlock = true, builder_tag = "reader" }
)
SortAfter("book_wetness", "book_rain")

-- 月镐和月锤 --
AddRecipe2("moonglasspickaxe", { Ingredient("twigs", 2), Ingredient("moonglass", 3) }, TECH.CELESTIAL_THREE, { description = "moonglassaxe", station_tag = "celestial_station" })
SortAfter("moonglasspickaxe", "moonglassaxe")

AddRecipe2(
	"moonglasshammer",
	{ Ingredient("twigs", 3), Ingredient("cutgrass", 6), Ingredient("moonglass", 3) },
	TECH.CELESTIAL_THREE,
	{ description = "moonglassaxe", station_tag = "celestial_station" }
)
SortAfter("moonglasshammer", "moonglasspickaxe")

AddDeconstructRecipe("glassiccutter", { Ingredient("glasscutter", 1) })

------------------------------------------------
-- 防止改配方出问题的一个修复
------------------------------------------------
local function clear_nounlock_recipes(inst)
	if inst.components.builder then
		local recipes = inst.components.builder.recipes
		if recipes then
			for i, recipe in ipairs(recipes) do
				if AllRecipes[recipe] and AllRecipes[recipe].nounlock then
					recipes[i] = nil
				end
			end
		end
	end
end

AddPlayerPostInit(function(inst)
	if not TheWorld.ismastersim then
		return
	end

	local onload = inst.OnLoad
	---@diagnostic disable-next-line
	inst.OnLoad = function(inst, ...)
		if onload then
			onload(inst, ...)
		end
		clear_nounlock_recipes(inst)
	end
	clear_nounlock_recipes(inst)
end)
