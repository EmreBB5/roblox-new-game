local Config = require("../src/shared/GameConfig")
local Progression = require("../src/shared/Progression")
local Combat = require("../src/shared/Combat")
local Campaign = require("../src/shared/Campaign")
local Crafting = require("../src/shared/Crafting")
local count = 0
local function eq(actual, expected, label)
	count += 1
	assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local p = Progression.newProfile()
eq(p.version, 7, "new profile v4")
eq(Combat.stats(p, Config).maxHealth, 140, "warrior health")
eq(Combat.stats(p, Config).basicRange, 11, "warrior melee range")
p.classId = "mage"
eq(Combat.stats(p, Config).basicDamage, 21, "mage basic damage")
eq(Combat.stats(p, Config).basicRange, 32, "mage ranged basic")
p.level, p.equipmentTier, p.equippedPet, p.pets.mossling = 5, 3, "mossling", true
local stats = Combat.stats(p, Config)
eq(stats.maxHealth, 135, "mage gear HP added once")
eq(stats.basicDamage, 48, "level plus gear plus owned pet damage")
p.pets.mossling = nil
eq(Combat.stats(p, Config).basicDamage, 44, "unowned pet gives no damage")
p.level = 1000
eq(Combat.stats(p, Config).basicDamage, 96, "level bonus capped")
p.classId = "warrior"
local runtime = Combat.newRuntime(100)
eq(Combat.use(p, runtime, "primary", 100, false, Config).status, "target", "no valid target")
eq(runtime.resource, 100, "invalid target spends nothing")
eq(runtime.cooldowns.primary, 0, "invalid target has no cooldown")
eq(Combat.use(p, runtime, "primary", 100, true, Config).status, "used", "valid cleave")
eq(runtime.resource, 75, "resource spent once")
eq(runtime.cooldowns.primary, 106, "absolute cooldown")
eq(Combat.use(p, runtime, "primary", 100, true, Config).status, "cooldown", "spam cooldown blocked")
eq(runtime.resource, 75, "spam not charged")
eq(Combat.use(p, runtime, "secondary", 100, false, Config).status, "target", "full health heal rejected by server target check")
eq(runtime.resource, 75, "full health heal not charged")
eq(Combat.use(p, runtime, "secondary", 100, true, Config).status, "used", "heal accepted when useful")
eq(runtime.resource, 45, "heal cost")
eq(runtime.cooldowns.secondary, 114, "heal cooldown")
Combat.refresh(runtime, 101, Config)
eq(runtime.resource, 53, "resource regen elapsed seconds")
eq(Combat.refresh(runtime, 100, Config), false, "clock rollback rejected")
eq(runtime.resource, 53, "clock rollback cannot farm regen")
for _, bad in {0/0, math.huge, -1} do
	eq(Combat.use(p, runtime, "primary", bad, true, Config).status, "invalid", "invalid clock rejected")
end
eq(Combat.use(p, runtime, "admin", 101, true, Config).status, "invalid", "unknown slot")
eq(runtime.resource, 53, "invalid input unchanged")
p.classId = "mage"
eq(Combat.use(p, runtime, "primary", 101, true, Config).status, "cooldown", "class swap preserves slot cooldown")
eq(runtime.cooldowns.primary, 106, "class swap cannot shorten cooldown")
eq(Combat.use(p, runtime, "primary", 106, true, Config).status, "used", "exact cooldown boundary")
eq(runtime.resource, 68, "regen and mage cost after class swap")
eq(runtime.cooldowns.primary, 110, "mage cooldown applied")
local empty = Combat.newRuntime(10)
empty.resource = 0
eq(Combat.use(p, empty, "secondary", 10, true, Config).status, "resource", "insufficient resource")
eq(empty.cooldowns.secondary, 0, "insufficient resource no cooldown")
eq(Combat.use(p, empty, "secondary", 15, true, Config).status, "used", "exact regenerated cost")
eq(empty.resource, 0, "exact cost leaves zero")
Combat.refresh(empty, 100000, Config)
eq(empty.resource, 100, "long offline interval caps resource")
empty.resource = 0/0
eq(Combat.use(p, empty, "primary", 100000, true, Config).status, "invalid", "poisoned runtime rejected")

