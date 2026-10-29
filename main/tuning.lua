local wilson_attack = 34

-- Civi --
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.CIVI = {}

TUNING.CIVI_BASE_STATUS = 175
TUNING.CIVI_HEALTH = TUNING.CIVI_BASE_STATUS
TUNING.CIVI_HUNGER = TUNING.CIVI_BASE_STATUS
TUNING.CIVI_SANITY = TUNING.CIVI_BASE_STATUS

TUNING.CIVI_BASE_SANITY_MULT = 0.75

TUNING.TOTEM_BUFF_RANGE = 15

TUNING.CIVI_EXCLUDE_DEBUFFS = {
	buff_medal_suckingblood = true,
	buff_medal_mermcurse = true,
}

TUNING.CIVI_VOIDCLOTH_BOOMERANG_CHAIN_DURATION = 3

-- Mio --
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.MIOTAN = {
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
}
TUNING.MIOTAN_STATUS = 100
TUNING.MIOTAN_HEALTH = TUNING.MIOTAN_STATUS
TUNING.MIOTAN_HUNGER = TUNING.MIOTAN_STATUS
TUNING.MIOTAN_SANITY = TUNING.MIOTAN_STATUS

TUNING.MIOTAN_SANITY_DAPPERNESS = -1 / 18
TUNING.MIOTAN_SANITY_NIGHT_MULT = -TUNING.WENDY_SANITY_MULT
TUNING.MIOTAN_SANITY_MULT = TUNING.WENDY_SANITY_MULT

TUNING.MIOTAN_STALE_HUNGER_RATE = -0.5
TUNING.MIOTAN_STALE_HEALTH_RATE = 0
TUNING.MIOTAN_SPOILED_HUNGER_RATE = -1
TUNING.MIOTAN_SPOILED_HEALTH_RATE = -0.5

TUNING.MIOTAN_BOOST_ABSORPTION = 0.6
TUNING.MIOTAN_BOOST_MINTEMP = 10
TUNING.MIOTAN_RUN_SPEED = TUNING.WILSON_RUN_SPEED * 1.25

TUNING.MIOTAN_AUTO_REFUEL_TABLE = {
	FUELED = {
		player = {
			armorskeleton = { trigger = 1 }, -- 骨甲
			lantern = { trigger = 1 }, -- 提灯
			lighter = { trigger = 1 }, -- 薇洛的打火机
			minerhat = { trigger = 1 }, -- 头灯
			molehat = { trigger = 2, bonus = 2, cost = 2 }, -- 鼹鼠帽
			nightstick = { trigger = 1 }, -- 晨星
			thurible = { trigger = 1 }, -- 香炉
			yellowamulet = { trigger = 1 }, -- 黄符
			purpleamulet = { trigger = 1 }, -- 紫符
			blueamulet = { trigger = 1 }, -- 冰符

			tophat = { trigger = 1 }, -- 高礼貌 & 魔术师魔术帽

			nightpack = { trigger = 1 }, -- 影背包 in Night Stories
			darkamulet = { trigger = 1 }, -- 黑暗护符 in Night Stories
			lightamulet = { trigger = 1 }, -- 光明护符 in Night Stories

			bottlelantern = { trigger = 1 }, -- 瓶灯 in Island Adventures
		},
		boat = { -- Island Adventures
			boat_lantern = { trigger = 1 }, -- 船灯
			ironwind = { trigger = 2, cost = 2 }, -- 螺旋桨
		},
	},
	FINITEUSES = {
		player = {
			orangestaff = { trigger = 2, bonus = 2 }, -- 橙杖
			orangeamulet = { trigger = 50, bonus = 50 }, -- 橙符
			horrorchain = { trigger = 100, bonus = 100, override_fuel = "horrorfuel" }, -- 恐惧锁链
			voidcloth_scythe = { trigger = 100, bonus = 100, override_fuel = "horrorfuel" }, -- 暗影收割者
			sword_lunarplant = { trigger = 100, bonus = 100, override_fuel = "purebrilliance" }, -- 亮茄剑
			staff_lunarplant = { trigger = 25, bonus = 25, override_fuel = "purebrilliance" }, -- 亮茄法杖
		},
	},
}

