-- Dummy pays sanity costs from her shared health pool, so sanity costs
-- follow the health rule that crafting must never kill her.
local function Resolve(ingredient, inst)
	if ingredient.type == CHARACTER_INGREDIENT.SANITY and inst.prefab == "dummy" then
		return setmetatable({ type = CHARACTER_INGREDIENT.HEALTH }, { __index = ingredient })
	end
	return ingredient
end

return { Resolve = Resolve }
