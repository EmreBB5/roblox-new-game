local Config = require("../src/shared/GameConfig")
local Schedule = require("../src/shared/BossSchedule")
local Pets = require("../src/shared/Pets")
local Progression = require("../src/shared/Progression")
local count = 0
local function eq(actual, expected, label)
	count += 1
	assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local hour = 1800000000 -- exactly on a UTC hour boundary
for index, id in Config.BossOrder do
	local start = hour + Config.Bosses[id].Minute * 60
	eq(Schedule.production(start - 0.01, Config), nil, "no early spawn " .. id)
	local event = Schedule.production(start, Config)
	eq(event.bossId, id, "UTC boss order")
	eq(event.occurrence, start, "stable occurrence")
	eq(Schedule.production(start + Config.BossDuration - 0.01, Config).occurrence, start, "late poll keeps occurrence")
	eq(Schedule.production(start + Config.BossDuration, Config), nil, "exclusive end boundary")
	eq(Schedule.next(start, Config).startsAt, start + 1200, "next skips current boundary")
end
local later = hour + 72 * 3600 + 1200 + 8
local laterEvent = Schedule.production(later, Config)
eq(laterEvent.startsAt, hour + 72 * 3600 + 1200, "no drift after skipped days")
eq(Schedule.production(0/0, Config), nil, "NaN clock rejected")
eq(Schedule.next(math.huge, Config), nil, "infinite clock rejected")
local epoch = hour + 123
local previous = 0
for slot = 0, 5 do
	local elapsed = 20 + slot * 180
	eq(Schedule.studio(elapsed - 0.01, Config, epoch), nil, "demo not early")
	local event = Schedule.studio(elapsed, Config, epoch)
	eq(event.bossId, Config.BossOrder[slot % 3 + 1], "demo rotation")
	eq(event.occurrence, epoch + elapsed, "demo occurrence anchored")
	eq(event.occurrence > previous, true, "demo distinct occurrences")
	previous = event.occurrence
	eq(Schedule.studio(elapsed + 120, Config, epoch), nil, "demo ends")
end
eq(Schedule.studio(20, Config, nil), nil, "demo needs epoch")
eq(Schedule.studioNext(0, Config, epoch).startsAt, epoch + 20, "first demo announcement")
eq(Schedule.studioNext(20, Config, epoch).startsAt, epoch + 200, "demo future schedule")
eq(Pets.eligible(35, 3, 3500, Config), true, "eligibility exact damage threshold")
eq(Pets.eligible(34.999, 99, 3500, Config), false, "damage threshold required")
eq(Pets.eligible(3500, 2, 3500, Config), false, "three hits required")
eq(Pets.eligible(3500, 3.5, 3500, Config), false, "fractional hits rejected")
eq(Pets.eligible(math.huge, 3, 3500, Config), false, "nonfinite damage rejected")
local function claim(p, occurrence, roll, damage, hits)
	return Pets.claim(p, "thornwarden", occurrence, damage or 35, hits or 3, 3500, roll, Config)
end
local p = Progression.newProfile()
for _, roll in {0/0, math.huge, -0.1, 1, 5} do
	eq(claim(p, epoch, roll).status, "invalid", "invalid roll rejected")
end
eq(p.lastBossClaims.thornwarden, nil, "invalid rolls cannot consume claim")
eq(p.petPity.thornwarden, nil, "invalid rolls cannot advance pity")
eq(claim(p, epoch, 0, 1, 2).status, "ineligible", "early participation rejected")
eq(p.gold, 0, "ineligible has no reward")
eq(Pets.claim(p, "fake", epoch, 35, 3, 3500, 0, Config).status, "invalid", "unknown boss rejected")
eq(claim(p, epoch + 0.5, 0).status, "invalid", "fractional occurrence rejected")
local result = claim(p, epoch, 0.03)
eq(result.status, "rewarded", "eligible personal reward")
eq(result.petId, nil, "3 percent upper boundary excluded")
eq(p.petPity.thornwarden, 1, "failed drop advances own pity")
eq(claim(p, epoch, 0).status, "claimed", "same occurrence cannot reroll")
eq(claim(p, epoch - 1, 0).status, "claimed", "older occurrence cannot replay")
eq(p.gold, Config.Bosses.thornwarden.Gold, "claim exactly once")
eq(p.bossVictories.thornwarden, 1, "victory exactly once")
result = claim(p, epoch + 1, 0.029999)
eq(result.petId, "mossling", "below 3 percent drops")
eq(p.petPity.thornwarden, 0, "drop resets pity")
eq(Pets.equip(p, "mossling", Config), true, "owned pet equips")
eq(Pets.damageBonus(p, Config), 4, "equal damage bonus")
eq(Pets.equip(p, "tidefin", Config), false, "unowned pet cannot equip")
eq(Pets.equip(p, "admin", Config), false, "unknown pet cannot equip")
eq(p.equippedPet, "mossling", "failed equip preserves equipped pet")
result = claim(p, epoch + 2, 0)
eq(result.duplicate, true, "duplicate detected")
eq(p.stardust, 10, "duplicate converts to dust")
eq(Pets.equip(p, "", Config), true, "unequip")
eq(Pets.damageBonus(p, Config), 0, "unequipped bonus zero")
local pityProfile = Progression.newProfile()
for victory = 1, 29 do
	result = claim(pityProfile, epoch + victory, 0.999)
	eq(result.petId, nil, "no premature pity " .. victory)
