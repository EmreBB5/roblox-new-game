-- Positions are plain {x,y,z}; the server owns discovery, geometry, and time.
local TravelRules = {}
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
local function position(p) return type(p) == "table" and finite(p.x) and finite(p.y) and finite(p.z) end
function TravelRules.canStart(profile, id, sourceDistance, alive, trusted, lastCombat, now, config, sourceId)
	if type(id) ~= "string" or not config.Waypoints[id] or not finite(now) or now < 0
		or not finite(sourceDistance) or sourceDistance < 0 or (not finite(lastCombat) and lastCombat ~= -math.huge) then return "invalid" end
	if not profile.waypoints[id] then return "locked" end
	if alive ~= true then return "dead" end
	if trusted ~= true then return "untrusted" end
	if sourceDistance > config.Travel.SourceRange then return "source" end
	if sourceId == id then return "same" end
	if now - lastCombat < config.Travel.CombatLock then return "combat" end
	return "allowed"
end
function TravelRules.begin(profile, id, sourceDistance, alive, trusted, lastCombat, now, config, characterKey, origin, sourceId)
	local status = TravelRules.canStart(profile, id, sourceDistance, alive, trusted, lastCombat, now, config, sourceId)
	if status ~= "allowed" then return {status = status} end
	if characterKey == nil or not position(origin) then return {status = "invalid"} end
	return {status = "started", channel = {waypointId = id, startedAt = now, endsAt = now + config.Travel.ChannelDuration,
		characterKey = characterKey, origin = {x = origin.x, y = origin.y, z = origin.z}}}
end
function TravelRules.check(channel, now, currentPosition, characterKey, alive, trusted, lastDamageAt, config)
	if type(channel) ~= "table" or not finite(now) or not finite(channel.startedAt) or now < channel.startedAt
		or not finite(channel.endsAt) or not position(channel.origin) or not position(currentPosition)
		or (not finite(lastDamageAt) and lastDamageAt ~= -math.huge) then return "cancelled" end
	if alive ~= true or trusted ~= true or characterKey ~= channel.characterKey or lastDamageAt >= channel.startedAt then return "cancelled" end
	local dx, dy, dz = currentPosition.x - channel.origin.x, currentPosition.y - channel.origin.y, currentPosition.z - channel.origin.z
	if dx * dx + dy * dy + dz * dz > config.Travel.MaxChannelMovement ^ 2 then return "cancelled" end
	return if now >= channel.endsAt then "ready" else "channeling"
end
return TravelRules
