GLOBAL.setfenv(1, GLOBAL)

local FuelRecipe = require("nightstories/shadowglash_recipe")
local BuilderReplica = require("components/builder_replica")

local has_ingredients = BuilderReplica.HasIngredients
function BuilderReplica:HasIngredients(recipe, ...)
	return has_ingredients(self, FuelRecipe.ResolveRecipe(recipe, self.inst.replica.inventory), ...)
end
