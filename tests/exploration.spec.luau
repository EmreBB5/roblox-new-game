local Config = require("../src/shared/GameConfig")
local Profile = require("../src/shared/Progression")
local Exploration = require("../src/shared/Exploration")
local n = 0
local function eq(a, b, label)
	n += 1
	assert(a == b, label .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local p = Profile.newProfile()
p.pets.mossling, p.equippedPet, p.petXP.mossling = true, "mossling", 120
for id, definition in Config.ExplorationSites do
	eq(Exploration.claim(p, id, true, true, Config).status, "undiscovered", "discovery required")
	eq(Exploration.discover(p, id, Config).status, "discovered", "first discovery")
	eq(Exploration.discover(p, id, Config).status, "known", "repeat discovery idempotent")
	eq(Exploration.claim(p, id, false, true, Config).status, "guarded", "guards block personal reward")
	eq(Exploration.claim(p, id, true, false, Config).status, "dead", "dead player cannot claim")
	eq(Exploration.claim(p, id, 1, true, Config).status, "guarded", "clear requires exact boolean")
	eq(Exploration.claim(p, id, true, "true", Config).status, "dead", "alive requires exact boolean")
	eq(p.exploration.claimed[id], nil, "failed claim not consumed")
	local gold, material = p.gold, p.materials[definition.RewardMaterial]
	local result = Exploration.claim(p, id, true, true, Config)
	eq(result.status, "rewarded", "cleared site rewards")
	eq(result.xp, definition.XP, "XP returned for server caller")
	eq(p.gold, gold + definition.Gold, "gold grant")
	eq(p.materials[definition.RewardMaterial], material + 3, "material grant")
	eq(p.petXP.mossling, 120, "chest does not train pet")
	eq(Exploration.claim(p, id, true, true, Config).status, "claimed", "double claim blocked")
	eq(Exploration.claim(p, id, false, true, Config).status, "claimed", "later guard respawn does not reset personal claim")
	eq(p.gold, gold + definition.Gold, "replay cannot duplicate gold")
	local restored = Profile.snapshot(p)
	eq(Exploration.claim(restored, id, true, true, Config).status, "claimed", "reconnect replay blocked")
	local other = Profile.newProfile()
	Exploration.discover(other, id, Config)
	eq(Exploration.claim(other, id, true, true, Config).status, "rewarded", "global clear supports independent personal claims")
end
for _, id in {"admin", {}, false, 5} do
	eq(Exploration.discover(p, id, Config).status, "invalid", "unknown site discovery rejected")
	eq(Exploration.claim(p, id, true, true, Config).status, "invalid", "unknown site claim rejected")
end
local q = Profile.newProfile()
Exploration.discover(q, "forest_ruins", Config)
q.gold = 0/0
eq(Exploration.claim(q, "forest_ruins", true, true, Config).status, "invalid", "NaN currency rejected")
eq(q.exploration.claimed.forest_ruins, nil, "invalid currency no claim mutation")
q.gold, q.materials.wood = 100, math.huge
eq(Exploration.claim(q, "forest_ruins", true, true, Config).status, "invalid", "infinite material rejected")
eq(q.gold, 100, "invalid material no gold mutation")
q.gold, q.materials.wood = 999999990, 100000000
eq(Exploration.claim(q, "forest_ruins", true, true, Config).status, "rewarded", "bounded reward accepted")
eq(q.gold, 999999999, "common gold cap")
eq(q.materials.wood, 100000000, "material cap")
eq(Profile.snapshot(q).gold, 999999999, "capped balance save roundtrip")

for version = 1, 6 do
	local migrated = Profile.sanitize({version = version, level = 7, xp = 23, gold = 120, questStatus = "return", classId = "mage", equipmentTier = 2,
		pets = {mossling = true}, petXP = {mossling = 400}, equippedPet = "mossling", petPity = {thornwarden = 18},
		lastBossClaims = {thornwarden = 1800000000}, materials = {wood = 9}, expedition = {stage = 5, progress = 3}, waypoints = {frost = true},
		regionalContracts = {forest = {status = "active", kills = 4, gathers = 2}}})
	eq(migrated.version, 7, "old profile upgraded")
	eq(migrated.gold, 120, "old currency preserved")
	eq(migrated.petXP.mossling, 400, "old trained pet preserved")
	eq(migrated.petPity.thornwarden, 18, "old boss pity preserved")
	eq(migrated.lastBossClaims.thornwarden, 1800000000, "old boss claim guard preserved")
	eq(migrated.classId, "mage", "old class preserved")
	eq(migrated.equipmentTier, 2, "old gear preserved")
	eq(migrated.materials.wood, 9, "old materials preserved")
	eq(migrated.waypoints.frost, true, "old shrine discovery preserved")
	eq(migrated.expedition.progress, 3, "old expedition preserved")
	eq(migrated.regionalContracts.forest.kills, 4, "old regional contract preserved")
	eq(next(migrated.exploration.discovered), nil, "new site discovery starts empty")
	eq(next(migrated.exploration.claimed), nil, "new chest claims start empty")
end
local raw = {exploration = {discovered = {forest_ruins = false, marsh_outpost = true, volcanic_archive = "true", admin = true}, claimed = {forest_ruins = true, desert_caravan = "true", admin = true}}}
local clean = Profile.sanitize(raw)
eq(clean.exploration.discovered.forest_ruins, true, "claimed normalizes discovered")
eq(clean.exploration.claimed.forest_ruins, true, "true personal claim preserved")
eq(clean.exploration.discovered.marsh_outpost, true, "valid discovery preserved")
eq(clean.exploration.discovered.volcanic_archive, nil, "discovery requires boolean")
eq(clean.exploration.claimed.desert_caravan, nil, "claim requires boolean")
eq(clean.exploration.discovered.admin, nil, "unknown discovery discarded")
eq(clean.exploration.claimed.admin, nil, "unknown claim discarded")
raw.exploration.claimed.forest_ruins = false
eq(clean.exploration.claimed.forest_ruins, true, "loaded claim map isolated")
local saved = Profile.snapshot(clean)
clean.exploration.discovered.marsh_outpost = false
clean.exploration.claimed.forest_ruins = false
eq(saved.exploration.discovered.marsh_outpost, true, "saved discovery map isolated")
eq(saved.exploration.claimed.forest_ruins, true, "saved claim map isolated")
local freshA, freshB = Profile.newProfile(), Profile.newProfile()
freshA.exploration.discovered.frost_watch = true
eq(freshB.exploration.discovered.frost_watch, nil, "new profile discovery maps isolated")
eq(freshA.exploration.claimed.frost_watch, nil, "discovery and claim maps independent")
local malformed = Profile.sanitize({exploration = {discovered = 3, claimed = "invalid"}})
eq(next(malformed.exploration.discovered), nil, "malformed discovery map ignored")
eq(next(malformed.exploration.claimed), nil, "malformed claim map ignored")

local function distance(x, z, tx, tz) return math.sqrt((x - tx) ^ 2 + (z - tz) ^ 2) end
for _, site in Config.ExplorationSites do
	local region = Config.Regions[site.RegionId]
	for _, offset in {{0, 0}, {-12, -4}, {12, -4}, {0, -12}, {0, 24}, {0, 42}} do
		local x, z = site.X + offset[1], site.Z + offset[2]
		eq(distance(x, z, region.X, region.Z) < region.Radius, true, "site landmark/guard/chest/entrance inside biome")
		eq(x > Config.MapBounds.MinX and x < Config.MapBounds.MaxX and z > Config.MapBounds.MinZ and z < Config.MapBounds.MaxZ, true, "site inside map bounds")
	end
	eq(site.Guards, 2, "two registered guards required")
	for _, boss in Config.Bosses do eq(distance(site.X, site.Z, boss.X, boss.Z) > 100, true, "camp avoids boss arena") end
	for _, elite in Config.Elites do eq(distance(site.X, site.Z, elite.X, elite.Z) > 100, true, "camp avoids elite arena") end
	for _, shrine in Config.Waypoints do eq(distance(site.X, site.Z, shrine.Position.x, shrine.Position.z) > 50, true, "camp avoids shrine") end
end
print("Exploration: " .. n .. " assertions passed")
