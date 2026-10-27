local prefabs = {}
-- characters
table.insert(
	prefabs,
	CreatePrefabSkin("civi_none", {
		base_prefab = "civi",
		type = "base",
		assets = {
			Asset("SCRIPT", "scripts/prefabs/player_common.lua"),

			Asset("ANIM", "anim/civi.zip"),
			Asset("ANIM", "anim/ghost_civi_build.zip"),
		},
		skins = { normal_skin = "civi", ghost_skin = "ghost_civi_build" },
		bigportrait = { build = "bigportrait/civi_none.xml", symbol = "civi_none_oval.tex" },
		skin_tags = { "CIVI", "BASE" },
		build_name_override = "civi",
		rarity = "Character",
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("miotan_none", {
		base_prefab = "miotan",
		type = "base",
		assets = {
			Asset("SCRIPT", "scripts/prefabs/player_common.lua"),

			Asset("ANIM", "anim/miotan.zip"),
			Asset("ANIM", "anim/ghost_miotan_build.zip"),
		},
		skins = { normal_skin = "miotan", ghost_skin = "ghost_miotan_build" },
		bigportrait = { build = "bigportrait/miotan_none.xml", symbol = "miotan_none_oval.tex" },
		skin_tags = { "MIOTAN", "BASE" },
		build_name_override = "miotan",
		rarity = "Character",
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("dummy_none", {
		base_prefab = "dummy",
		type = "base",
		assets = {
			Asset("SCRIPT", "scripts/prefabs/player_common.lua"),

			Asset("ANIM", "anim/dummy.zip"),
			Asset("ANIM", "anim/ghost_dummy_build.zip"),
		},
		skins = { normal_skin = "dummy", ghost_skin = "ghost_dummy_build" },
		skin_tags = { "DUMMY", "BASE" },
		bigportrait = { build = "bigportrait/dummy_none.xml", symbol = "dummy_none_oval.tex" },
		build_name_override = "dummy",
		rarity = "Character",
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("miotan_classic", {
		base_prefab = "miotan",
		type = "base",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/miotan_classic.zip"),
			Asset("PKGREF", "anim/dynamic/miotan_classic.dyn"),
			Asset("DYNAMIC_ANIM", "anim/dynamic/ghost_miotan_classic_build.zip"),
			Asset("PKGREF", "anim/dynamic/ghost_miotan_classic_build.dyn"),
			Asset("ATLAS", "bigportraits/miotan_classic.xml"),
		},
		skins = { normal_skin = "miotan_classic", ghost_skin = "ghost_miotan_classic_build" },
		bigportrait = { build = "bigportrait/miotan_classic.xml", symbol = "miotan_classic_oval.tex" },
		skin_tags = { "MIOTAN", "BASE" },
		build_name_override = "miotan_classic",
		rarity = "Glassic",
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("wx78_potato", {
		base_prefab = "wx78",
		type = "base",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/wx78_potato.zip"),
			Asset("PKGREF", "anim/dynamic/wx78_potato.dyn"),
			Asset("ATLAS", "bigportraits/wx78_potato.xml"),
		},
		skins = { normal_skin = "wx78_potato", ghost_skin = "ghost_wx78_build" },
		bigportrait = { build = "bigportrait/wx78_potato.xml", symbol = "wx78_potato_oval.tex" },
		skin_tags = { "WX78", "BASE" },
		build_name_override = "wx78_potato",
		rarity = "Glassic",
	})
)
-- items
table.insert(
	prefabs,
	CreatePrefabSkin("armorskeleton_none", {
		base_prefab = "armorskeleton",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/armor_skeleton_none.zip"),
			Asset("PKGREF", "anim/dynamic/armor_skeleton_none.dyn"),
		},
		build_name_override = "armor_skeleton_none",
		init_fn = function(inst)
			inst.foleysound = nil
			GlassicAPI.BasicInitFn(inst)
		end,
		skin_tags = { "ARMORSKELETON", "GLASSIC" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("skeletonhat_glass", {
		base_prefab = "skeletonhat",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/skeletonhat_glass.zip"),
			Asset("PKGREF", "anim/dynamic/skeletonhat_glass.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		skin_tags = { "SKELETONHAT", "GLASSIC" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("nightsword_lotus", {
		base_prefab = "nightsword",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/nightsword_lotus.zip"),
			Asset("PKGREF", "anim/dynamic/nightsword_lotus.dyn"),
		},
		init_fn = function(inst)
			ns_nightsword_init_fn(inst, "nightsword_lotus")
		end,
		skin_tags = { "NIGHTSWORD" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("lantern_mio", {
		base_prefab = "lantern",
		type = "item",
		rarity = "Reward",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/lantern_mio.zip"),
			Asset("PKGREF", "anim/dynamic/lantern_mio.dyn"),
		},
		prefabs = { "lantern_mio_fx_held", "lantern_mio_fx_ground" },
		init_fn = function(inst)
			lantern_init_fn(inst, "lantern_mio", { "firefly" }, Vector3(67, -7, 0), { 195 / 255, 190 / 255, 120 / 255 })
		end,
		skin_tags = { "LANTERN" },
		fx_prefab = { "lantern_mio_fx_held", "lantern_mio_fx_ground" },
		release_group = 87,
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("yellowamulet_heart", {
		base_prefab = "yellowamulet",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/yellowamulet_heart.zip"),
			Asset("PKGREF", "anim/dynamic/yellowamulet_heart.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		skin_tags = { "YELLOWAMULET" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("greenamulet_heart", {
		base_prefab = "greenamulet",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/greenamulet_heart.zip"),
			Asset("PKGREF", "anim/dynamic/greenamulet_heart.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		skin_tags = { "GREENAMULET" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("raincoat_peggy", {
		base_prefab = "raincoat",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/raincoat_peggy.zip"),
			Asset("PKGREF", "anim/dynamic/raincoat_peggy.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		skin_tags = { "RAINCOAT", "PEGGY" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("dragonflychest_gingerbread", {
		base_prefab = "dragonflychest",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/dragonflychest_gingerbread.zip"),
			Asset("DYNAMIC_ANIM", "anim/dynamic/dragonflychest_upgraded_gingerbread.zip"),
			Asset("PKGREF", "anim/dynamic/dragonflychest_gingerbread.dyn"),
			Asset("PKGREF", "anim/dynamic/dragonflychest_upgraded_gingerbread.dyn"),
		},
		-- init_fn = GlassicAPI.BasicInitFn,
		init_fn = dragonflychest_gingerbread_init_fn,
		build_name_override = "dragonflychest_gingerbread",
		skin_tags = { "DRAGONFLYCHEST" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("meatrack_hermit_red", {
		base_prefab = "meatrack",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/meatrack_hermit_red.zip"),
			Asset("PKGREF", "anim/dynamic/meatrack_hermit_red.dyn"),
		},
		init_fn = function(inst)
			inst.AnimState:SetBank("meatrack_hermit")
			GlassicAPI.BasicInitFn(inst)
		end,
		skin_tags = { "MEATRACK" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("meatrack_hermit_white", {
		base_prefab = "meatrack",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/meatrack_hermit_white.zip"),
			Asset("PKGREF", "anim/dynamic/meatrack_hermit_white.dyn"),
		},
		init_fn = function(inst)
			inst.AnimState:SetBank("meatrack_hermit")
			GlassicAPI.BasicInitFn(inst)
		end,
		skin_tags = { "MEATRACK" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("hivehat_pigcrown", {
		base_prefab = "hivehat",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/hivehat_pigcrown.zip"),
			Asset("PKGREF", "anim/dynamic/hivehat_pigcrown.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		skin_tags = { "HIVEHAT" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("hivehat_pigcrown_willow", {
		base_prefab = "hivehat",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/hivehat_pigcrown_willow.zip"),
			Asset("PKGREF", "anim/dynamic/hivehat_pigcrown_willow.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		skin_tags = { "HIVEHAT" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("eyebrellahat_peggy", {
		base_prefab = "eyebrellahat",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/eyebrellahat_peggy.zip"),
			Asset("PKGREF", "anim/dynamic/eyebrellahat_peggy.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		skin_tags = { "EYEBRELLAHAT", "PEGGY" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("alterguardianhat_finger", {
		base_prefab = "alterguardianhat",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/alterguardianhat_finger.zip"),
			Asset("PKGREF", "anim/dynamic/alterguardianhat_finger.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		skin_tags = { "ALTERGUARDIANHAT" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("goldenaxe_victorian", {
		base_prefab = "goldenaxe",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/goldenaxe_victorian.zip"),
			Asset("PKGREF", "anim/dynamic/goldenaxe_victorian.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		skin_tags = { "GOLDENAXE", "VICTORIAN" },
		release_group = 87,
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("cane_glass", {
		base_prefab = "cane",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/cane_glass.zip"),
			Asset("PKGREF", "anim/dynamic/cane_glass.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		skin_tags = { "CANE", "GLASSIC" },
		granted_items = { "orangestaff_glass" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("moonglassaxe_northern", {
		base_prefab = "moonglassaxe",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/glassaxe_northern.zip"),
			Asset("PKGREF", "anim/dynamic/glassaxe_northern.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		build_name_override = "glassaxe_northern",
		skin_tags = { "MOONGLASSAXE", "GLASSIC" },
		release_group = 87,
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("moonglassaxe_victorian", {
		base_prefab = "moonglassaxe",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/glassaxe_victorian.zip"),
			Asset("PKGREF", "anim/dynamic/glassaxe_victorian.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		build_name_override = "glassaxe_victorian",
		skin_tags = { "MOONGLASSAXE", "GLASSIC" },
		release_group = 87,
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("moonglasshammer_forge", {
		base_prefab = "moonglasshammer",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/glasshammer_forge.zip"),
			Asset("PKGREF", "anim/dynamic/glasshammer_forge.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		build_name_override = "glasshammer_forge",
		skin_tags = { "MOONGLASSHAMMER", "GLASSIC" },
		release_group = 87,
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("moonglasspickaxe_northern", {
		base_prefab = "moonglasspickaxe",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/glasspickaxe_northern.zip"),
			Asset("PKGREF", "anim/dynamic/glasspickaxe_northern.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		build_name_override = "glasspickaxe_northern",
		skin_tags = { "MOONGLASSPICKAXE", "GLASSIC" },
		release_group = 87,
	})
)

-- table.insert(prefabs, CreatePrefabSkin("glassiccutter_dream", {
--	 base_prefab = "glassiccutter",
--	 type = "item",
--	 rarity = "Glassic",
--	 assets = {
--		 Asset( "DYNAMIC_ANIM", "anim/dynamic/glassiccutter_dream.zip" ),
--		 Asset( "PKGREF", "anim/dynamic/glassiccutter_dream.dyn" ),
--	 },
--	 init_fn = function(inst) glassiccutter_init_fn(inst, "glassiccutter_dream") end,
--	 skin_tags = { "GLASSICCUTTER", "GLASSIC" },

-- }))

table.insert(
	prefabs,
	CreatePrefabSkin("orangestaff_glass", {
		base_prefab = "orangestaff",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/orangestaff_glass.zip"),
			Asset("PKGREF", "anim/dynamic/orangestaff_glass.dyn"),
		},
		init_fn = glassic_orangestaff_init_fn,
		skin_sound = {
			["preteleport"] = "dontstarve/common/gem_shatter",
		},
		fx_prefab = { nil, nil, "glash_fx", nil },
		skin_tags = { "ORANGESTAFF", "GLASSIC" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("krampus_sack_invisible", {
		base_prefab = "krampus_sack",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/krampus_sack_invisible.zip"),
			Asset("PKGREF", "anim/dynamic/krampus_sack_invisible.dyn"),
		},
		init_fn = GlassicAPI.BasicInitFn,
		skin_tags = { "KRAMPUS_SACK", "GLASSIC" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("dreadstonehat_scrap", {
		base_prefab = "dreadstonehat",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/dreadstonehat_scrap.zip"),
			Asset("PKGREF", "anim/dynamic/dreadstonehat_scrap.dyn"),
		},
		init_fn = ns_dreadstonehat_init_fn,
		skin_tags = { "DREADSTONEHAT" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("dreadstonehat_trans", {
		base_prefab = "dreadstonehat",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/dreadstonehat_trans.zip"),
			Asset("PKGREF", "anim/dynamic/dreadstonehat_trans.dyn"),
		},
		init_fn = ns_dreadstonehat_init_fn,
		skin_tags = { "DREADSTONEHAT" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("lunarplanthat_trans", {
		base_prefab = "lunarplanthat",
		type = "item",
		rarity = "Glassic",
		assets = {
			-- Asset( "ANIM", "anim/lunarplanthat_trans.zip" ),
			Asset("DYNAMIC_ANIM", "anim/dynamic/lunarplanthat_trans.zip"),
			Asset("PKGREF", "anim/dynamic/lunarplanthat_trans.dyn"),
		},
		init_fn = function(inst)
			lunarplanthat_init_fn(inst, "lunarplanthat_trans")
		end,
		skin_tags = { "LUNARPLANTHAT", "GLASSIC" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("cane_mossling", {
		base_prefab = "cane",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/cane_mossling.zip"),
			Asset("PKGREF", "anim/dynamic/cane_mossling.dyn"),
		},
		init_fn = function(inst)
			cane_init_fn(inst, "cane_mossling")
			GlassicAPI.UpdateFloaterAnim(inst)
		end,
		skin_tags = { "CANE", "GLASSIC" },
		granted_items = { "orangestaff_mossling" },
	})
)

table.insert(
	prefabs,
	CreatePrefabSkin("orangestaff_mossling", {
		base_prefab = "orangestaff",
		type = "item",
		rarity = "Glassic",
		assets = {
			Asset("DYNAMIC_ANIM", "anim/dynamic/orangestaff_mossling.zip"),
			Asset("PKGREF", "anim/dynamic/orangestaff_mossling.dyn"),
		},
		init_fn = function(inst)
			orangestaff_init_fn(inst, "orangestaff_mossling")
			GlassicAPI.UpdateFloaterAnim(inst)
		end,
		skin_sound = {
			["preteleport"] = "dontstarve_DLC001/creatures/mossling/taunt",
			["postteleport"] = "dontstarve_DLC001/creatures/mossling/taunt",
		},
		fx_prefab = { nil, nil, "mossling_spin_fx", nil },
		skin_tags = { "ORANGESTAFF", "GLASSIC" },
	})
)

-- Recruited merms
for _, data in ipairs({
	{ prefab = "merm", build = "merm_bluefish" },
	{ prefab = "merm_lunar", build = "merm_lunar_bluefish" },
	{ prefab = "merm_shadow", build = "merm_shadow_bluefish" },
}) do
	table.insert(
		prefabs,
		CreatePrefabSkin(data.prefab .. "_bluefish", {
			base_prefab = data.prefab,
			type = "item",
			rarity = "Glassic",
			assets = {
				Asset("DYNAMIC_ANIM", "anim/dynamic/" .. data.build .. ".zip"),
				Asset("PKGREF", "anim/dynamic/" .. data.build .. ".dyn"),
			},
			build_name_override = data.build,
			init_fn = ns_merm_bluefish_init_fn,
			skin_tags = { "MERM", "GLASSIC" },
		})
	)
end

return unpack(prefabs)
