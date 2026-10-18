-- Per-region, one-time contracts. Server validates board proximity independently.
local Contracts = {}
local function amount(n) return type(n) == "number" and n == n and n >= 0 and n < math.huge and n % 1 == 0 end
local function entry(profile, id, config)
	if type(id) ~= "string" or not config.RegionalContracts[id] or type(profile.regionalContracts) ~= "table" then return nil end
	local value = profile.regionalContracts[id]
	return if type(value) == "table" then value else nil
end
function Contracts.accept(profile, id, config)
	local value = entry(profile, id, config)
	if not value then return {status = "invalid"} end
	if value.status == "completed" then return {status = "completed"} end
	if value.status == "active" then return {status = "active"} end
	if value.status ~= "available" then return {status = "invalid"} end
	value.status, value.kills, value.gathers = "active", 0, 0
	return {status = "accepted"}
end
local function record(profile, id, config, key, targetKey)
	local value = entry(profile, id, config)
	if not value or value.status ~= "active" or not amount(value[key]) then return false end
	value[key] = math.min(config.RegionalContracts[id][targetKey], value[key] + 1)
	return true
end
function Contracts.recordKill(profile, id, config) return record(profile, id, config, "kills", "KillTarget") end
function Contracts.recordGather(profile, id, config) return record(profile, id, config, "gathers", "GatherTarget") end
function Contracts.ready(profile, id, config)
	local value = entry(profile, id, config)
	if not value or value.status ~= "active" or not amount(value.kills) or not amount(value.gathers) then return false end
	local definition = config.RegionalContracts[id]
	return value.kills >= definition.KillTarget and value.gathers >= definition.GatherTarget
		and type(profile.waypoints) == "table" and profile.waypoints[definition.WaypointId] == true
end
function Contracts.claim(profile, id, config)
	local value = entry(profile, id, config)
	if not value then return {status = "invalid"} end
	if value.status == "completed" then return {status = "completed"} end
	if not Contracts.ready(profile, id, config) then return {status = "incomplete"} end
	local definition = config.RegionalContracts[id]
	if not amount(profile.gold) or type(profile.materials) ~= "table" or not amount(profile.materials[definition.Material]) then return {status = "invalid"} end
	value.status = "completed"
	profile.gold = math.min(999999999, profile.gold + definition.Gold)
	profile.materials[definition.Material] = math.min(100000000, profile.materials[definition.Material] + definition.MaterialAmount)
	return {status = "rewarded", xp = definition.XP, gold = definition.Gold, regionId = id}
end
function Contracts.interact(profile, id, config)
	local value = entry(profile, id, config)
	if not value then return {status = "invalid"} end
	return if value.status == "available" then Contracts.accept(profile, id, config) else Contracts.claim(profile, id, config)
end
return Contracts
