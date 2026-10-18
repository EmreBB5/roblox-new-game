local Config = require("../src/shared/GameConfig")
local Growth = require("../src/shared/PetGrowth")
local Profile = require("../src/shared/Progression")
local Pets = require("../src/shared/Pets")
local Combat = require("../src/shared/Combat")
local Elite = require("../src/shared/EliteRules")
local n = 0
local function eq(a, b, label)
	n += 1
	assert(a == b, label .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local p = Profile.newProfile()
eq(Growth.info(p, "mossling", Config), nil, "unowned pet has no training info")
eq(Growth.info(p, "fake", Config), nil, "unknown pet rejected")
eq(Growth.award(p, 4, Config), nil, "no equipped pet no XP")
p.equippedPet = "mossling"
eq(Growth.award(p, 4, Config), nil, "unowned equipped id no XP")
eq(next(p.petXP), nil, "invalid award cannot create ownership or XP")
p.pets.mossling = true
local cumulative = 0
for level = 1, 10 do
	p.petXP.mossling = cumulative
	local info = Growth.info(p, "mossling", Config)
	eq(info.level, level, "exact level boundary")
	eq(info.xp, 0, "boundary XP remainder")
	eq(info.totalXP, cumulative, "cumulative XP not consumed")
	eq(info.bonus, 4 + math.floor((level - 1) / 2), "level damage rule")
	eq(Pets.damageBonus(p, Config), info.bonus, "loot helper damage matches growth")
	eq(Combat.stats(p, Config).basicDamage, 25 + info.bonus, "combat damage matches growth")
	if level < 10 then
		local needed = 40 + (level - 1) * 20
		eq(info.xpNeeded, needed, "growing XP requirement")
		p.petXP.mossling = cumulative + needed - 1
		eq(Growth.info(p, "mossling", Config).level, level, "one XP below threshold")
		cumulative += needed
	else eq(info.xpNeeded, 0, "max level no next requirement") end
end
eq(cumulative, 1080, "all nine thresholds sum to cap")
p.petXP.mossling = 39
local gained = Growth.award(p, Config.PetProgression.NormalXP, Config)
eq(gained.previousLevel, 1, "award previous level")
eq(gained.level, 2, "normal kill may level pet")
eq(gained.leveledUp, true, "level-up result")
eq(Growth.info(p, "mossling", Config).xp, 3, "XP rollover")
local before = p.petXP.mossling
for _, bad in {0/0, math.huge, -1, 0} do eq(Growth.award(p, bad, Config), nil, "invalid reward rejected") end
eq(p.petXP.mossling, before, "invalid rewards no mutation")
p.pets.tidefin, p.petXP.tidefin = true, 12
Growth.award(p, 12, Config)
eq(p.petXP.tidefin, 12, "unequipped pet cannot train")
p.equippedPet = "tidefin"
Growth.award(p, Config.PetProgression.BossXP, Config)
eq(p.petXP.tidefin, 42, "equipped pet receives boss XP")
eq(p.petXP.mossling, before + 12, "switch does not transfer XP")
Growth.award(p, 1e100, Config)
eq(p.petXP.tidefin, 1080, "huge finite reward capped")
eq(Growth.info(p, "tidefin", Config).bonus, 8, "max damage bonus eight")
local atMax = Growth.award(p, 30, Config)
eq(atMax.leveledUp, false, "max level no repeated level up")
eq(atMax.totalXP, 1080, "max XP stable")
for version = 1, 4 do
	local migrated = Profile.sanitize({version = version, level = 9, gold = 125, questStatus = "return", classId = "mage", equipmentTier = 2,
		pets = {mossling = true}, equippedPet = "mossling", petPity = {thornwarden = 17}, bossVictories = {thornwarden = 5},
		lastBossClaims = {thornwarden = 1800000000}, materials = {wood = 12}, expedition = {stage = 5, progress = 3}, waypoints = {frost = true}})
	eq(migrated.version, 7, "old profile schema migrated")
	eq(migrated.gold, 125, "migration currency preserved")
	eq(migrated.classId, "mage", "migration class preserved")
	eq(migrated.equipmentTier, 2, "migration equipment preserved")
	eq(migrated.questStatus, "return", "migration legacy quest preserved")
	eq(migrated.petPity.thornwarden, 17, "migration pity preserved")
	eq(migrated.lastBossClaims.thornwarden, 1800000000, "migration replay guard preserved")
	eq(migrated.materials.wood, 12, "migration materials preserved")
	eq(migrated.expedition.progress, 3, "migration expedition preserved")
	eq(migrated.waypoints.frost, true, "migration discovery preserved")
	eq(migrated.petXP.mossling, 0, "old owned pet starts at zero XP")
end
local raw = {pets = {mossling = true, tidefin = true, embercub = true}, petXP = {mossling = math.huge, tidefin = -9, embercub = 1e15, fake = 42}}
local clean = Profile.sanitize(raw)
eq(clean.petXP.mossling, 0, "nonfinite saved pet XP discarded")
eq(clean.petXP.tidefin, 0, "negative saved pet XP clamped")
eq(clean.petXP.embercub, 1080, "saved pet XP capped")
eq(clean.petXP.fake, nil, "unknown saved pet XP discarded")
local unowned = Profile.sanitize({pets = {}, petXP = {mossling = 1000}})
eq(unowned.petXP.mossling, nil, "unowned saved XP discarded")
raw.petXP.embercub = 0
eq(clean.petXP.embercub, 1080, "sanitize XP map independent")
local saved = Profile.snapshot(clean)
clean.petXP.embercub = 0
eq(saved.petXP.embercub, 1080, "in-flight pet XP snapshot independent")
eq(Profile.snapshot(saved).petXP.embercub, 1080, "max pet XP roundtrip")
local freshA, freshB = Profile.newProfile(), Profile.newProfile()
freshA.petXP.mossling = 12
eq(freshB.petXP.mossling, nil, "new profile XP maps isolated")

local frost, desert = Config.Elites.frost_warden, Config.Elites.desert_sentinel
local origin = {x = 10, y = 3, z = 20}
eq(Elite.eligible(9, 2, 900, Config), true, "elite minimum participation")
eq(Elite.eligible(8.99, 99, 900, Config), false, "elite damage threshold")
eq(Elite.eligible(900, 1, 900, Config), false, "elite two accepted hits required")
eq(Elite.eligible(math.huge, 2, 900, Config), false, "elite nonfinite damage rejected")
eq(Elite.eligible(9, 2.5, 900, Config), false, "elite fractional hits rejected")
eq(Elite.eligible(9, 2, 0, Config), false, "elite max HP must be positive")
eq(Elite.hits({x = 24, y = 3, z = 20}, origin, frost), true, "radius exact boundary")
eq(Elite.hits({x = 24.01, y = 3, z = 20}, origin, frost), false, "outside radius")
eq(Elite.hits({x = 10, y = 13, z = 20}, origin, frost), true, "vertical tolerance boundary")
eq(Elite.hits({x = 10, y = 13.01, z = 20}, origin, frost), false, "vertical dodge beyond tolerance")
eq(Elite.hits({x = 10, y = 3, z = 32}, origin, desert), true, "targeted disk exact boundary")
eq(Elite.hits({x = 10, y = 3, z = 32.01}, origin, desert), false, "targeted disk outside")
eq(Elite.hits({x = 0/0, y = 3, z = 20}, origin, frost), false, "NaN target geometry")
eq(Elite.begin(math.huge, origin, frost), nil, "invalid telegraph time")
local channel = Elite.begin(100, origin, frost)
origin.x = 999
eq(channel.origin.x, 10, "telegraph center locked copy")
eq(Elite.ready(channel, 101.499), false, "windup not early")
eq(Elite.ready(channel, 101.5), true, "windup exact ready")
eq(Elite.ready(channel, 99), false, "clock rollback not ready")
local inside = {x = 10, y = 3, z = 20}
eq(Elite.canHit(channel, 101.5, inside, true, true, true, frost), true, "valid delayed hit")
eq(Elite.canHit(channel, 101.49, inside, true, true, true, frost), false, "cannot hit during windup")
eq(Elite.canHit(channel, 101.5, inside, true, true, false, frost), false, "line of sight required")
eq(Elite.canHit(channel, 101.5, inside, false, true, true, frost), false, "dead target excluded")
eq(Elite.canHit(channel, 101.5, inside, true, false, true, frost), false, "untrusted target excluded")
local targeted = Elite.begin(200, {x = 0, y = 3, z = 0}, desert)
eq(Elite.canHit(targeted, 201.2, {x = 13, y = 3, z = 0}, true, true, true, desert), false, "moving from locked target center dodges")
eq(Elite.canHit(targeted, 201.2, {x = 0, y = 3, z = 0}, true, true, true, desert), true, "locked target center still dangerous")
print("Pet growth and elites: " .. n .. " assertions passed")
