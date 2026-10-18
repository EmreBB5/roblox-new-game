-- Asset-free visual landmarks. No gameplay geometry, prompts, or remote calls.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Landmarks = {}
local P = {
	stone = Color3.fromRGB(70, 91, 101), dark = Color3.fromRGB(20, 49, 58),
	gold = Color3.fromRGB(199, 155, 76), wood = Color3.fromRGB(90, 64, 51),
	teal = Color3.fromRGB(62, 171, 159), glow = Color3.fromRGB(122, 242, 214),
	amber = Color3.fromRGB(255, 191, 100), moss = Color3.fromRGB(82, 132, 91),
	ice = Color3.fromRGB(141, 209, 232), snow = Color3.fromRGB(217, 237, 241),
	sand = Color3.fromRGB(191, 145, 83), ember = Color3.fromRGB(255, 137, 65),
}
local function model(parent, name)
	local result = Instance.new("Model")
	result.Name = name
	result.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	result.Parent = parent
	return result
end

function Landmarks.decorate(parent)
	-- Idempotent for manual Studio reruns; preserve all existing world objects.
	if parent:FindFirstChild("WorldLandmarks") then return end
	local folder = Instance.new("Folder")
	folder.Name = "WorldLandmarks"
	folder.Parent = parent
	local count, lightCount = 0, 0
	local bounds = Config.MapBounds
	local function piece(group, name, size, transform, color, material, shape)
		assert(count < 450, "Landmark part budget exceeded")
		assert(size.X > 0 and size.Y > 0 and size.Z > 0 and math.max(size.X, size.Y, size.Z) <= 2048, "Invalid landmark size")
		-- Check every transformed corner, including tilted crystals and arches.
		for _, x in {-0.5, 0.5} do
			for _, y in {-0.5, 0.5} do
				for _, z in {-0.5, 0.5} do
					local point = transform:PointToWorldSpace(Vector3.new(size.X * x, size.Y * y, size.Z * z))
					assert(point.X >= bounds.MinX and point.X <= bounds.MaxX and point.Z >= bounds.MinZ and point.Z <= bounds.MaxZ, "Landmark outside map")
				end
			end
		end
		local item = Instance.new("Part")
		item.Name, item.Size, item.CFrame = name, size, transform
		item.Color, item.Material = color, material or Enum.Material.Slate
		item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch = true, false, false, false
		item.CastShadow = material ~= Enum.Material.Neon and material ~= Enum.Material.Glass
		item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if shape then item.Shape = shape end
		item.Parent = group
		count += 1
		return item
	end
	local function block(group, name, size, position, color, material)
		return piece(group, name, size, CFrame.new(position), color, material)
	end
	local function rod(group, name, a, b, width, color, material)
		return piece(group, name, Vector3.new((b - a).Magnitude, width, width),
			CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), color, material, Enum.PartType.Cylinder)
	end
	local function orb(group, name, size, position, color, material)
		return piece(group, name, size, CFrame.new(position), color, material, Enum.PartType.Ball)
	end
	local function disc(group, name, center, radius, thickness, color, material)
		return piece(group, name, Vector3.new(thickness, radius * 2, radius * 2),
			CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2), color, material, Enum.PartType.Cylinder)
	end
	local function ring(group, name, center, radius, segments, width, color, material, upright)
		for index = 0, segments - 1 do
			local function point(angle)
				return center + (if upright then Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0)
					else Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius))
			end
			rod(group, name, point(index * math.pi * 2 / segments), point((index + 1) * math.pi * 2 / segments), width, color, material)
		end
	end
	local function gem(group, center, scale, color)
		piece(group, "FacetedCrystal", Vector3.new(1.7, 4.8, 1.7) * scale,
			CFrame.new(center) * CFrame.Angles(0.2, math.pi / 4, 0.2), color, Enum.Material.Glass)
		piece(group, "CrystalHeart", Vector3.new(0.7, 3.5, 0.7) * scale,
			CFrame.new(center) * CFrame.Angles(0.2, math.pi / 4, 0.2), color, Enum.Material.Neon)
	end
	local function light(item, color, brightness, range)
		assert(lightCount < 8, "Landmark light budget exceeded")
		local source = Instance.new("PointLight")
		source.Color, source.Brightness, source.Range = color, brightness, range
		source.Shadows = false
		source.Parent = item
		lightCount += 1
	end

	-- A low, compact fountain beside the plaza: spawn (0,19), keeper (15,0),
	-- forge (-14,12), board (-16,0) and village shrine (-5,35) stay clear.
	do
		local group = model(folder, "VillageCrystalFountain")
		local c = Vector3.new(16, 0, 29)
		disc(group, "OctagonalFoundation", c + Vector3.new(0, 0.4, 0), 5.8, 0.6, P.stone)
		disc(group, "StillWater", c + Vector3.new(0, 1, 0), 4.6, 0.15, P.teal, Enum.Material.Glass).Transparency = 0.3
		ring(group, "BasinRim", c + Vector3.new(0, 1, 0), 5.1, 12, 0.75, P.gold, Enum.Material.Metal)
		block(group, "CentralPlinth", Vector3.new(2.5, 2.8, 2.5), c + Vector3.new(0, 1.8, 0), P.dark)
		disc(group, "PlinthCollar", c + Vector3.new(0, 3, 0), 1.8, 0.3, P.gold, Enum.Material.Metal)
		gem(group, c + Vector3.new(0, 5.6, 0), 1.1, P.glow)
		local core = orb(group, "FountainAura", Vector3.new(0.8, 0.8, 0.8), c + Vector3.new(0, 4.6, 0), P.glow, Enum.Material.Neon)
		light(core, P.glow, 0.8, 20)
		for index = 0, 3 do
			local angle = index * math.pi / 2
			local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local previous = c + direction * 1.2 + Vector3.new(0, 3.6, 0)
			for segment = 1, 4 do
				local t = segment / 4
				local point = c + direction * (1.2 + t * 2.8) + Vector3.new(0, 3.6 + math.sin(t * math.pi) * 0.9 - t * 2.5, 0)
				rod(group, "WaterArc", previous, point, 0.09, P.glow, Enum.Material.Glass).Transparency = 0.25
				previous = point
			end
		end
	end
	local function stall(center, tint, name)
		local group = model(folder, name)
		block(group, "Counter", Vector3.new(9, 2.4, 3.8), center + Vector3.new(0, 1.8, 0), P.wood, Enum.Material.WoodPlanks)
		block(group, "CounterTrim", Vector3.new(9.3, 0.2, 4.1), center + Vector3.new(0, 3.1, 0), P.gold, Enum.Material.Metal)
		for _, x in {-4.4, 4.4} do rod(group, "CanopyPost", center + Vector3.new(x, 0.5, -1.5), center + Vector3.new(x, 8, -1.5), 0.32, P.wood, Enum.Material.Wood) end
		for index = 0, 5 do
			local x = -3.75 + index * 1.5
			piece(group, "StripedCanopy", Vector3.new(1.5, 0.2, 6), CFrame.new(center + Vector3.new(x, 7.1, -0.4)) * CFrame.Angles(-0.15, 0, 0), if index % 2 == 0 then tint else P.gold, Enum.Material.Fabric)
			block(group, "CanopyValance", Vector3.new(1.5, 0.9, 0.15), center + Vector3.new(x, 6.3, 2.5), if index % 2 == 0 then tint else P.gold, Enum.Material.Fabric)
		end
		for index = 1, 4 do
			orb(group, "MarketProduce", Vector3.new(0.9, 0.8, 0.9), center + Vector3.new(-3 + index * 1.3, 3.6, 0), if index % 2 == 0 then P.amber else P.moss, Enum.Material.SmoothPlastic)
		end
		block(group, "SupplyCrate", Vector3.new(2.5, 2.5, 2.5), center + Vector3.new(5.8, 1.6, -1), P.wood, Enum.Material.WoodPlanks)
		block(group, "CrateBand", Vector3.new(2.6, 0.25, 2.6), center + Vector3.new(5.8, 1.6, -1), P.gold, Enum.Material.Metal)
	end
	stall(Vector3.new(-39, 0, -4), P.dark, "NightMarketHerbalist")
	stall(Vector3.new(40, 0, 2), P.teal, "NightMarketAetherGoods")
	for index, coordinates in {{8, 34}, {-25, -8}, {-32, -49}, {32, -49}, {-89, -89}, {94, -102}} do
		local group = model(folder, "AmberWaylight" .. index)
		local c = Vector3.new(coordinates[1], 0, coordinates[2])
		block(group, "LanternFoot", Vector3.new(1.5, 0.8, 1.5), c + Vector3.new(0, 0.5, 0), P.stone)
		rod(group, "LanternPost", c + Vector3.new(0, 0.8, 0), c + Vector3.new(0, 8, 0), 0.35, P.dark, Enum.Material.Metal)
		rod(group, "LanternArm", c + Vector3.new(0, 7.5, 0), c + Vector3.new(1.5, 7.5, 0), 0.25, P.gold, Enum.Material.Metal)
		local glass = block(group, "AmberGlass", Vector3.new(1.1, 1.6, 1.1), c + Vector3.new(1.5, 6.6, 0), P.amber, Enum.Material.Neon)
		for _, y in {5.65, 7.55} do block(group, "LanternCap", Vector3.new(1.5, 0.25, 1.5), c + Vector3.new(1.5, y, 0), P.gold, Enum.Material.Metal) end
		light(glass, P.amber, 0.65, 20)
		block(group, "HangingBanner", Vector3.new(1.8, 3, 0.12), c + Vector3.new(-1.2, 5.2, 0), P.teal, Enum.Material.Fabric)
		block(group, "BannerGoldStripe", Vector3.new(0.2, 2.5, 0.15), c + Vector3.new(-1.2, 5.2, 0.1), P.gold, Enum.Material.Metal)
	end

	-- Forest: a rooted arch with an elevated suspended aether seed.
	do
		local group = model(folder, "ForestRootArch")
		local c = Vector3.new(-415, 0, -210)
		for _, side in {-1, 1} do
			block(group, "AncientPier", Vector3.new(5, 18, 5), c + Vector3.new(side * 14, 9, 0), P.stone)
			block(group, "MossCapital", Vector3.new(6, 1.5, 6), c + Vector3.new(side * 14, 18, 0), P.moss, Enum.Material.Grass)
			for index = 1, 3 do
				rod(group, "GnarledRoot", c + Vector3.new(side * (14 + index * 2), 0.7, index * 3), c + Vector3.new(side * 13, 12 + index, 0), 1.1, P.wood, Enum.Material.Wood)
			end
		end
		for index = 0, 9 do
			local a, b = index * math.pi / 10, (index + 1) * math.pi / 10
			rod(group, "ArchVoussoir", c + Vector3.new(math.cos(a) * 14, 18 + math.sin(a) * 12, 0), c + Vector3.new(math.cos(b) * 14, 18 + math.sin(b) * 12, 0), 3, P.stone)
		end
		rod(group, "SeedChain", c + Vector3.new(0, 28, 0), c + Vector3.new(0, 21, 0), 0.15, P.gold, Enum.Material.Metal)
		gem(group, c + Vector3.new(0, 20, 0), 1.4, P.glow)
		for _, side in {-1, 1} do
			for index = 1, 4 do
				orb(group, "ArchLeaf", Vector3.new(4, 2, 4), c + Vector3.new(side * (9 + index), 22 + index, 0), P.moss, Enum.Material.Grass)
			end
		end
	end
	-- Marsh: the ringed willow and luminous reeds silhouette above the mist.
	do
		local group = model(folder, "MarshRingedWillow")
		local c = Vector3.new(390, 0, -515)
		local points = {Vector3.zero, Vector3.new(-3, 9, 0), Vector3.new(1, 19, 1), Vector3.new(-4, 29, 0), Vector3.new(0, 36, 0)}
		for index = 1, #points - 1 do rod(group, "TwistedTrunk", c + points[index], c + points[index + 1], 4.5, P.dark, Enum.Material.Wood) end
		ring(group, "WillowAetherRing", c + Vector3.new(0, 24, 0), 13, 12, 0.45, P.teal, Enum.Material.Neon, true)
		for _, side in {-1, 1} do
			rod(group, "WillowBough", c + Vector3.new(-2, 24, 0), c + Vector3.new(side * 17, 33, 2), 2.5, P.dark, Enum.Material.Wood)
			orb(group, "WillowCrown", Vector3.new(18, 8, 12), c + Vector3.new(side * 15, 34, 2), P.teal, Enum.Material.Grass)
			for index = 1, 4 do
				rod(group, "DroopingVine", c + Vector3.new(side * (9 + index * 3), 33, 2), c + Vector3.new(side * (9 + index * 3), 19 + index, 2), 0.2, P.moss, Enum.Material.Grass)
			end
		end
		for index = 0, 7 do
			local angle = index * math.pi / 4
			local foot = c + Vector3.new(math.cos(angle) * 19, 0.6, math.sin(angle) * 13)
			rod(group, "LuminousReed", foot, foot + Vector3.new(0.6, 5 + index % 3, 0), 0.18, P.teal, Enum.Material.Grass)
			orb(group, "ReedGlow", Vector3.new(0.45, 1.5, 0.45), foot + Vector3.new(0.6, 5 + index % 3, 0), P.glow, Enum.Material.Neon)
		end
	end
	-- Volcanic: a basalt crown with thin, restrained glowing inscriptions.
	do
		local group = model(folder, "VolcanicRuneCrown")
		local c = Vector3.new(145, 0, -925)
		for index = 0, 6 do
			local angle = index * math.pi * 2 / 7
			local radius = if index == 0 then 0 else 15
			local p = c + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			local height = if index == 0 then 44 else 20 + index * 2
			local base = CFrame.new(p) * CFrame.Angles(0, angle, 0)
			piece(group, "BasaltMonolith", Vector3.new(6, height, 6), base * CFrame.new(0, height / 2, 0), P.dark, Enum.Material.Basalt)
			for tier = 1, 3 do
				piece(group, "EmberInscription", Vector3.new(3.8, 0.35, 0.12), base * CFrame.new(0, tier * height / 4, 3.05) * CFrame.Angles(0, 0, if tier % 2 == 0 then 0.4 else -0.4), P.ember, Enum.Material.Neon)
			end
		end
	end
	-- Frost: a narrow ice gate with a floating snowflake crest.
	do
		local group = model(folder, "FrostAuroraGate")
		local c = Vector3.new(-1050, 0, -1130)
		for _, side in {-1, 1} do
			piece(group, "IceGatePier", Vector3.new(7, 33, 7), CFrame.new(c + Vector3.new(side * 14, 16.5, 0)) * CFrame.Angles(0, 0, -side * 0.08), P.ice, Enum.Material.Ice)
			block(group, "SnowPierCrown", Vector3.new(9, 2, 9), c + Vector3.new(side * 14, 33, 0), P.snow, Enum.Material.Snow)
			for index = 1, 3 do
				gem(group, c + Vector3.new(side * (20 + index * 3), 2 + index, -index * 2), 0.5 + index * 0.2, P.ice)
			end
		end
		block(group, "IceGateLintel", Vector3.new(35, 5, 7), c + Vector3.new(0, 32, 0), P.ice, Enum.Material.Ice)
		ring(group, "AuroraCrest", c + Vector3.new(0, 42, 0), 6, 8, 0.35, P.glow, Enum.Material.Neon, true)
		for index = 0, 2 do
			local a = index * math.pi / 3
			rod(group, "SnowflakeArm", c + Vector3.new(-math.cos(a) * 4.5, 42 - math.sin(a) * 4.5, 0), c + Vector3.new(math.cos(a) * 4.5, 42 + math.sin(a) * 4.5, 0), 0.5, P.snow, Enum.Material.Ice)
		end
	end
	-- Desert: the gold-capped obelisk and palms frame a purely visual pool.
	do
		local group = model(folder, "DesertSunObelisk")
		local c = Vector3.new(1040, 0, -1180)
		block(group, "ObeliskPedestal", Vector3.new(12, 3, 12), c + Vector3.new(0, 1.5, 0), P.sand, Enum.Material.Sandstone)
		block(group, "ObeliskShaft", Vector3.new(5, 36, 5), c + Vector3.new(0, 21, 0), P.sand, Enum.Material.Sandstone)
		gem(group, c + Vector3.new(0, 41, 0), 1.5, P.gold)
		for tier = 1, 5 do
			block(group, "SolarGlyph", Vector3.new(if tier % 2 == 0 then 1.6 else 0.4, 1.6, 0.12), c + Vector3.new(0, 9 + tier * 4.5, 2.56), P.gold, Enum.Material.Metal)
		end
		local water = disc(group, "ReflectedOasis", c + Vector3.new(21, 0.45, 7), 10, 0.2, P.teal, Enum.Material.Glass)
		water.Transparency = 0.3
		for _, delta in {Vector3.new(11, 0, 16), Vector3.new(32, 0, 3)} do
			local foot = c + delta
			rod(group, "PalmTrunk", foot + Vector3.new(0, 0.5, 0), foot + Vector3.new(2, 17, 0), 1.5, P.wood, Enum.Material.Wood)
			for index = 0, 5 do
				local angle = index * math.pi / 3
				piece(group, "PalmFrond", Vector3.new(1.5, 0.3, 11), CFrame.new(foot + Vector3.new(2 + math.sin(angle) * 4, 17.5, math.cos(angle) * 4)) * CFrame.Angles(0.2, angle, 0), P.moss, Enum.Material.Grass)
			end
		end
	end
	folder:SetAttribute("PartCount", count)
	folder:SetAttribute("PointLightCount", lightCount)
end
return Landmarks
