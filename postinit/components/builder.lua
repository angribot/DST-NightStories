GLOBAL.setfenv(1, GLOBAL)

local SHADOWGLASH = "shadowglash_builder"

-- Dummy pays sanity costs from her shared health pool, so sanity costs
-- follow the health rule that crafting must never kill her.
local function resolve_character_ingredient(ingredient, inst)
	if ingredient.type == CHARACTER_INGREDIENT.SANITY and inst.prefab == "dummy" then
		return setmetatable({ type = CHARACTER_INGREDIENT.HEALTH }, { __index = ingredient })
	end
	return ingredient
end

-- Shadowglash's fuel depends on the builder's inventory; see main/recipes.lua.
local function resolve_recipe(recipe, inventory)
	local name = type(recipe) == "string" and recipe or recipe and recipe.name
	if name ~= SHADOWGLASH then
		return recipe
	end
	return AllRecipes[SHADOWGLASH].ForInventory(inventory)
end

-- Builder --
local Builder = require("components/builder")

local has_character_ingredient = Builder.HasCharacterIngredient
function Builder:HasCharacterIngredient(ingredient, ...)
	return has_character_ingredient(self, resolve_character_ingredient(ingredient, self.inst), ...)
end

local has_ingredients = Builder.HasIngredients
function Builder:HasIngredients(recipe, ...)
	return has_ingredients(self, resolve_recipe(recipe, self.inst.components.inventory), ...)
end

local get_ingredients = Builder.GetIngredients
function Builder:GetIngredients(recname, ...)
	if recname ~= SHADOWGLASH then
		return get_ingredients(self, recname, ...)
	end

	local fuel = AllRecipes[SHADOWGLASH].GetFuel(self.inst.components.inventory)
	-- Record the selected material before consumption, including the last Pure Horror.
	if self.shadowglash_build ~= nil then
		self.shadowglash_build.fuel = fuel
	end
	return { [fuel] = self.inst.components.inventory:GetCraftingIngredient(fuel, 1) }, false
end

local do_build = Builder.DoBuild
function Builder:DoBuild(recname, ...)
	if recname ~= SHADOWGLASH then
		return do_build(self, recname, ...)
	end

	-- Scope the material to this build, so failed or nested builds cannot leak a tier.
	local previous_build = self.shadowglash_build
	self.shadowglash_build = {}
	local success, reason = do_build(self, recname, ...)
	self.shadowglash_build = previous_build
	return success, reason
end

-- Builder Replica --
local BuilderReplica = require("components/builder_replica")

local replica_has_character_ingredient = BuilderReplica.HasCharacterIngredient
function BuilderReplica:HasCharacterIngredient(ingredient, ...)
	return replica_has_character_ingredient(self, resolve_character_ingredient(ingredient, self.inst), ...)
end

local replica_has_ingredients = BuilderReplica.HasIngredients
function BuilderReplica:HasIngredients(recipe, ...)
	return replica_has_ingredients(self, resolve_recipe(recipe, self.inst.replica.inventory), ...)
end
