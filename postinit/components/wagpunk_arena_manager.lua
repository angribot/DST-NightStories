-- local AddPrefabPostInit = AddPrefabPostInit
local AddComponentPostInit = AddComponentPostInit
---@diagnostic disable-next-line
GLOBAL.setfenv(1, GLOBAL)
AddComponentPostInit("wagpunk_arena_manager", function(self)
	local add_wagboss_defeated_recipes = self.AddWagbossDefeatedRecipes
	function self:AddWagbossDefeatedRecipes()
		add_wagboss_defeated_recipes(self)
		if self.workstation then
			self.workstation.components.craftingstation:LearnItem("lunarshadow", "lunarshadow")
		end
	end
end)
