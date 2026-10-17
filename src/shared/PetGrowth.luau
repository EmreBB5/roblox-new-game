-- Cumulative XP; no Roblox globals or module loading required by callers.
local PetGrowth = {}
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
function PetGrowth.info(profile, petId, config)
	if type(petId) ~= "string" or not config.Pets[petId] or type(profile.pets) ~= "table" or profile.pets[petId] ~= true then return nil end
	local rules = config.PetProgression
	local total = if type(profile.petXP) == "table" then profile.petXP[petId] else 0
	total = if finite(total) then math.clamp(math.floor(total), 0, rules.MaxXP) else 0
	local level, remaining = 1, total
	while level < rules.MaxLevel do
		local needed = rules.BaseXP + (level - 1) * rules.StepXP
		if remaining < needed then break end
		remaining -= needed
		level += 1
	end
	return {level = level, xp = remaining, xpNeeded = if level == rules.MaxLevel then 0 else rules.BaseXP + (level - 1) * rules.StepXP,
		totalXP = total, bonus = config.Pets[petId].DamageBonus + math.floor((level - 1) / rules.DamageEveryLevels)}
end
function PetGrowth.award(profile, amount, config)
	if not finite(amount) or amount <= 0 then return nil end
	local id = profile.equippedPet
	local before = PetGrowth.info(profile, id, config)
	if not before then return nil end
	if type(profile.petXP) ~= "table" then profile.petXP = {} end
	profile.petXP[id] = math.min(config.PetProgression.MaxXP, before.totalXP + math.floor(amount))
	local after = PetGrowth.info(profile, id, config)
	return {petId = id, previousLevel = before.level, level = after.level, leveledUp = after.level > before.level,
		totalXP = after.totalXP, bonus = after.bonus}
end
return PetGrowth
