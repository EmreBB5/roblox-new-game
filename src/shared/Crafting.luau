local Crafting = {}
local function validAmount(value)
	return type(value) == "number" and value == value and value >= 0 and value < math.huge and value % 1 == 0
end
function Crafting.craft(profile, config)
	if not validAmount(profile.equipmentTier) or profile.equipmentTier > 3 or not validAmount(profile.gold) or type(profile.materials) ~= "table" then return {status = "invalid"} end
	local tier = profile.equipmentTier + 1
	local recipe = config.Equipment[tier]
	if not recipe then return {status = "completed"} end
	if profile.gold < recipe.Gold then return {status = "gold"} end
	for id, amount in recipe.Materials do
		if not validAmount(profile.materials[id]) then return {status = "invalid"} end
		if profile.materials[id] < amount then return {status = "materials"} end
	end
	for id, amount in recipe.Materials do profile.materials[id] -= amount end
	profile.gold -= recipe.Gold
	profile.equipmentTier = tier
	return {status = "crafted", tier = tier}
end
return Crafting
