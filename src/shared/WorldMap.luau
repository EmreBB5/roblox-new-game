-- Coordinate helpers shared by the map, biome feedback, and validation.
local WorldMap = {}
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
function WorldMap.regionAt(x, z, config)
	if not finite(x) or not finite(z) then return nil end
	if x * x + z * z <= config.SafeZoneRadius ^ 2 then return "village" end
	local nearest, distance = nil, math.huge
	for id, region in config.Regions do
		local dx, dz = x - region.X, z - region.Z
		local radius = math.sqrt(dx * dx + dz * dz)
		if radius <= region.Radius and radius < distance then nearest, distance = id, radius end
	end
	return nearest
end
function WorldMap.normalized(x, z, config)
	if not finite(x) or not finite(z) then return nil, nil end
	local bounds = config.MapBounds
	return math.clamp((x - bounds.MinX) / (bounds.MaxX - bounds.MinX), 0.02, 0.98),
		math.clamp((z - bounds.MinZ) / (bounds.MaxZ - bounds.MinZ), 0.02, 0.98)
end
return WorldMap