-- Dummy --
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.DUMMY = {}
TUNING.DUMMY_HEALTH = 200
TUNING.DUMMY_HUNGER = 150
TUNING.DUMMY_SANITY = 200
TUNING.DUMMY_DAMAGE_MULT = 0.75

TUNING.DUMMY_NIGHT_SANITY_MULT = 0
TUNING.DUMMY_SANITY_MULT = 0.5
TUNING.DUMMY_SANITY_AURA = 0.33

TUNING.NIGHTMARE_SPEAR_DAMAGE = wilson_attack * 2
TUNING.NIGHTMARE_SPEAR_PERIOD = 0.2
TUNING.NIGHTMARE_SPEAR_FUELTIME = 25
TUNING.SANITY_LARGER = 40
-- spice_cactus --
TUNING.SPICE_MULTIPLIERS.SPICE_CACTUS = {
	SANITY = 1,
}

TUNING.PORTABLE_WARDROBE_USES = 10
TUNING.HEALTH_FUELPOCKETWATCH_COST = -30
TUNING.HEALTH_FUELPOCKETWATCH_COST_MORE = -50

TUNING.BLACKHOLESTAFF_USES = 5
TUNING.BLACKHOLESTAFF_SANITY_THRESHOLD = 0.5
TUNING.BLACKHOLESTAFF_RANGE_MULT = 2

TUNING.QUEEN_TORCH_AOE_RADIUS = 2
TUNING.QUEEN_TORCH_AOE_RANGE_PADDING = 3

-- Glassic

TUNING.MOONGLASSHAMMER = {
	USES = 75,
	CONSUMPTION = 1.25,
	EFFECTIVENESS = 2,
	DAMAGE = wilson_attack,
	ATTACKWEAR = 2,
	SHADOW_WEAR = 0.5,
}

TUNING.MOONGLASSPICKAXE = {
	USES = 50,
	CONSUMPTION = 1,
	EFFECTIVENESS = 3,
	DAMAGE = wilson_attack,
	ATTACKWEAR = 2,
	SHADOW_WEAR = 0.5,
}

TUNING.LUNARSHADOW = {
	USES = 200,
	BASE_DAMAGE = wilson_attack * 2 - 30,
	BUFFED_DAMAGE = wilson_attack * 2,
	LUNAR_PLANAR_DAMAGE = 30,
	SHADOW_PLANAR_DAMAGE = 18,
	SETBONUS_DAMAGE_MULT = 1.1,
	ALIGN_VS_MULT = 1.1,
	SETBONUS_PLANAR_DAMAGE = 5,
	BATTERIES = {
		-- Lunar > 0
		moonglass = 5,
		moonglass_charged = 20,
		purebrilliance = 50,
		lightcrystal = 50,
		-- Shadow < 0
		nightmarefuel = -10,
		-- thulecite = -20,
		horrorfuel = -50,
		darkcrystal = -50,
	},
	SHADOW_LEVEL = 2,
}

-- HORROR CHAIN
TUNING.HORRORCHAIN_DAMAGE = wilson_attack
TUNING.HORRORCHAIN_PLANAR_DAMAGE = 10
TUNING.HORRORCHAIN_RANGE = 2
TUNING.HORRORCHAIN_USES = 200
TUNING.HORRORCHAIN_DIST = 20
TUNING.HORRORCHAIN_DRUATION = 5
TUNING.HORRORCHAIN_SHADOW_LEVEL = 2

TUNING.BUFF_GLASH_DURATION = 60 * 5
TUNING.BUFF_SHADOWGLASH_DURATION = 60

TUNING.GLASH_BASE_DAMAGE = wilson_attack
TUNING.GLASH_HIT_RANGE = 60

TUNING.SHADOWGLASH_PLANAR_DAMAGE = 25
TUNING.SHADOWGLASH_ENHANCED_PLANAR_DAMAGE = 38
TUNING.SHADOWGLASH_CHAIN_DURATION = 3

TUNING.BAT_LUNARPLANT_DAMAGE = wilson_attack
TUNING.BAT_LUNARPLANT_PLANAR_DAMAGE = 17
