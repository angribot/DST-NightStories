Assets = {
	Asset("SOUNDPACKAGE", "sound/nightstories.fev"),
	Asset("ANIM", "anim/glash_fx.zip"), -- GLASH FX FOR ROD OF GLASS AND RING OF FRIENDSHIP.
}

PrefabFiles = {
	"bat_lunarplant",
	"battleruinshat",
	"blackholestaff",
	"book_wetness",
	"buff_glash",
	"chesspiece_headuck",
	"civi_crystal",
	"civi",
	"cookpackage",
	"dummy_books",
	"dummy",
	"nightpack",
	"friendshipring",
	"friendshiptotem_buff",
	"glash",
	"horrorchain",
	"lantern_mio_fx",
	"lunarshadow",
	"miotan",
	"moonglasshammer",
	"moonglasspickaxe",
	-- "nightmare_spear",
	"ns_skins",
	"ns_spices",
	"ns_queen_torch_projectile",
	"portable_wardrobe",
	"skilltree_respec_tool",
}

GlassicAPI.InitCharacterAssets("miotan", "FEMALE", Assets)
GlassicAPI.InitCharacterAssets("dummy", "FEMALE", Assets)
GlassicAPI.InitCharacterAssets("civi", "DUCK", Assets)

GlassicAPI.InitMinimapAtlas("ns_minimap", Assets)

GlassicAPI.RegisterItemAtlas("ns_inventoryimages", Assets)
GlassicAPI.RegisterItemAtlas("hud/nightmaretab", Assets)
GlassicAPI.RegisterItemAtlas("hud/dummy_status_health", Assets)
