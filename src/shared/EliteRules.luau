-- Pure telegraph geometry. Server owns one-shot timers and generation guards.
local EliteRules = {}
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
local function vector(v) return type(v) == "table" and finite(v.x) and finite(v.y) and finite(v.z) end
function EliteRules.eligible(damage, hits, maxHP, config)
	return finite(damage) and finite(hits) and finite(maxHP) and maxHP > 0
		and hits % 1 == 0 and hits >= config.EliteEligibility.MinHits and damage >= maxHP * config.EliteEligibility.DamageFraction
end
function EliteRules.hits(position, origin, definition)
	if not vector(position) or not vector(origin) or math.abs(position.y - origin.y) > definition.MaxVertical then return false end
	local dx, dz = position.x - origin.x, position.z - origin.z
	return (definition.Kind == "area" or definition.Kind == "targeted") and dx * dx + dz * dz <= definition.Radius ^ 2
end
function EliteRules.begin(now, origin, definition)
	if not finite(now) or now < 0 or not vector(origin) then return nil end
	return {startedAt = now, endsAt = now + definition.Windup, origin = {x = origin.x, y = origin.y, z = origin.z}}
end
function EliteRules.ready(channel, now)
	return type(channel) == "table" and finite(now) and finite(channel.endsAt) and finite(channel.startedAt)
		and now >= channel.startedAt and now >= channel.endsAt
end
function EliteRules.canHit(channel, now, position, alive, trusted, lineOfSight, definition)
	return EliteRules.ready(channel, now) and alive == true and trusted == true and lineOfSight == true
		and EliteRules.hits(position, channel.origin, definition)
end
return EliteRules