end
eq(pityProfile.petPity.thornwarden, 29, "29 failed eligible victories")
result = claim(pityProfile, epoch + 30, 0.999)
eq(result.petId, "mossling", "30th victory guaranteed")
eq(pityProfile.petPity.thornwarden, 0, "guarantee resets pity")
eq(pityProfile.petPity.tide_sentinel, nil, "boss pity independent")
local second = Progression.newProfile()
eq(claim(second, epoch, 0).petId, "mossling", "second participant has personal independent roll")
eq(second.bossVictories.thornwarden, 1, "no last-hit condition for reward")
local migrated = Progression.sanitize({version = 1, level = 4, xp = 17, gold = 81, questStatus = "return", questKills = 3, hasCrystal = true})
eq(migrated.version, 4, "v1 upgrades")
eq(migrated.level, 4, "v1 level preserved")
eq(migrated.xp, 17, "v1 XP preserved")
eq(migrated.gold, 81, "v1 gold preserved")
eq(migrated.questStatus, "return", "v1 quest preserved")
eq(migrated.hasCrystal, true, "v1 crystal preserved")
local raw = {pets = {mossling = true, fake = true}, equippedPet = "fake", petPity = {thornwarden = math.huge, tide_sentinel = 1000}, bossVictories = {thornwarden = -1}, lastBossClaims = {thornwarden = 0/0}, stardust = math.huge}
local clean = Progression.sanitize(raw)
eq(clean.pets.fake, nil, "unknown saved pet discarded")
eq(clean.pets.mossling, true, "known saved pet kept")
eq(clean.equippedPet, nil, "unknown saved equipped pet discarded")
eq(clean.petPity.thornwarden, 0, "nonfinite saved pity discarded")
eq(clean.petPity.tide_sentinel, 29, "saved pity capped")
eq(clean.bossVictories.thornwarden, 0, "negative victories clamped")
eq(clean.lastBossClaims.thornwarden, 0, "NaN claim discarded")
eq(clean.stardust, 0, "nonfinite dust discarded")
raw.pets.mossling = false
eq(clean.pets.mossling, true, "sanitize does not alias saved collection")
local snapshot = Progression.snapshot(p)
p.pets.mossling = false
p.petPity.thornwarden = 17
p.bossVictories.thornwarden = 99
p.lastBossClaims.thornwarden = epoch + 999
p.stardust = 123
p.equippedPet = "mossling"
eq(snapshot.pets.mossling, true, "save pet snapshot isolated")
eq(snapshot.petPity.thornwarden, 0, "save pity snapshot isolated")
eq(snapshot.bossVictories.thornwarden, 3, "save victory snapshot isolated")
eq(snapshot.lastBossClaims.thornwarden, epoch + 2, "save claim snapshot isolated")
eq(snapshot.stardust, 10, "save dust isolated")
eq(snapshot.equippedPet, nil, "save equipped pet isolated")
local restored = Progression.sanitize(snapshot)
eq(claim(restored, epoch + 2, 0).status, "claimed", "persisted claim survives reconnect")
eq(Schedule.studioNext(20, Config, epoch + 0.5), nil, "demo announcement epoch must be integral")
local independent = Progression.newProfile()
claim(independent, epoch, 0.99)
local tide = Pets.claim(independent, "tide_sentinel", epoch + 1200, 45, 3, 4500, 0.99, Config)
eq(tide.status, "rewarded", "different boss independently eligible")
eq(independent.petPity.thornwarden, 1, "other boss cannot reset forest pity")
eq(independent.petPity.tide_sentinel, 1, "own boss pity advances")
for petId in Config.Pets do
	local owner = Progression.newProfile()
	owner.pets[petId] = true
	eq(Pets.equip(owner, petId, Config), true, "each known pet can equip")
	eq(Pets.damageBonus(owner, Config), 4, "each pet equal power")
end
local malformed = Progression.sanitize({pets = "invalid", petPity = false, bossVictories = 12, lastBossClaims = "invalid", equippedPet = "mossling"})
eq(malformed.equippedPet, nil, "malformed ownership cannot equip saved pet")
eq(malformed.petPity.thornwarden, 0, "malformed nested pity falls back")
eq(malformed.bossVictories.thornwarden, 0, "malformed nested victories falls back")
eq(malformed.lastBossClaims.thornwarden, 0, "malformed nested claims falls back")
local freshA, freshB = Progression.newProfile(), Progression.newProfile()
freshA.pets.mossling = true
freshA.petPity.thornwarden = 8
eq(freshB.pets.mossling, nil, "new profiles do not share ownership")
eq(freshB.petPity.thornwarden, nil, "new profiles do not share pity")
local rich = Progression.newProfile()
rich.gold = 200000000
local richReward = claim(rich, epoch, 0.99)
eq(richReward.status, "rewarded", "high balance boss claim accepted")
eq(rich.gold, 200000000 + Config.Bosses.thornwarden.Gold, "boss reward never reduces high balance")
eq(Progression.snapshot(rich).gold, rich.gold, "high balance boss save roundtrip")
rich.gold = 999999990
claim(rich, epoch + 1, 0.99)
eq(rich.gold, 999999999, "boss reward uses common currency cap")
eq(Progression.snapshot(rich).gold, 999999999, "capped boss reward save roundtrip")
print("Bosses and pets: " .. count .. " assertions passed")
