-- Discovery and personal one-time rewards; server alone supplies guard state.
local Exploration = {}
local function amount(value)
	return type(value) == "number" and value == value and value >= 0 and value < math.huge and value % 1 == 0
end
local function valid(profile, id, config)
	return type(id) == "string" and config.ExplorationSites[id] ~= nil and type(profile.exploration) == "table"
		and type(profile.exploration.discovered) == "table" and type(profile.exploration.claimed) == "table"
end
function Exploration.discover(profile, id, config)
	if not valid(profile, id, config) then return {status = "invalid"} end
	if profile.exploration.discovered[id] == true then return {status = "known"} end
	profile.exploration.discovered[id] = true
	return {status = "discovered"}
end
function Exploration.claim(profile, id, cleared, alive, config)
	if not valid(profile, id, config) then return {status = "invalid"} end
	if profile.exploration.claimed[id] == true then return {status = "claimed"} end
	if profile.exploration.discovered[id] ~= true then return {status = "undiscovered"} end
	if alive ~= true then return {status = "dead"} end
	if cleared ~= true then return {status = "guarded"} end
	local definition = config.ExplorationSites[id]
	if not amount(profile.gold) or type(profile.materials) ~= "table" or not amount(profile.materials[definition.RewardMaterial]) then return {status = "invalid"} end
	-- Commit before any external save yields; duplicate requests cannot grant twice.
	profile.exploration.claimed[id] = true
	profile.gold = math.min(999999999, profile.gold + definition.Gold)
	profile.materials[definition.RewardMaterial] = math.min(100000000, profile.materials[definition.RewardMaterial] + definition.MaterialAmount)
	return {status = "rewarded", siteId = id, xp = definition.XP, gold = definition.Gold}
end
return Exploration
