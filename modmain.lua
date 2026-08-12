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
	"components/bundler",
	"components/combat",
	"components/dryingrack",
	"components/equippable",
	"components/forgerepair",
	-- "components/lptw",
	"components/moisture",
	"components/planarentity",
	"components/sanity",
	"components/skilltreeupdater",
	"components/spellcaster",
	"components/trader",
	-- prefabs
	"prefabs/alterguardianhat",
	"prefabs/antlion",
	"prefabs/beargerfur_sack",
	"prefabs/birdcage",
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
	"prefabs/orangestaff",
	"prefabs/pigking",
	"prefabs/pocketwatch_recall",
	"prefabs/punchingbag",
	"prefabs/raincoat",
	"prefabs/sculptingtable",
	"prefabs/voidcloth_boomerang",
	"prefabs/world",
	-- widgets
	"widgets/itemtile",
	"widgets/statusdisplays",
	"widgets/templates",
	-- root
	-- "only_dazui", -- Temp diabled.
	"tools_mutable",
}
for i = 1, #postinit do
	modimport("postinit/" .. postinit[i])
end