local campaign = Progression.newProfile()
eq(Campaign.claim(campaign, Config).status, "incomplete", "cannot claim before kills")
Campaign.recordKill(campaign, "marsh", Config)
Campaign.recordBoss(campaign, Config)
eq(campaign.expedition.progress, 0, "wrong region or early boss not counted")
for stage = 1, 3 do
	local id = Config.Expedition[stage].RegionId
	for _ = 1, 8 do Campaign.recordKill(campaign, id, Config) end
	eq(campaign.expedition.progress, 5, "kill objective capped")
	local claimed = Campaign.claim(campaign, Config)
	eq(claimed.status, "rewarded", "stage reward")
	eq(claimed.stage, stage, "reward identifies completed stage")
	eq(campaign.expedition.stage, stage + 1, "manual claim advances")
	eq(campaign.expedition.progress, 0, "new stage not prefilled")
	local gold = campaign.gold
	eq(Campaign.claim(campaign, Config).status, "incomplete", "same claim cannot repeat")
	eq(campaign.gold, gold, "repeat claim gives no gold")
	local crafted = Crafting.craft(campaign, Config)
	eq(crafted.status, "crafted", "campaign enables matching recipe")
	eq(crafted.tier, stage, "craft only next tier")
	eq(campaign.gold, 0, "exact recipe gold")
end
Campaign.recordKill(campaign, "volcanic", Config)
Campaign.recordKill(campaign, nil, Config)
eq(campaign.expedition.progress, 0, "boss stage not satisfied by kills or missing region")
Campaign.recordBoss(campaign, Config)
Campaign.recordBoss(campaign, Config)
eq(campaign.expedition.progress, 1, "eligible boss objective capped")
eq(Campaign.claim(campaign, Config).status, "rewarded", "boss objective reward")
eq(campaign.expedition.stage, 5, "boss unlocks frontier expedition")
for stage = 5, 6 do
	local regionId = Config.Expedition[stage].RegionId
	Campaign.recordBoss(campaign, Config)
	Campaign.recordKill(campaign, "forest", Config)
	eq(campaign.expedition.progress, 0, "frontier objective excludes boss and old regions")
	for _ = 1, 10 do Campaign.recordKill(campaign, regionId, Config) end
	eq(campaign.expedition.progress, 8, "frontier objective capped")
	eq(Campaign.claim(campaign, Config).status, "rewarded", "frontier stage reward")
	eq(campaign.expedition.stage, stage + 1, "frontier manual advancement")
	eq(Campaign.claim(campaign, Config).status, stage == 6 and "completed" or "incomplete", "frontier reward cannot be replayed")
end
local finalGold = campaign.gold
eq(Campaign.claim(campaign, Config).status, "completed", "completed campaign cannot claim again")
eq(campaign.gold, finalGold, "completed claim no extra currency")
eq(Crafting.craft(campaign, Config).status, "completed", "max tier no extra spending")
eq(campaign.gold, finalGold, "max tier no deduction")

local craft = Progression.newProfile()
craft.gold, craft.materials.wood = 24, 5
eq(Crafting.craft(craft, Config).status, "gold", "insufficient gold")
eq(craft.materials.wood, 5, "gold failure preserves materials")
craft.gold, craft.materials.wood = 25, 4
eq(Crafting.craft(craft, Config).status, "materials", "insufficient materials")
eq(craft.gold, 25, "material failure preserves gold")
eq(craft.equipmentTier, 0, "failure preserves tier")
craft.materials.wood = 5
eq(Crafting.craft(craft, Config).status, "crafted", "tier one success")
craft.gold, craft.materials.wood, craft.materials.iron = 100, 8, 4
eq(Crafting.craft(craft, Config).status, "materials", "second recipe checks every material")
eq(craft.materials.wood, 8, "late missing ingredient no partial deduction")
eq(craft.materials.iron, 4, "late ingredient preserved")
eq(craft.gold, 100, "late ingredient failure no gold charge")
craft.materials.iron = math.huge
eq(Crafting.craft(craft, Config).status, "invalid", "infinite material cannot craft")
eq(craft.materials.wood, 8, "corrupt ingredient no partial deduction")
craft.materials.iron = 5
craft.gold = 0/0
eq(Crafting.craft(craft, Config).status, "invalid", "NaN currency cannot craft")
local overflow = Progression.newProfile()
overflow.gold = 999999990
overflow.materials.wood = 100000000
overflow.expedition.progress = 5
Campaign.claim(overflow, Config)
eq(overflow.gold, 999999999, "campaign gold bounded without wrap")
eq(overflow.materials.wood, 100000000, "material reward bounded")

