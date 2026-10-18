-- Presentation only. Observe complete personal State snapshots, never grant rewards.
-- Caller injects actual Progression.xpNeeded to keep progression math authoritative.
local FeedbackRules = {}
local MAX_IDS = 3
local function integer(value, minimum, maximum)
	return type(value) == "number" and value == value and value % 1 == 0 and value >= minimum and value <= maximum
end
local function flags(raw, whitelist)
	local result = {}
	if type(raw) == "table" then
		for id in whitelist do if raw[id] == true then result[id] = true end end
	end
	return result
end
local function missing(previous, current)
	for id in previous do if not current[id] then return true end end
	return false
end
local function additions(previous, current)
	local result = {}
	for id in current do if not previous[id] then table.insert(result, id) end end
	table.sort(result)
	return result
end
local function capped(ids)
	local result = {}
	for index = 1, math.min(MAX_IDS, #ids) do table.insert(result, ids[index]) end
	return result
end
function FeedbackRules.new(config, xpNeeded)
	assert(type(xpNeeded) == "function", "inject Progression.xpNeeded")
	return {config = config, xpNeeded = xpNeeded, totals = {0}, previous = nil, revision = nil}
end
local function normalize(tracker, state)
	if type(state) ~= "table" or not integer(state.level, 1, 10000) or not integer(state.gold, 0, 999999999)
		or not integer(state.xp, 0, tracker.xpNeeded(state.level) - 1) or not integer(state.equipmentTier or 0, 0, 3) then return nil end
	if state.feedbackRevision ~= nil and not integer(state.feedbackRevision, 1, 1000000000000) then return nil end
	for level = #tracker.totals, state.level - 1 do
		tracker.totals[level + 1] = tracker.totals[level] + tracker.xpNeeded(level)
	end
	local exploration = if type(state.exploration) == "table" then state.exploration else {}
	return {level = state.level, totalXP = tracker.totals[state.level] + state.xp, gold = state.gold,
		tier = state.equipmentTier or 0, pets = flags(state.pets, tracker.config.Pets),
		claimed = flags(exploration.claimed, tracker.config.ExplorationSites),
		discovered = flags(exploration.discovered, tracker.config.ExplorationSites), revision = state.feedbackRevision}
end
function FeedbackRules.observe(tracker, state)
	local current = normalize(tracker, state)
	if not current then return nil end
	if tracker.revision ~= nil and (current.revision == nil or current.revision <= tracker.revision) then return nil end
	local previous = tracker.previous
	if current.revision then tracker.revision = current.revision end
	if not previous then
		tracker.previous = current
		return nil
	end
	-- Persistent progress never decreases in this game. Ignore a reset/restore
	-- frame, preserving the prior baseline so restoration cannot celebrate again.
	if current.totalXP < previous.totalXP or current.tier < previous.tier or missing(previous.pets, current.pets)
		or missing(previous.claimed, current.claimed) or missing(previous.discovered, current.discovered) then return nil end
	local pets = additions(previous.pets, current.pets)
	local chests = additions(previous.claimed, current.claimed)
	local discoveries = additions(previous.discovered, current.discovered)
	local xp = current.totalXP - previous.totalXP
	-- Gold-only changes have no safe order without a revision. Such legacy
	-- snapshots only celebrate gold alongside monotonically increasing XP.
	local gold = if current.revision or xp > 0 then math.max(0, current.gold - previous.gold) else 0
	local kind, count
	if #pets > 0 then kind, count = "pet", #pets
	elseif current.level > previous.level then kind, count = "level", current.level - previous.level
	elseif current.tier > previous.tier then kind, count = "equipment", current.tier - previous.tier
	elseif #chests > 0 then kind, count = "chest", #chests
	elseif #discoveries > 0 then kind, count = "discovery", #discoveries
	elseif xp > 0 or gold > 0 then kind, count = "xp", 1 end
	tracker.previous = current
	if not kind then return nil end
	return {kind = kind, count = count, xp = xp, gold = gold, level = current.level, tier = current.tier,
		petIds = capped(pets), siteIds = capped(if kind == "chest" then chests else discoveries)}
end
return FeedbackRules
