local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local Feedback = require("nightstories/dummyhealthfeedback")
AddPrefabPostInit("player_classified", Feedback.InitializeClassified)
