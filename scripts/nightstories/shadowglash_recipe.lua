local RECIPE_NAME = "shadowglash_builder"
local ingredients = {
	nightmarefuel = { Ingredient("nightmarefuel", 1) },
	horrorfuel = { Ingredient("horrorfuel", 1) },
}

local function get_fuel(inventory)
	return inventory:Has("horrorfuel", 1, true) and "horrorfuel" or "nightmarefuel"
end

local function resolve_recipe(recipe, inventory)
	local name = type(recipe) == "string" and recipe or recipe and recipe.name
	if name ~= RECIPE_NAME then
		return recipe
	end

	-- Keep the shared recipe immutable: each player's available fuel can differ.
	return setmetatable({ ingredients = ingredients[get_fuel(inventory)] }, { __index = AllRecipes[RECIPE_NAME] })
end

return {
	RecipeName = RECIPE_NAME,
	GetFuel = get_fuel,
	ResolveRecipe = resolve_recipe,
}
