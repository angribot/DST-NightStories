GLOBAL.setfenv(1, GLOBAL)

local DummyIngredient = require("nightstories/dummyingredient")
local FuelRecipe = require("nightstories/shadowglash_recipe")
local BuilderReplica = require("components/builder_replica")

local has_character_ingredient = BuilderReplica.HasCharacterIngredient
function BuilderReplica:HasCharacterIngredient(ingredient, ...)
	return has_character_ingredient(self, DummyIngredient.Resolve(ingredient, self.inst), ...)
end

local has_ingredients = BuilderReplica.HasIngredients
function BuilderReplica:HasIngredients(recipe, ...)
	return has_ingredients(self, FuelRecipe.ResolveRecipe(recipe, self.inst.replica.inventory), ...)
end
