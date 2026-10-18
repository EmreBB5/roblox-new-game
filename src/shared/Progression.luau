local Progression = {}

function Progression.xpNeeded(level: number): number
	return 50 + (math.max(1, math.floor(level)) - 1) * 25
end

function Progression.addXP(level: number, xp: number, amount: number): (number, number)
	xp += math.max(0, math.floor(amount))
	while xp >= Progression.xpNeeded(level) do
		xp -= Progression.xpNeeded(level)
		level += 1
	end
	return level, xp
end

function Progression.newProfile()
	local regionalContracts = {}
	for _, id in {"forest", "marsh", "volcanic", "frost", "desert"} do
		regionalContracts[id] = {status = "available", kills = 0, gathers = 0}
	end
	return {regionalContracts = regionalContracts,version = 7, level = 1, xp = 0, gold = 0, kills = 0,
		questStatus = "available", questKills = 0, hasCrystal = false,
		exploration = {discovered = {}, claimed = {}}, pets = {}, petXP = {}, equippedPet = nil, petPity = {}, bossVictories = {}, lastBossClaims = {}, stardust = 0, classId = "warrior", equipmentTier = 0,
		waypoints = {village = true}, materials = {wood = 0, iron = 0, ember = 0}, expedition = {stage = 1, progress = 0}}
end

function Progression.sanitize(raw: any)
	local profile = Progression.newProfile()
	if type(raw) ~= "table" then return profile end
	for _, key in {"level", "xp", "gold", "kills", "questKills"} do
		local value = raw[key]
		if type(value) == "number" and value == value and math.abs(value) < 1e9 then
			profile[key] = math.max(if key == "level" then 1 else 0, math.floor(value))
		end
	end
	profile.level = math.min(profile.level, 10000)
	profile.xp = math.min(profile.xp, Progression.xpNeeded(profile.level) - 1)
	if raw.questStatus == "active" or raw.questStatus == "return" or raw.questStatus == "completed" then
		profile.questStatus = raw.questStatus
	end
	profile.hasCrystal = raw.hasCrystal == true
	local function bounded(value, cap)
		if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return 0 end
		return math.clamp(math.floor(value), 0, cap)
	end
	profile.questKills = math.min(profile.questKills, 3)
	profile.stardust = bounded(raw.stardust, 100000000)
	for _, id in {"mossling", "tidefin", "embercub"} do
		if type(raw.pets) == "table" and raw.pets[id] == true then
			profile.pets[id] = true
			profile.petXP[id] = bounded(if type(raw.petXP) == "table" then raw.petXP[id] else nil, 1080)
		end
	end
	if type(raw.equippedPet) == "string" and profile.pets[raw.equippedPet] then profile.equippedPet = raw.equippedPet end
	for _, id in {"thornwarden", "tide_sentinel", "ember_drake"} do
		profile.petPity[id] = bounded(if type(raw.petPity) == "table" then raw.petPity[id] else nil, 29)
		profile.bossVictories[id] = bounded(if type(raw.bossVictories) == "table" then raw.bossVictories[id] else nil, 100000000)
		profile.lastBossClaims[id] = bounded(if type(raw.lastBossClaims) == "table" then raw.lastBossClaims[id] else nil, 1000000000000)
	end
	for _, id in {"forest", "marsh", "volcanic", "frost", "desert"} do
		if type(raw.waypoints) == "table" and raw.waypoints[id] == true then profile.waypoints[id] = true end
	end
	for _, id in {"forest", "marsh", "volcanic", "frost", "desert"} do
		local entry = if type(raw.regionalContracts) == "table" then raw.regionalContracts[id] else nil
		if type(entry) == "table" and (entry.status == "active" or entry.status == "completed") then
			profile.regionalContracts[id] = {status = entry.status, kills = bounded(entry.kills, 5), gathers = bounded(entry.gathers, 3)}
		end
	end
	if type(raw.exploration) == "table" then
		for _, id in {"forest_ruins", "marsh_outpost", "volcanic_archive", "frost_watch", "desert_caravan"} do
			local discovered = type(raw.exploration.discovered) == "table" and raw.exploration.discovered[id] == true
			local claimed = type(raw.exploration.claimed) == "table" and raw.exploration.claimed[id] == true
			if discovered or claimed then profile.exploration.discovered[id] = true end
			if claimed then profile.exploration.claimed[id] = true end
		end
	end
	if raw.classId == "mage" then profile.classId = "mage" end
	profile.equipmentTier = bounded(raw.equipmentTier, 3)
	for _, id in {"wood", "iron", "ember"} do
		profile.materials[id] = bounded(if type(raw.materials) == "table" then raw.materials[id] else nil, 100000000)
	end
	if type(raw.expedition) == "table" then
		profile.expedition.stage = math.max(1, bounded(raw.expedition.stage, 7))
		local target = if profile.expedition.stage <= 3 then 5 elseif profile.expedition.stage == 4 then 1 elseif profile.expedition.stage <= 6 then 8 else 0
		profile.expedition.progress = bounded(raw.expedition.progress, target)
	end
	return profile
end

-- Validated copy creates fresh nested collections for every in-flight save.
function Progression.snapshot(profile)
	return Progression.sanitize(profile)
end

function Progression.recordKill(profile, config)
	profile.kills += 1
	profile.level, profile.xp = Progression.addXP(profile.level, profile.xp, config.KillXP)
	if profile.questStatus == "active" then
		profile.questKills = math.min(config.QuestTarget, profile.questKills + 1)
		if profile.questKills >= config.QuestTarget then profile.questStatus = "return" end
	end
end

-- Normal kills and nearby party assists use the same atomic progression path.
function Progression.recordRegionKill(profile, regionId, xp, config)
	local region = config.Regions[regionId]
	if not region or type(xp) ~= "number" or xp ~= xp or xp < 0 or xp == math.huge then return false end
	profile.kills += 1
	profile.level, profile.xp = Progression.addXP(profile.level, profile.xp, xp)
	if regionId == "forest" and profile.questStatus == "active" then
		profile.questKills = math.min(config.QuestTarget, profile.questKills + 1)
		if profile.questKills >= config.QuestTarget then profile.questStatus = "return" end
	end
	if region.Material and profile.materials[region.Material] then
		profile.materials[region.Material] = math.min(100000000, profile.materials[region.Material] + 1)
	end
	return true
end

-- Synchronous transition: repeated interactions cannot award the same turn-in twice.
function Progression.interact(profile, config): string
	if profile.questStatus == "return" then
		profile.questStatus = "completed"
		profile.level, profile.xp = Progression.addXP(profile.level, profile.xp, config.QuestXP)
		profile.gold = math.min(999999999, profile.gold + config.QuestGold)
		profile.hasCrystal = true
		return "completed"
	elseif profile.questStatus == "available" or profile.questStatus == "completed" then
		profile.questKills = 0
		profile.questStatus = "active"
		return "started"
	end
	return "active"
end

return Progression
