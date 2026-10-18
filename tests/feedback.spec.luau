local Config = require("../src/shared/GameConfig")
local Profile = require("../src/shared/Progression")
local Rules = require("../src/shared/FeedbackRules")
local n = 0
local function eq(a, b, label)
	n += 1
	assert(a == b, label .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local function snapshot(revision)
	local state = Profile.newProfile()
	state.feedbackRevision = revision
	return state
end
local function tracker(state)
	local result = Rules.new(Config, Profile.xpNeeded)
	eq(Rules.observe(result, state), nil, "first snapshot establishes silent baseline")
	return result
end
local state = snapshot(1)
state.gold, state.level, state.xp, state.equipmentTier = 900, 10, 12, 3
state.pets.mossling = true
state.exploration.discovered.forest_ruins = true
state.exploration.claimed.forest_ruins = true
local t = tracker(state)
eq(Rules.observe(t, state), nil, "same snapshot revision replay silent")
local replay = Profile.snapshot(state)
replay.feedbackRevision = 2
eq(Rules.observe(t, replay), nil, "higher revision identical contents silent")

state = snapshot(1)
state.xp, state.gold = 49, 100
t = tracker(state)
local nextState = snapshot(2)
nextState.level, nextState.xp, nextState.gold = 2, 3, 110
local event = Rules.observe(t, nextState)
eq(event.kind, "level", "level event outranks reward")
eq(event.xp, 4, "XP crossing threshold counted exactly")
eq(event.gold, 10, "gold delta")
eq(event.level, 2, "current level included")
eq(event.count, 1, "one level gained")
local old = snapshot(1)
old.xp, old.gold = 49, 100
eq(Rules.observe(t, old), nil, "older revision ignored")
nextState.feedbackRevision = 3
eq(Rules.observe(t, nextState), nil, "stale reorder cannot cause duplicate restore reward")
local cap = snapshot(4)
cap.level, cap.xp, cap.gold = 4, 2, 20
local multi = Rules.observe(t, cap)
eq(multi.kind, "level", "multiple levels one event")
eq(multi.count, 2, "multiple levels count")
local expected = Profile.xpNeeded(2) - 3 + Profile.xpNeeded(3) + 2
eq(multi.xp, expected, "multiple levels use actual progression formula")
eq(multi.gold, 0, "currency spend never negative gain")
local gain = Profile.snapshot(cap)
gain.feedbackRevision, gain.gold = 5, 35
local gained = Rules.observe(t, gain)
eq(gained.gold, 15, "gold earned after spending counted from latest valid balance")
eq(gained.xp, 0, "gold-only reward has zero XP")
eq(gained.kind, "xp", "gold-only revision reward uses reward card")
local staleSpend = Profile.snapshot(cap)
staleSpend.feedbackRevision = 4
eq(Rules.observe(t, staleSpend), nil, "out of order spender cannot rewind baseline")
gain.feedbackRevision = 6
eq(Rules.observe(t, gain), nil, "restoring latest balance after stale spend silent")

state = snapshot(1)
t = tracker(state)
state.pets.mossling = true -- mutate source after baseline; tracker must not alias.
local pet = snapshot(2)
pet.pets.mossling, pet.pets.tidefin = true, true
pet.level, pet.xp, pet.gold, pet.equipmentTier = 2, 5, 50, 1
for id in Config.ExplorationSites do pet.exploration.discovered[id], pet.exploration.claimed[id] = true, true end
local batch = Rules.observe(t, pet)
eq(batch.kind, "pet", "new pet highest priority")
eq(batch.count, 2, "all pets counted")
eq(batch.petIds[1], "mossling", "pet order deterministic")
eq(batch.petIds[2], "tidefin", "pet order stable")
eq(batch.xp, 55, "priority card retains XP batch")
eq(batch.gold, 50, "priority card retains gold batch")
pet.feedbackRevision = 3
eq(Rules.observe(t, pet), nil, "consumed lower-priority changes cannot celebrate next snapshot")
batch.petIds[1] = "fake"
local unchanged = Profile.snapshot(pet)
unchanged.feedbackRevision = 4
eq(Rules.observe(t, unchanged), nil, "returned event arrays cannot mutate tracker")
local reset = snapshot(5)
eq(Rules.observe(t, reset), nil, "reset profile silent and does not replace progress highwater")
unchanged.feedbackRevision = 6
eq(Rules.observe(t, unchanged), nil, "restored profile not celebrated again")
local restoredPet = Profile.snapshot(unchanged)
restoredPet.feedbackRevision = 7
restoredPet.pets.embercub = true
eq(Rules.observe(t, restoredPet).kind, "pet", "genuinely new pet after restore still celebrates")

state = snapshot(1)
state.pets.mossling = false
t = tracker(state)
local owned = snapshot(2)
owned.pets.mossling = true
eq(Rules.observe(t, owned).kind, "pet", "explicit false to true ownership celebrates")
owned.feedbackRevision = 3
owned.equippedPet = "mossling"
owned.petXP.mossling = 100
eq(Rules.observe(t, owned), nil, "equip or pet growth alone not a fake new reward")

state = snapshot(1)
t = tracker(state)
local discovery = snapshot(2)
for id in Config.ExplorationSites do discovery.exploration.discovered[id] = true end
local found = Rules.observe(t, discovery)
eq(found.kind, "discovery", "discovery event")
eq(found.count, 5, "capped batch retains full discovery count")
eq(#found.siteIds, 3, "display list capped at three")
eq(found.siteIds[1], "desert_caravan", "site list sorted deterministically")
local chest = Profile.snapshot(discovery)
chest.feedbackRevision = 3
for id in Config.ExplorationSites do chest.exploration.claimed[id] = true end
local opened = Rules.observe(t, chest)
eq(opened.kind, "chest", "chest claim higher than existing discovery")
eq(opened.count, 5, "all personal claims counted")
eq(#opened.siteIds, 3, "claim display list capped")
chest.feedbackRevision = 4
eq(Rules.observe(t, chest), nil, "claims celebrated once")
local spent = Profile.snapshot(chest)
spent.feedbackRevision, spent.equipmentTier, spent.gold = 5, 1, 0
eq(Rules.observe(t, spent).kind, "equipment", "craft celebrates without fake currency gains")

state = snapshot(1)
state.xp = 20
t = tracker(state)
for _, bad in {0/0, math.huge, -1, 1.5} do
	local malformed = snapshot(100)
	malformed.xp = bad
	eq(Rules.observe(t, malformed), nil, "invalid XP rejected")
end
local invalidRevision = snapshot(0/0)
invalidRevision.xp = 30
eq(Rules.observe(t, invalidRevision), nil, "invalid revision rejected")
local valid = snapshot(2)
valid.xp = 25
eq(Rules.observe(t, valid).xp, 5, "invalid high revision cannot poison subsequent valid snapshots")
valid.feedbackRevision = nil
valid.xp = 30
eq(Rules.observe(t, valid), nil, "revisioned stream cannot downgrade to unversioned state")

state = snapshot(nil)
t = tracker(state)
local legacyGold = snapshot(nil)
legacyGold.gold = 10
eq(Rules.observe(t, legacyGold), nil, "legacy gold-only state conservatively silent")
legacyGold.xp = 4
local legacyGain = Rules.observe(t, legacyGold)
eq(legacyGain.xp, 4, "legacy monotonic XP can celebrate")
eq(legacyGain.gold, 0, "legacy prior balance does not repeat gold")
local partial = {feedbackRevision = 3, level = 1, xp = 5}
eq(Rules.observe(t, partial), nil, "partial state rejected rather than fabricate default currency")
print("Progression feedback: " .. n .. " assertions passed")
