GLOBAL.setfenv(1, GLOBAL)

local FuelRecipe = require("nightstories/shadowglash_recipe")
local Builder = require("components/builder")

local has_ingredients = Builder.HasIngredients
function Builder:HasIngredients(recipe, ...)
	return has_ingredients(self, FuelRecipe.ResolveRecipe(recipe, self.inst.components.inventory), ...)
end

local get_ingredients = Builder.GetIngredients
function Builder:GetIngredients(recname, ...)
	if recname ~= FuelRecipe.RecipeName then
		return get_ingredients(self, recname, ...)
	end

	local fuel = FuelRecipe.GetFuel(self.inst.components.inventory)
	-- Record the selected material before consumption, including the last Pure Horror.
	if self.shadowglash_build ~= nil then
		self.shadowglash_build.fuel = fuel
	end
	return { [fuel] = self.inst.components.inventory:GetCraftingIngredient(fuel, 1) }, false
end

local do_build = Builder.DoBuild
function Builder:DoBuild(recname, ...)
	if recname ~= FuelRecipe.RecipeName then
		return do_build(self, recname, ...)
	end

	-- Scope the material to this build, so failed or nested builds cannot leak a tier.
	local previous_build = self.shadowglash_build
	self.shadowglash_build = {}
	local success, reason = do_build(self, recname, ...)
	self.shadowglash_build = previous_build
	return success, reason
end
