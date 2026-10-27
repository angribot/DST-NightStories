local MODROOT = MODROOT
GLOBAL.setfenv(1, GLOBAL)

local SPEECHES = {
	civi = require("speech_civi"),
	miotan = require("speech_miotan"),
}

local strings = {
	ANNOUNCE_GLASSIC_BROKE = "WEAPON BREAK!",
	ACTIONS = {
		BLINK = {
			FUEL = "Shadowpoof",
		},
		BLINK_MAP = {
			FUEL = "Shadowpoof({uses})",
		},
		CHANGE_TACKLE = {
			CRYSTAL = "Boost Sword",
			BATTERY = "Set Battery",
		},
		COOKPACKAGE = "Pacook",
		FUELPOCKETWATCH = "Hack",
		-- MOONLIGHTSHADOW_CHARGE = "Charge",
		LUNARSHADOWCHARGE = "Charge",
		LUNARSHADOWSTATE = "Switch State",
		TOGGLETOTEM = {
			ON = "Activate",
			OFF = "Deactivate",
		},
	},
	UI = {
		CRAFTING = {
			RECIPEACTION = {
				SOULSPLIT = "Split",
			},
		},
	},
	NAMES = {
		CIVI = "Civi",
		LIGHTAMULET = "Light Amulet",
		DARKAMULET = "Dark Amulet",
		NIGHTPACK = "Night Pack",
		NIGHTPACK_BLIGHTED = "Blighted {backpack}",
		NIGHTPACK_RED = "Red Night Pack",
		NIGHTPACK_BLUE = "Blue Night Pack",
		NIGHTPACK_PURPLE = "Purple Night Pack",
		NIGHTPACK_YELLOW = "Yellow Night Pack",
		NIGHTPACK_ORANGE = "Orange Night Pack",
		NIGHTPACK_GREEN = "Green Night Pack",
		NIGHTPACK_OPAL = "Opal Night Pack",
		-- NIGHTPACK_DARK = "Dark Night Pack",
		-- NIGHTPACK_LIGHT = "Light Night Pack",
		NIGHTPACK_FUEL = "Night Pack",
		DARKCRYSTAL = "Dark Crystal",
		LIGHTCRYSTAL = "Light Crystal",
		DARKGEM = "Dark Gem",
		LIGHTGEM = "Light Gem",
		DARKMAGATAMA = "Dark Magatama",
		LIGHTMAGATAMA = "Light Magatama",

		FRIENDSHIPRING = "Ring of Friendship",
		FRIENDSHIPTOTEM_DARK = "Infused Dark Totem",
		FRIENDSHIPTOTEM_LIGHT = "Infused Light Totem",
		BUFF_FRIENDSHIPTOTEM_DARK = "Infused Dark Totem",
		BUFF_FRIENDSHIPTOTEM_LIGHT = "Infused Light Totem",

		MIOTAN = "Mio",
		FUELPOCKETWATCH = "hacking Backtrek Watch",

		DUMMY = "Dummy",
		LOSE_SANITY = "the lost of sanity",
		BLACKHOLESTAFF = "Blackhole Staff",
		BOOK_HARVEST = "Season of Harvest",
		BOOK_TOGGLEDOWNFALL = "Love of Rain",
		-- NIGHTMARE_SPEAR = "Nightmare Spear",
		SHADOWGLASH_BUILDER = "Power of Nightmare",

		BATTLERUINSHAT = "Battle Crown",

		SPICE_CACTUS = "Cactus Powder",
		SPICE_CACTUS_FOOD = "Cactus {food}",

		SPICE_MOONGLASS = "Lunar Powder",
		SPICE_MOONGLASS_FOOD = "Mystic {food}",

		PORTABLE_WARDROBE_WRAP = "Magic Dress",
		PORTABLE_WARDROBE_ITEM = "Portable Wardrobe",

		CHESSPIECE_HEADUCK = "Headuck Figure",
		CHESSPIECE_HEADUCK_BUILDER = "Headuck Figure",

		BOOK_WETNESS = "The Wetness",
		SKILLTREE_RESPEC_TOOL = STRINGS.SKILLTREE.RESPEC,
		-- Glassic items

		GLASSICCUTTER = "Glassic Cutter",
		GLASSICCUTTER_MOONGLASS = "Gestalt Cutter",
		GLASSICCUTTER_MOONROCK = "Frost Cutter",
		GLASSICCUTTER_DREAM = "Musou Isshin",
		GLASSICCUTTER_FROST = "Frost Mourning",
		MOONGLASSHAMMER = "Moon Glass Hammer",
		MOONGLASSPICKAXE = "Moon Glass Pickaxe",
		MOONLIGHT_SHADOW = "Moonlight Shadow",
		LUNARSHADOW = "Lunar Shadow",

		-- Lunarplant items
		BAT_LUNARPLANT = "Brightshade Spike Bat",
		-- Voidcloth items
		HORRORCHAIN = "Horror Chain",

		COOKPACKAGEWRAP = "Cooker's Bundling Wrap",
		COOKGIFTWRAP = "Cooker's Gift Wrap",
	},
	RECIPE_DESC = {
		REDGEM = "Change ice into fire.",
		BLUEGEM = "Change fire into ice.",
		NIGHTPACK = "Dark away.",

		FRIENDSHIPRING = "Buff your team.",

		DARKCRYSTAL = "Into Dark!",
		LIGHTCRYSTAL = "Into Light!",

		BLACKHOLESTAFF = "Absorb everything!",
		BOOK_HARVEST = "Should help you harvest!",
		BOOK_TOGGLEDOWNFALL = "/toggledownfall",
		BOOK_WETNESS = "The mystery of weather.",
		-- NIGHTMARE_SPEAR = "Disappear in a moment.",
		SHADOWGLASH_BUILDER = "Disappear in a moment.",

		BATTLERUINSHAT = "Complete with ancient force field!",
		SKILLTREE_RESPEC_TOOL = "Quick way to reset insight.",

		BAT_LUNARPLANT = "Deadly food deals deadly damage.",
		LUNARSHADOW = "A sword with super power of both lunar light and nightmare.",
		HORRORCHAIN = "Spread horror.",

		CHESSPIECE_HEADUCK_BUILDER = "I feel headache, but a duck.",
		COOKPACKAGEWRAP = "Package and cook instantly.",
		COOKGIFTWRAP = "Wrap things up and cook them!",
		PORTABLE_WARDROBE_ITEM = "Convenient for dressing up a lot.",
		PORTABLE_WARDROBE_WRAP = "Convenient for dressing up.",
		SPICE_CACTUS = "Make sanity great again.",
		SPICE_MOONGLASS = "Grant the power of the moon.",
	},
	SKIN_NAMES = {
		merm_bluefish = "Blue Whale Maid",
		merm_lunar_bluefish = "Moonlit Whale Maid",
		merm_shadow_bluefish = "Shadow Whale Maid",
		civi_none = "Civi",
		armorskeleton_none = "Emperor's New Clothes",
		skeletonhat_glass = "Crystal Skull",
		nightsword_lotus = "Black Lotus",

		miotan_none = "Mio",
		miotan_classic = "Classic",
		lantern_mio = "Camping Lamp",
		-- yellowamulet_heart = "Glowing Heart",

		dummy_none = "Dummy",
		-- greenamulet_heart = "Green Heart",
		raincoat_peggy = "Peggy's Raincoat",

		wx78_potato = "Crop",

		dragonflychest_gingerbread = STRINGS.SKIN_NAMES.treasurechest_gingerbread,
		meatrack_hermit_red = "Hermit's Meat Rack",
		meatrack_hermit_white = "Hermit's Meat Rack",
		hivehat_pigcrown = "Royal Crown",
		hivehat_pigcrown_willow = "Dark Crown",

		eyebrellahat_peggy = "Peggy's Eyebrella",
		alterguardianhat_finger = "Crossed Fingers",

		krampus_sack_invisible = "Pantomimed Krampus Sack",
		dreadstonehat_scrap = "Scrappy Hatm",
		dreadstonehat_trans = "Phantomstone Helm",
		-- Glassic items
		cane_glass = "Gane",
		cane_mossling = "Mosling Cane",
		glassiccutter_dream = "Musou Isshin",
		goldenaxe_victorian = "Fanciful Luxury Axe",
		moonglassaxe_northern = "Moon Nordic Axe",
		moonglassaxe_victorian = "Fanciful Moon Glass Axe",
		moonglasshammer_forge = "Moon Forging Hammer",
		moonglasspickaxe_northern = "Moon Nordic Pickaxe",
		orangestaff_glass = "Rod Of Glass",
		orangestaff_mossling = "Mossia Staff",
		-- lunar items
		lunarplanthat_trans = "Phantomshade Helm",
	},
	SKIN_DESCRIPTIONS = {
		merm_bluefish = "A bowl of rice, then back to work.",
		merm_lunar_bluefish = "Moon-glass ribbons for a midnight snack.",
		merm_shadow_bluefish = "Even shadows need a lunch break.",
		-- characters
		civi_none = "Civi can control magic, turning lights into darks, or turning darks into lights.",
		miotan_none = "Mio cames from another world, where nightmare is everywhere.",
		miotan_classic = "Mio's V1 skin!",
		dummy_none = "Another girl comes from nightmare's world.",

		wx78_potato = "A reworked machine becomes a potato!",

		-- items
		armorskeleton_none = "Only clever people can see it.",
		skeletonhat_glass = "Indiana Jones and the Kingdom of the Crystal Skull XD.",
		nightsword_lotus = "She's back.",

		lantern_mio = "A lamp that is fit for camping.",
		-- yellowamulet_heart = "Glowing Heart",

		-- greenamulet_heart = "Green Heart",
		raincoat_peggy = "Wow! There are lots of Peggy...s!",

		dragonflychest_gingerbread = STRINGS.SKIN_DESCRIPTIONS.treasurechest_gingerbread,
		meatrack_hermit_red = "Mimic HD meatrack by Hermit.",
		meatrack_hermit_white = "Mimic HD meatrack by Hermit.",
		hivehat_pigcrown = "Pig Queen likes it.",
		hivehat_pigcrown_willow = "Pig Queen and Willow like it.",

		eyebrellahat_peggy = "Wow! It's Peggy!",
		alterguardianhat_finger = "It's completely an emoji joke.",

		krampus_sack_invisible = "Convey an incredibly convincing impression of a krampus sack.",

		dreadstonehat_scrap = STRINGS.CHARACTERS.WANDA.DESCRIBE.SCRAPHAT,
		dreadstonehat_trans = "Transparent!",
		-- Glassic items
		cane_glass = "It's a glassic joke, I assume.",
		cane_mossling = "Mossia!",
		glassiccutter_dream = "Inazuma shines eternal!",
		goldenaxe_victorian = "An elegantly engraved golden axe.",
		moonglassaxe_northern = "A resplendent moon axe, its design reminiscent of days of yore.",
		moonglassaxe_victorian = "An elegantly engraved moon axe.",
		moonglasshammer_forge = STRINGS.SKIN_DESCRIPTIONS.hammer_forge,
		moonglasspickaxe_northern = "A resplendent moon pickaxe, its design reminiscent of days of yore.",
		orangestaff_glass = "It's a glassic joke, I assume.",
		orangestaff_mossling = "Mossia!",
		-- lunar items
		lunarplanthat_trans = "Transparent!",
	},
	SKIN_TAG_CATEGORIES = {
		COLLECTION = {
			PEGGY = "Peggy Collection",
		},
	},
	CIVI_LEVELS = {
		FEEL_DARK = "I felt the dark.",
		ALREADY_DARK = "I've already in the dark.",
		FEEL_LIGHT = "I felt the light.",
		ALREADY_LIGHT = "I've already in the light.",
	},
	CHARACTERS = {
		GENERIC = {
			ANNOUNCE_ATTACH_BUFF_GLASH = "Secret power from the moon!",
			ANNOUNCE_ATTACH_BUFF_SHADOWGLASH = "Secret power from the nightmare!",
			ANNOUNCE_DETACH_BUFF_GLASH = "The moon power has gone.",
			ANNOUNCE_DETACH_BUFF_SHADOWGLASH = "The nightmare power has gone.",
			DESCRIBE = {
				-- GLASSICCUTTER =
				-- {
				--	 GENERIC = "Sharp but probably get broken.",
				--	 MOONGLASS = "Sword with gestalt flash.",
				--	 MOONROCK = "Sword with frost energy.",
				--	 DREAM = "Inazuma shines eternal!",
				--	 FROST = "ao?",
				-- },
				MOONLIGHT_SHADOW = "Secret power comes from the moon.",
				LUNARSHADOW = {
					LUNAR = "I can feel the secret power from the moon.",
					SHADOW = "I can feel the secret power from the nightmare.",
				},
				MOONGLASSHAMMER = STRINGS.CHARACTERS.GENERIC.DESCRIBE.MOONGLASSAXE,
				MOONGLASSPICKAXE = STRINGS.CHARACTERS.GENERIC.DESCRIBE.MOONGLASSAXE,

				NIGHTPACK = {
					GENERIC = "It seems to need some glowing materials.",
					RED = "It shines red.",
					BLUE = "It shines blue.",
					PURPLE = "It shines purple.",
					YELLOW = "It shines yellow.",
					GREEN = "It shines green.",
					ORANGE = "It shines orange.",
					OPAL = "It shines!",
					FUEL = "It doesn't shine.",
				},
				FRIENDSHIPRING = "It's the proof of friendship.",
				FRIENDSHIPTOTEM_DARK = "Darkness will be wide-range spread.",
				FRIENDSHIPTOTEM_LIGHT = "Pureness will be wide-range spread.",

				DARKAMULET = "I can feel the darkness coming.",
				LIGHTAMULET = "I can feel the darkness away.",

				DARKCRYSTAL = "Get closer to dark!",
				LIGHTCRYSTAL = "Get closer to light!",

				DARKGEM = "It seems no use.",
				LIGHTGEM = "It seems no use.",

				DARKMAGATAMA = "It seems no use.",
				LIGHTMAGATAMA = "It seems no use.",

				BLACKHOLESTAFF = "???",
				BOOK_HARVEST = "H-A-R-V-E-S-T!",
				BOOK_TOGGLEDOWNFALL = "/toggledownfall",
				NIGHTMARE_SPEAR = "It looks like breaking.",

				BATTLERUINSHAT = "For The King!",

				SPICE_CACTUS = "Make sanity great again.",
				SPICE_MOONGLASS = "Grant the power of the moon.",

				PORTABLE_WARDROBE_WRAP = "Dress up anytime.",
				PORTABLE_WARDROBE_ITEM = "Dress up anywhere.",

				CHESSPIECE_HEADUCK = "󰂷",
				BOOK_WETNESS = "We would be able to see a wet world.",

				BAT_LUNARPLANT = STRINGS.CHARACTERS.GENERIC.DESCRIBE.HAMBAT,
				HORRORCHAIN = "We never now how it spreads horror.",

				COOKPACKAGEWRAP = "Wrapping things up and cook them together.",
				COOKGIFTWRAP = "That's a cooker's wrap!",
			},
		},
		CIVI = deepcopy(SPEECHES["civi"]),
		MIOTAN = deepcopy(SPEECHES["miotan"]),
		WICKERBOTTOM = {
			ACTIONFAIL = {
				READ = {
					NOHARVESTABLE = "Oh, I don't think there are things to harvest.",
				},
			},
		},
		WAXWELL = {
			ACTIONFAIL = {
				READ = {
					NOHARVESTABLE = "Kidding? Nothing to harvest!",
				},
			},
		},
		WURT = {
			ANNOUNCE_READ_BOOK = {
				BOOK_HARVEST = "Oh, breaking crops is awful.",
				BOOK_TOGGLEDOWNFALL = "I couldn't live without water!",
				BOOK_WETNESS = "A lot of water... soggy!",
			},
		},
	},
	-- character
	CHARACTER_NAMES = {
		civi = "Civi",
		miotan = "Mio",
		dummy = "Dummy",
	},
	CHARACTER_TITLES = {
		civi = "Mogician of Light and Dark",
		miotan = "The Nightmare Eater",
		dummy = "The Nightmare Breaker",
	},
	CHARACTER_ABOUTME = {
		civi = "Civi can control magic, turning lights into darks, or turning darks into lights.",
		miotan = "Mio cames from another world, where nightmare is everywhere.",
		dummy = "Dummy also comes from the nightmare world. She is Mio's sister.",
	},
	CHARACTER_DESCRIPTIONS = {
		civi = "*Travel between light and dark.\n*Can control nightmare.",
		miotan = "*World treats her differently.\n*Friend of nightmare.",
		dummy = "*Unfriendly to people.\n*Friend of nightmare.\n*Forgive.",
	},
	CHARACTER_QUOTES = {
		civi = '"Get close to Nightmare!"',
		miotan = '"If I could eat nightmare..."',
		dummy = '"No one plays with me..."',
	},
	CHARACTER_BIOS = {
		civi = {
			{ title = "Birthday", desc = "Feb 25" },
			{
				title = "Favorite Food",
				desc = "Lv.0 - " .. STRINGS.NAMES.BONESOUP .. "\nLv.1 - " .. STRINGS.NAMES.MEATBALLS .. "\nLv.2 - " .. STRINGS.NAMES.VOLTGOATJELLY,
			},
		},
		miotan = {
			{ title = "Birthday", desc = "July 17" },
			{ title = "Favorite Food", desc = "None" },
		},
		dummy = {
			{ title = "Birthday", desc = "July 17" },
			{ title = "Favorite Food", desc = STRINGS.NAMES.NIGHTMAREPIE },
		},
	},
	CHARACTER_SURVIVABILITY = {
		civi = STRINGS.CHARACTER_SURVIVABILITY.wilson,
		miotan = STRINGS.CHARACTER_SURVIVABILITY.wortox,
		dummy = STRINGS.CHARACTER_SURVIVABILITY.wes,
	},
}

