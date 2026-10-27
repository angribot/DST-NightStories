local main = {
	-- high priority
	"assets",
	"tuning",
	"strings",
	-- medium priority
	"actions",
	"clothing",
	"containerwidgets",
	"prefabskin",
	"recipes",
	"spices",
	-- low priority
}

for i = 1, #main do
	modimport("main/" .. main[i])
end

local postinit = {
	-- components
	"components/brightmarespawner",
	"components/builder",
	"components/builder_replica",
	"components/bundler",
	"components/combat",
	"components/corruption",
	"components/dryingrack",
	"components/equippable",
	"components/forgerepair",
	-- "components/lptw",
	"components/planarentity",
	"components/sanity",
	"components/skilltreeupdater",
	"components/spellcaster",
	"components/trader",
	"components/wagpunk_arena_manager",
	-- prefabs
	"prefabs/alterguardianhat",
	"prefabs/antlion",
	"prefabs/beargerfur_sack",
	"prefabs/birdcage",
	"prefabs/charlie_boss",
	"prefabs/dragonflychest",
	"prefabs/flower",
	"prefabs/foodbuffs",
	"prefabs/gems",
	"prefabs/gestalt",
	"prefabs/meatrack",
	"prefabs/multiplayer_portal_moonrock",
	"prefabs/nightmarecreatures",
	"prefabs/nightmarefuel",
	"prefabs/nightsword",
	"prefabs/pigking",
	"prefabs/player_classified",
	"prefabs/pocketwatch_recall",
	"prefabs/punchingbag",
	"prefabs/queen_torch",
	"prefabs/raincoat",
	"prefabs/sculptingtable",
	"prefabs/shadow_container",
	"prefabs/staff_common",
	"prefabs/voidcloth_boomerang",
	"prefabs/world",
	-- widgets
	"widgets/itemtile",
	"widgets/redux/craftingmenu_hud",
	"widgets/statusdisplays",
	"widgets/templates",
	-- root
	"only_dazui",
	"tools_mutable",
}
for i = 1, #postinit do
	modimport("postinit/" .. postinit[i])
end
