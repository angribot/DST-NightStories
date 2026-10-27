local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local FuelRecipe = require("nightstories/shadowglash_recipe")

AddClassPostConstruct("widgets/redux/craftingmenu_hud", function(self)
	local rebuild_recipes = self.RebuildRecipes
	self.RebuildRecipes = function(self, ...)
		rebuild_recipes(self, ...)
		local data = self.valid_recipes[FuelRecipe.RecipeName]
		if data ~= nil then
			data.recipe = FuelRecipe.ResolveRecipe(AllRecipes[FuelRecipe.RecipeName], self.owner.replica.inventory)
		end
	end

	local function refresh()
		self:UpdateRecipes()
	end
	self.inst:ListenForEvent("equip", refresh, self.owner)
	self.inst:ListenForEvent("unequip", refresh, self.owner)
	self:RebuildRecipes()
end)