GlassicAPI.MergeStringsToGLOBAL(strings)
GlassicAPI.MergeStringsToGLOBAL(require("speech_wortox"), STRINGS.CHARACTERS.MIOTAN, true)
STRINGS.CHARACTERS.DUMMY = STRINGS.CHARACTERS.MIOTAN -- Use mio's quote for now
GlassicAPI.MergeTranslationFromPO(MODROOT .. "languages")

-- Wait for DST Fixed
scheduler:ExecuteInTime(0, function()
	local STRCODE_TALKER = rawget(_G, "STRCODE_TALKER")
	if STRCODE_TALKER then
		STRCODE_TALKER[STRINGS.ANNOUNCE_GLASSIC_BROKE] = "ANNOUNCE_GLASSIC_BROKE"
	end
end)

local function MergeCharacterSpeech(char, source)
	local file, errormsg = io.open(MODROOT .. "scripts/speech_" .. char .. ".lua", "w")
	if not file then
		print("Can't update " .. MODROOT .. "scripts/speech_" .. char .. ".lua" .. "\n" .. tostring(errormsg))
		return
	end
	GlassicAPI.MergeSpeechFile(SPEECHES[char], file, source)
end

function UpdateNsStrings(update_speech)
	if update_speech then
		MergeCharacterSpeech("miotan", "speech_wortox")
		-- MergeCharacterSpeech("dummy")
		MergeCharacterSpeech("civi")
	end
	local file, errormsg = io.open(MODROOT .. "languages/strings.pot", "w")
	if not file then
		print("Can't generate " .. MODROOT .. "languages/strings.pot" .. "\n" .. tostring(errormsg))
		return
	end
	GlassicAPI.MakePOTFromStrings(file, strings)
end
