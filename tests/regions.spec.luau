local Config = require("../src/shared/GameConfig")
local Profile = require("../src/shared/Progression")
local Contracts = require("../src/shared/Contracts")
local Enemies = require("../src/shared/EnemyRules")
local n = 0
local function eq(a, b, label)
	n += 1
	assert(a == b, label .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local p = Profile.newProfile()
p.pets.mossling, p.equippedPet, p.petXP.mossling = true, "mossling", 42
for id, config in Config.RegionalContracts do
	eq(Contracts.recordKill(p, id, Config), false, "pre-accept kill ignored")
	eq(Contracts.recordGather(p, id, Config), false, "pre-accept gathering ignored")
	eq(p.regionalContracts[id].kills, 0, "no pre-accept kills counted")
	eq(Contracts.claim(p, id, Config).status, "incomplete", "claim cannot implicitly accept")
	-- Previously discovered shrines are valid when accepting later.
	p.waypoints[id] = true
	eq(Contracts.interact(p, id, Config).status, "accepted", "board starts available contract")
	Contracts.recordKill(p, id, Config)
	eq(Contracts.accept(p, id, Config).status, "active", "repeat accept preserves current contract")
	eq(p.regionalContracts[id].kills, 1, "repeat accept does not reset progress")
	for _ = 1, 8 do Contracts.recordKill(p, id, Config) end
	for _ = 1, 2 do Contracts.recordGather(p, id, Config) end
	eq(Contracts.ready(p, id, Config), false, "all objectives required")
	local gold, material = p.gold, p.materials[config.Material]
	eq(Contracts.claim(p, id, Config).status, "incomplete", "partial objective no claim")
	eq(p.gold, gold, "partial claim currency unchanged")
	Contracts.recordGather(p, id, Config)
	eq(Contracts.ready(p, id, Config), true, "previous discovery counts after other objectives")
	Contracts.recordGather(p, id, Config)
	eq(p.regionalContracts[id].kills, 5, "kills capped")
	eq(p.regionalContracts[id].gathers, 3, "gather interactions capped")
	local result = Contracts.interact(p, id, Config)
	eq(result.status, "rewarded", "complete board interaction grants reward")
	eq(result.xp, config.XP, "player XP returned for authoritative caller")
	eq(p.gold, gold + config.Gold, "gold added once")
	eq(p.materials[config.Material], material + 3, "three materials rewarded")
	eq(p.petXP.mossling, 42, "contract does not grant pet XP")
	eq(Contracts.claim(p, id, Config).status, "completed", "repeated claim rejected")
	eq(Contracts.accept(p, id, Config).status, "completed", "completed contract cannot restart")
	eq(Contracts.recordKill(p, id, Config), false, "completed kills ignored")
	eq(Contracts.recordGather(p, id, Config), false, "completed gathering ignored")
	eq(p.gold, gold + config.Gold, "replay cannot duplicate gold")
	eq(Profile.snapshot(p).regionalContracts[id].status, "completed", "completion persisted")
end
local q = Profile.newProfile()
Contracts.accept(q, "forest", Config)
Contracts.recordKill(q, "marsh", Config)
Contracts.recordGather(q, "marsh", Config)
eq(q.regionalContracts.forest.kills, 0, "wrong region kill ignored")
eq(q.regionalContracts.forest.gathers, 0, "wrong region gathering ignored")
for _ = 1, 5 do Contracts.recordKill(q, "forest", Config) end
for _ = 1, 3 do Contracts.recordGather(q, "forest", Config) end
eq(Contracts.ready(q, "forest", Config), false, "undiscovered waypoint blocks readiness")
eq(Contracts.claim(q, "forest", Config).status, "incomplete", "undiscovered waypoint blocks claim")
q.waypoints.forest = "true"
eq(Contracts.ready(q, "forest", Config), false, "discovery requires boolean")
q.waypoints.forest = true
for _, id in {"admin", {}, 12, false} do
	eq(Contracts.accept(q, id, Config).status, "invalid", "invalid region cannot accept")
	eq(Contracts.claim(q, id, Config).status, "invalid", "invalid region cannot claim")
	eq(Contracts.recordKill(q, id, Config), false, "invalid region cannot progress")
end
q.materials.wood = math.huge
eq(Contracts.claim(q, "forest", Config).status, "invalid", "invalid material rejects whole reward")
eq(q.regionalContracts.forest.status, "active", "invalid reward no completion mutation")
eq(q.gold, 0, "invalid reward no gold mutation")
q.materials.wood, q.gold = 100000000, 999999990
eq(Contracts.claim(q, "forest", Config).status, "rewarded", "bounded reward accepted")
eq(q.gold, 999999999, "common currency cap")
eq(q.materials.wood, 100000000, "material cap")
eq(Profile.snapshot(q).gold, 999999999, "capped reward persists without balance wipe")

for version = 1, 5 do
	local old = Profile.sanitize({version = version, level = 7, xp = 23, gold = 120, questStatus = "return", classId = "mage", equipmentTier = 2,
		pets = {mossling = true}, petXP = {mossling = 400}, equippedPet = "mossling", petPity = {thornwarden = 18},
		lastBossClaims = {thornwarden = 1800000000}, materials = {wood = 9}, expedition = {stage = 5, progress = 3}, waypoints = {frost = true}})
	eq(old.version, 7, "profile schema upgraded")
	eq(old.level, 7, "migration player level preserved")
	eq(old.xp, 23, "migration XP preserved")
	eq(old.gold, 120, "migration gold preserved")
	eq(old.questStatus, "return", "migration legacy quest preserved")
	eq(old.classId, "mage", "migration class preserved")
	eq(old.equipmentTier, 2, "migration equipment preserved")
	eq(old.petXP.mossling, 400, "migration trained pet preserved")
	eq(old.petPity.thornwarden, 18, "migration boss pity preserved")
	eq(old.lastBossClaims.thornwarden, 1800000000, "migration replay guard preserved")
	eq(old.materials.wood, 9, "migration materials preserved")
	eq(old.expedition.progress, 3, "migration expedition preserved")
	eq(old.waypoints.frost, true, "migration discovery preserved")
	eq(old.regionalContracts.frost.status, "available", "old profile starts new contract")
end
local raw = {regionalContracts = {
	forest = {status = "active", kills = 900, gathers = -5},
	marsh = {status = "completed", kills = 5, gathers = 3},
	volcanic = {status = "active", kills = 0/0, gathers = math.huge},
	frost = {status = "admin", kills = 5, gathers = 3},
	desert = {status = "available", kills = 5, gathers = 3},
	admin = {status = "completed"},
}}
local clean = Profile.sanitize(raw)
eq(clean.regionalContracts.forest.kills, 5, "stored kill count capped")
eq(clean.regionalContracts.forest.gathers, 0, "stored negative gather clamped")
eq(clean.regionalContracts.marsh.status, "completed", "stored completion retained")
eq(clean.regionalContracts.volcanic.kills, 0, "stored NaN count discarded")
eq(clean.regionalContracts.volcanic.gathers, 0, "stored infinite count discarded")
eq(clean.regionalContracts.frost.status, "available", "unknown status reset")
eq(clean.regionalContracts.frost.kills, 0, "unknown status cannot preload progress")
eq(clean.regionalContracts.desert.kills, 0, "available contract cannot preload progress")
eq(clean.regionalContracts.admin, nil, "unknown contract discarded")
raw.regionalContracts.forest.kills = 0
eq(clean.regionalContracts.forest.kills, 5, "loaded nested contract isolated")
local saved = Profile.snapshot(clean)
clean.regionalContracts.forest.gathers = 3
eq(saved.regionalContracts.forest.gathers, 0, "in-flight contract snapshot isolated")
local freshA, freshB = Profile.newProfile(), Profile.newProfile()
freshA.regionalContracts.forest.status = "active"
eq(freshB.regionalContracts.forest.status, "available", "new profile contracts isolated")
freshA.regionalContracts.forest.kills = 4
eq(freshA.regionalContracts.marsh.kills, 0, "regional entries do not alias")

for region, definition in Config.EnemyBehaviors do
	local origin = {x = 0, y = 3, z = 0}
	local channel = Enemies.begin(100, origin, definition)
	origin.x = 100
	eq(channel.origin.x, 0, "attack center copied")
	eq(Enemies.ready(channel, 100 + definition.Windup), true, "exact windup boundary")
	if definition.Windup > 0 then eq(Enemies.ready(channel, 100 + definition.Windup - 0.001), false, "windup not early") end
	eq(Enemies.hits({x = definition.Radius, y = 3, z = 0}, channel.origin, definition), true, "ground radius inclusive")
	eq(Enemies.hits({x = definition.Radius + 0.01, y = 3, z = 0}, channel.origin, definition), false, "outside ground radius")
	eq(Enemies.hits({x = 0, y = 13, z = 0}, channel.origin, definition), true, "vertical tolerance inclusive")
	eq(Enemies.hits({x = 0, y = 13.01, z = 0}, channel.origin, definition), false, "beyond vertical tolerance")
	eq(Enemies.canHit(channel, 110, {x = 0, y = 3, z = 0}, true, true, false, definition), false, "LOS required")
	eq(Enemies.canHit(channel, 110, {x = 0, y = 3, z = 0}, false, true, true, definition), false, "dead target excluded")
	eq(Enemies.canHit(channel, 110, {x = 0, y = 3, z = 0}, true, false, true, definition), false, "untrusted target excluded")
	eq(Enemies.canHit(channel, 110, {x = 0/0, y = 3, z = 0}, true, true, true, definition), false, "NaN geometry rejected")
	eq(Enemies.begin(math.huge, channel.origin, definition), nil, "infinite clock rejected")
	eq(Enemies.ready(channel, 99), false, "clock rollback rejected")
	if region == "marsh" or region == "desert" then
		eq(Enemies.canHit(channel, 110, {x = definition.Radius + 1, y = 3, z = 0}, true, true, true, definition), false, "moving away from locked target disk dodges")
	end
end
print("Regional contracts and enemy rules: " .. n .. " assertions passed")
