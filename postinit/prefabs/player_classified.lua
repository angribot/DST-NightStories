local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local Feedback = require("dummyhealthfeedback")
AddPrefabPostInit("player_classified", Feedback.InitializeClassified)
