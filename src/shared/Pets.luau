-- Pure reward state machine. Caller supplies accepted server combat totals and a
-- server-generated random value. Client remotes must never supply these inputs.
local Pets = {}
local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function Pets.eligible(damage, hits, maxHP, config)
	return finite(damage) and finite(hits) and finite(maxHP) and maxHP > 0
		and damage >= maxHP * config.BossMinDamageFraction
		and hits % 1 == 0 and hits >= config.BossMinAcceptedHits
end
function Pets.equip(profile, petId, config)
	if petId == "" then
		profile.equippedPet = nil
		return true
	end
	if type(petId) ~= "string" or not config.Pets[petId] or profile.pets[petId] ~= true then return false end
	profile.equippedPet = petId
	return true
end
function Pets.damageBonus(profile, config)
	local id = profile.equippedPet
	if type(id) == "string" and config.Pets[id] and profile.pets[id] == true then return config.Pets[id].DamageBonus end
	return 0
end
function Pets.claim(profile, bossId, occurrence, damage, hits, maxHP, roll, config)
	local boss = if type(bossId) == "string" then config.Bosses[bossId] else nil
	if not boss or not config.Pets[boss.PetId] or not finite(occurrence) or occurrence <= 0
		or occurrence % 1 ~= 0 or occurrence > 1000000000000
		or not finite(roll) or roll < 0 or roll >= 1 then return {status = "invalid"} end
	if not Pets.eligible(damage, hits, maxHP, config) then return {status = "ineligible"} end
	if (profile.lastBossClaims[bossId] or 0) >= occurrence then return {status = "claimed"} end
	local pity = (profile.petPity[bossId] or 0) + 1
	local dropped = roll < config.PetDropChance or pity >= config.PetPityLimit
	local duplicate = dropped and profile.pets[boss.PetId] == true
	-- No yielding or random draws after the claim guard: each occurrence grants once.
	profile.lastBossClaims[bossId] = occurrence
	profile.bossVictories[bossId] = math.min(100000000, (profile.bossVictories[bossId] or 0) + 1)
	profile.petPity[bossId] = if dropped then 0 else pity
	profile.gold = math.min(100000000, profile.gold + boss.Gold)
	if dropped then
		profile.pets[boss.PetId] = true
		if duplicate then profile.stardust = math.min(100000000, profile.stardust + config.DuplicateStardust) end
	end
	return {status = "rewarded", xp = boss.XP, gold = boss.Gold,
		petId = if dropped then boss.PetId else nil, duplicate = duplicate, pity = profile.petPity[bossId]}
end
return Pets