local old = Progression.sanitize({version = 2, level = 7, xp = 18, gold = 123, questStatus = "return", questKills = 3,
	pets = {tidefin = true}, equippedPet = "tidefin", petPity = {thornwarden = 17}, bossVictories = {thornwarden = 20}, lastBossClaims = {thornwarden = 1800000000}, stardust = 10})
eq(old.version, 7, "v2 migration version")
eq(old.level, 7, "v2 migration level")
eq(old.xp, 18, "v2 migration XP")
eq(old.gold, 123, "v2 migration gold")
eq(old.questStatus, "return", "v2 migration legacy quest")
eq(old.equippedPet, "tidefin", "v2 migration pet ownership")
eq(old.petPity.thornwarden, 17, "v2 migration pity")
eq(old.lastBossClaims.thornwarden, 1800000000, "v2 migration occurrence guard")
eq(old.classId, "warrior", "v2 default class")
eq(old.equipmentTier, 0, "v2 default equipment")
eq(old.materials.wood, 0, "v2 new materials empty")
eq(old.expedition.stage, 1, "v2 expedition starts")
local raw = {classId = "admin", equipmentTier = math.huge, materials = {wood = 0/0, iron = -3, ember = 1e15, premium = 99}, expedition = {stage = math.huge, progress = math.huge}}
local sanitized = Progression.sanitize(raw)
eq(sanitized.classId, "warrior", "class whitelist")
eq(sanitized.equipmentTier, 0, "nonfinite tier discarded")
eq(sanitized.materials.wood, 0, "NaN material discarded")
eq(sanitized.materials.iron, 0, "negative material clamped")
eq(sanitized.materials.ember, 100000000, "material upper cap")
eq(sanitized.materials.premium, nil, "unknown material discarded")
eq(sanitized.expedition.stage, 1, "nonfinite stage defaults")
eq(sanitized.expedition.progress, 0, "nonfinite progress discarded")
local cap = Progression.sanitize({classId = "mage", equipmentTier = 999, expedition = {stage = 4, progress = 999}})
eq(cap.classId, "mage", "mage class preserved")
eq(cap.equipmentTier, 3, "tier capped")
eq(cap.expedition.progress, 1, "boss progress capped")
cap.materials.iron = 5
local saved = Progression.snapshot(cap)
cap.materials.iron, cap.expedition.stage = 10, 5
eq(saved.materials.iron, 5, "save material snapshot independent")
eq(saved.expedition.stage, 4, "save expedition snapshot independent")
local fresh = Progression.newProfile()
cap.materials.wood = 4
eq(fresh.materials.wood, 0, "new profile materials independent")
eq(fresh.expedition.stage, 1, "new profile expedition independent")
local badClass = Progression.newProfile()
badClass.classId = "admin"
local cleanRuntime = Combat.newRuntime(1)
eq(Combat.use(badClass, cleanRuntime, "primary", 1, true, Config).status, "invalid", "unknown class cannot invoke ability")
eq(cleanRuntime.resource, 100, "unknown class no spending")
cleanRuntime.cooldowns.primary = 0/0
eq(Combat.use(Progression.newProfile(), cleanRuntime, "primary", 1, true, Config).status, "invalid", "nonfinite cooldown rejected")
eq(pcall(function() Combat.newRuntime(math.huge) end), false, "nonfinite runtime creation rejected")
local complete = Progression.sanitize({expedition = {stage = 7, progress = 999}})
eq(complete.expedition.progress, 0, "completed stored campaign has zero progress")
local dirty = Progression.newProfile()
dirty.expedition.progress, dirty.materials.iron = 5, math.huge
eq(Campaign.claim(dirty, Config).status, "invalid", "malformed material cannot claim")
eq(dirty.expedition.stage, 1, "invalid claim no stage mutation")
eq(dirty.gold, 0, "invalid claim no gold mutation")
local rich = Progression.newProfile()
rich.gold, rich.questStatus = 999999990, "return"
Progression.interact(rich, Config)
eq(rich.gold, 999999999, "legacy quest currency bounded")
eq(Progression.snapshot(rich).gold, 999999999, "currency overflow cannot wipe save")
print("Adventure: " .. count .. " assertions passed")
