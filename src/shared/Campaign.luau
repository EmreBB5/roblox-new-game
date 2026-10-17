local Campaign = {}
local function amount(value)
	return type(value) == "number" and value == value and value >= 0 and value < math.huge and value % 1 == 0
end
function Campaign.recordKill(profile, regionId, config)
	local stage = config.Expedition[profile.expedition.stage]
	if stage and type(regionId) == "string" and stage.RegionId == regionId then profile.expedition.progress = math.min(stage.Target, profile.expedition.progress + 1) end
end
function Campaign.recordBoss(profile, config)
	local stage = config.Expedition[profile.expedition.stage]
	if stage and not stage.RegionId then profile.expedition.progress = math.min(stage.Target, profile.expedition.progress + 1) end
end
function Campaign.claim(profile, config)
	if type(profile.expedition) ~= "table" or not amount(profile.expedition.stage) or profile.expedition.stage < 1
		or not amount(profile.expedition.progress) or not amount(profile.gold) or type(profile.materials) ~= "table" then return {status = "invalid"} end
	for _, id in {"wood", "iron", "ember"} do if not amount(profile.materials[id]) then return {status = "invalid"} end end
	local index = profile.expedition.stage
	local stage = config.Expedition[index]
	if not stage then return {status = "completed"} end
	if profile.expedition.progress < stage.Target then return {status = "incomplete"} end
	-- All rewards and progression change together without yielding.
	profile.expedition.stage, profile.expedition.progress = index + 1, 0
	profile.gold = math.min(999999999, profile.gold + stage.Gold)
	for id, amount in stage.Materials do profile.materials[id] = math.min(100000000, profile.materials[id] + amount) end
	return {status = "rewarded", stage = index, xp = stage.XP, gold = stage.Gold}
end
return Campaign
