local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local SHADOWGLASH = "shadowglash_builder"

AddClassPostConstruct("widgets/redux/craftingmenu_hud", function(self)
	local rebuild_recipes = self.RebuildRecipes
	self.RebuildRecipes = function(self, ...)
		rebuild_recipes(self, ...)
		local data = self.valid_recipes[SHADOWGLASH]
		if data ~= nil then
			-- Show the fuel this player would pay; see main/recipes.lua.
			data.recipe = AllRecipes[SHADOWGLASH].ForInventory(self.owner.replica.inventory)
		end
	end

	local function refresh()
		self:UpdateRecipes()
	end
	self.inst:ListenForEvent("equip", refresh, self.owner)
	self.inst:ListenForEvent("unequip", refresh, self.owner)
	self:RebuildRecipes()
end)
