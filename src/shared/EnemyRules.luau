-- Ground-plane hit tests only; service owns target selection and cast lifecycle.
local EnemyRules = {}
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
local function vector(v) return type(v) == "table" and finite(v.x) and finite(v.y) and finite(v.z) end
function EnemyRules.hits(position, origin, definition)
	if not vector(position) or not vector(origin) or math.abs(position.y - origin.y) > definition.MaxVertical then return false end
	local dx, dz = position.x - origin.x, position.z - origin.z
	return dx * dx + dz * dz <= definition.Radius ^ 2
end
function EnemyRules.begin(now, origin, definition)
	if not finite(now) or now < 0 or not vector(origin) then return nil end
	return {startedAt = now, endsAt = now + definition.Windup, origin = {x = origin.x, y = origin.y, z = origin.z}}
end
function EnemyRules.ready(channel, now)
	return type(channel) == "table" and finite(now) and finite(channel.startedAt) and finite(channel.endsAt)
		and now >= channel.startedAt and now >= channel.endsAt
end
function EnemyRules.canHit(channel, now, position, alive, trusted, lineOfSight, definition)
	return EnemyRules.ready(channel, now) and alive == true and trusted == true and lineOfSight == true
		and EnemyRules.hits(position, channel.origin, definition)
end
return EnemyRules
