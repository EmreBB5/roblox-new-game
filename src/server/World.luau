-- Asset-free connected open world. Decorations are streamable; combat stays on the server.
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local World = {}
local weaponRequests = setmetatable({}, {__mode = "k"})
local gatherOffsets = {Vector3.new(-110, 0, 55), Vector3.new(105, 0, 65), Vector3.new(-120, 0, -40), Vector3.new(125, 0, -60), Vector3.new(-65, 0, 110)}

local palette = {
	grass = Color3.fromRGB(73, 108, 79),
	forest = Color3.fromRGB(38, 73, 64),
	stone = Color3.fromRGB(102, 119, 127),
	wood = Color3.fromRGB(91, 67, 61),
	roof = Color3.fromRGB(72, 91, 123),
	gold = Color3.fromRGB(248, 207, 119),
	magic = Color3.fromRGB(114, 233, 215),
}

local function part(parent, name, size, position, color, material)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Position = position
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.Anchored = true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function label(adornee, title, subtitle, width)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WorldLabel"
	billboard.Size = UDim2.fromOffset(width or 240, 64)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 100
	billboard.Adornee = adornee
	billboard.Parent = adornee
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = title .. "\n" .. subtitle
	text.TextColor3 = palette.gold
	text.TextStrokeTransparency = 0.35
	text.TextSize = 17
	text.Font = Enum.Font.GothamBold
	text.Parent = billboard
	return billboard
end

local function crystal(parent, position, scale)
	local gem = part(parent, "AetherCrystal", Vector3.new(1.6, 4, 1.6) * scale,
		position + Vector3.new(0, 2 * scale, 0), palette.magic, Enum.Material.Neon)
	gem.CFrame *= CFrame.Angles(0, math.rad(35), math.rad(15))
	gem.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = palette.magic
	light.Brightness = 0.7
	light.Range = 14 * scale
	light.Parent = gem
	return gem
end

local function tree(parent, position, scale, random)
	part(parent, "Trunk", Vector3.new(2.4, 12, 2.4) * scale,
		position + Vector3.new(0, 6 * scale, 0), palette.wood, Enum.Material.Wood)
	for tier = 1, 3 do
		local diameter = (15 - tier * 2) * scale
		local crown = part(parent, "Canopy", Vector3.new(diameter, 9 * scale, diameter),
			position + Vector3.new(0, (8 + tier * 3) * scale, 0),
			palette.forest:Lerp(palette.grass, random:NextNumber(0, 0.45)), Enum.Material.Grass)
		crown.Shape = Enum.PartType.Ball
		crown.CanCollide = false
	end
end

local function house(parent, position, yaw)
	local model = Instance.new("Model")
	model.Name = "VillageHouse"
	model.Parent = parent
	local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	local function block(name, size, offset, color, material)
		local item = part(model, name, size, Vector3.zero, color, material)
		item.CFrame = base * CFrame.new(offset)
		return item
	end
	block("Foundation", Vector3.new(19, 2, 16), Vector3.new(0, 1, 0), palette.stone, Enum.Material.Slate)
	block("Walls", Vector3.new(17, 10, 14), Vector3.new(0, 7, 0), Color3.fromRGB(204, 181, 141))
	block("Roof", Vector3.new(21, 3, 18), Vector3.new(0, 13, 0), palette.roof, Enum.Material.Slate)
	block("Door", Vector3.new(4, 7, 0.3), Vector3.new(0, 5.5, 7.2), palette.wood, Enum.Material.Wood)
	for _, x in {-5.5, 5.5} do
		block("Window", Vector3.new(2.8, 3, 0.3), Vector3.new(x, 8, 7.25), palette.gold, Enum.Material.Neon)
		block("Timber", Vector3.new(0.7, 10, 0.6), Vector3.new(x * 1.45, 7, 7.2), palette.wood, Enum.Material.Wood)
	end
	block("Chimney", Vector3.new(3, 6, 3), Vector3.new(5, 15, -3), palette.stone, Enum.Material.Brick)
end

local function guardian(parent)
	local model = Instance.new("Model")
	model.Name = "Eldrin"
	local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(15, 3, 0), palette.roof)
	root.Transparency = 1
	root.CanCollide = false
	part(model, "Robe", Vector3.new(2.8, 4, 2), Vector3.new(15, 2.5, 0), Color3.fromRGB(73, 65, 119))
	local head = part(model, "Head", Vector3.new(1.8, 1.8, 1.8), Vector3.new(15, 5.3, 0), Color3.fromRGB(223, 190, 151))
	head.Shape = Enum.PartType.Ball
	part(model, "HatBrim", Vector3.new(3.6, 0.35, 3.6), Vector3.new(15, 6.25, 0), palette.roof)
	part(model, "Hat", Vector3.new(2, 2, 2), Vector3.new(15, 7.2, 0), palette.roof)
	part(model, "Staff", Vector3.new(0.3, 6.5, 0.3), Vector3.new(17.3, 3.25, 0), palette.wood, Enum.Material.Wood)
	crystal(model, Vector3.new(17.3, 6.5, 0), 0.4)
	label(head, "ELDRİN", "Ormanın Muhafızı")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "QuestPrompt"
	prompt.ObjectText = "Eldrin · Ormanın Muhafızı"
	prompt.ActionText = "Konuş / görevi teslim et"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0.25
	prompt.Parent = root
	model.PrimaryPart = root
	model.Parent = parent
	return model, prompt
end

local function blacksmith(parent)
	local model = Instance.new("Model")
	model.Name = "Borin"
	local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(-14, 3, 12), palette.wood)
	root.Transparency = 1
	root.CanCollide = false
	part(model, "Apron", Vector3.new(2.7, 3.3, 1.6), Vector3.new(-14, 2.5, 12), Color3.fromRGB(108, 72, 49), Enum.Material.Fabric)
	local head = part(model, "Head", Vector3.new(1.8, 1.8, 1.8), Vector3.new(-14, 5, 12), Color3.fromRGB(207, 165, 126))
	head.Shape = Enum.PartType.Ball
	part(model, "Beard", Vector3.new(1.7, 1.2, 0.4), Vector3.new(-14, 4.5, 11.2), Color3.fromRGB(76, 66, 59))
	part(model, "AnvilBase", Vector3.new(3.4, 1.3, 2), Vector3.new(-9, 0.9, 12), palette.stone, Enum.Material.Metal)
	part(model, "AnvilTop", Vector3.new(5, 0.7, 2.2), Vector3.new(-9, 2, 12), Color3.fromRGB(77, 85, 95), Enum.Material.Metal)
	part(model, "ForgeCoals", Vector3.new(3.5, 0.4, 3.5), Vector3.new(-20, 0.6, 15), Color3.fromRGB(255, 143, 82), Enum.Material.Neon)
	label(head, "BORİN · DEMİRCİ", "Donanım yükseltme · Tarifler: C", 280)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ForgePrompt"
	prompt.ObjectText = "Borin · Demirci"
	prompt.ActionText = "Donanımı güçlendir"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.6
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	model.PrimaryPart = root
	model.Parent = parent
	return model, prompt
end

local regionColors = {
	forest = {ground = Color3.fromRGB(61, 96, 68), skin = Color3.fromRGB(109, 151, 91), accent = Color3.fromRGB(174, 235, 117)},
	marsh = {ground = Color3.fromRGB(58, 83, 93), skin = Color3.fromRGB(94, 169, 172), accent = Color3.fromRGB(127, 231, 241)},
	volcanic = {ground = Color3.fromRGB(82, 65, 65), skin = Color3.fromRGB(161, 91, 69), accent = Color3.fromRGB(255, 164, 80)},
	frost = {ground = Color3.fromRGB(207, 225, 235), skin = Color3.fromRGB(141, 192, 219), accent = Color3.fromRGB(178, 244, 255)},
	desert = {ground = Color3.fromRGB(211, 175, 111), skin = Color3.fromRGB(190, 148, 84), accent = Color3.fromRGB(255, 221, 121)},
}

local roads = {
	{{-8, -45}, {-130, -140}, 20}, {{-130, -140}, {-230, -245}, 20},
	{{8, -45}, {150, -170}, 20}, {{150, -170}, {260, -335}, 20},
	{{-150, -250}, {-110, -520}, 18}, {{190, -370}, {110, -520}, 18},
	{{-110, -520}, {0, -660}, 22}, {{110, -520}, {0, -660}, 22}, {{0, -660}, {0, -755}, 22},
	{{-110, -520}, {-340, -650}, 22}, {{-340, -650}, {-700, -835}, 22}, {{-700, -835}, {-760, -1020}, 22},
	{{110, -520}, {360, -610}, 22}, {{360, -610}, {730, -790}, 22}, {{730, -790}, {790, -990}, 22},
	{{-190, -140}, {-130, -140}, 14}, {{220, -215}, {190, -230}, 14}, {{18, -630}, {0, -660}, 14},
	{{-760, -1020}, {-760, -1155}, 16}, {{790, -990}, {790, -1125}, 16},
}

local function nearRoad(x, z)
	local point = Vector2.new(x, z)
	for _, road in roads do
		local from, to = Vector2.new(road[1][1], road[1][2]), Vector2.new(road[2][1], road[2][2])
		local segment = to - from
		local along = math.clamp((point - from):Dot(segment) / segment:Dot(segment), 0, 1)
		if (point - (from + segment * along)).Magnitude < road[3] / 2 + 10 then return true end
	end
	return false
end

local function frostDecoration(parent, position, random)
	if random:NextNumber() < 0.6 then
		local scale = random:NextNumber(1, 1.8)
		part(parent, "FrostPineTrunk", Vector3.new(2, 12, 2) * scale, position + Vector3.new(0, 6, 0) * scale, palette.wood, Enum.Material.Wood)
		for tier = 1, 3 do
			local size = (13 - tier * 2.3) * scale
			local crown = part(parent, "SnowCrown", Vector3.new(size, 6 * scale, size), position + Vector3.new(0, 6 + tier * 4, 0) * scale,
				if tier == 1 then Color3.fromRGB(80, 121, 133) else Color3.fromRGB(221, 237, 243), Enum.Material.Snow)
			crown.Shape = Enum.PartType.Ball
			crown.CanCollide = false
		end
	else
		local height = random:NextNumber(7, 21)
		local ice = part(parent, "GlacierShard", Vector3.new(5, height, 5), position + Vector3.new(0, height / 2, 0), regionColors.frost.accent, Enum.Material.Ice)
		ice.CFrame *= CFrame.Angles(0.12, random:NextNumber(0, math.pi), 0.13)
		ice.Transparency = 0.2
	end
end

local function desertDecoration(parent, position, random)
	if random:NextNumber() < 0.55 then
		local height = random:NextNumber(6, 11)
		local green = Color3.fromRGB(87, 128, 85)
		part(parent, "Cactus", Vector3.new(1.8, height, 1.8), position + Vector3.new(0, height / 2, 0), green, Enum.Material.Grass)
		for _, side in {-1, 1} do
			part(parent, "CactusArm", Vector3.new(3, 1.3, 1.3), position + Vector3.new(side * 1.8, height * 0.55, 0), green, Enum.Material.Grass)
			part(parent, "CactusTip", Vector3.new(1.3, 3, 1.3), position + Vector3.new(side * 3, height * 0.55 + 1, 0), green, Enum.Material.Grass)
		end
	else
		local height = random:NextNumber(5, 16)
		local pillar = part(parent, "AncientSandstone", Vector3.new(5, height, 5), position + Vector3.new(0, height / 2, 0), Color3.fromRGB(182, 143, 90), Enum.Material.Sandstone)
		pillar.CFrame *= CFrame.Angles(0, random:NextNumber(0, math.pi), 0.08)
		part(parent, "RuinedCapital", Vector3.new(7, 1.5, 7), position + Vector3.new(0, height, 0), regionColors.desert.ground, Enum.Material.Sandstone)
	end
end

local function disc(parent, name, position, radius, color, material)
	local item = part(parent, name, Vector3.new(0.25, radius * 2, radius * 2), position, color, material)
	item.Shape = Enum.PartType.Cylinder
	item.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	return item
end

local function travelShrines(parent)
	local folder = Instance.new("Folder")
	folder.Name = "TravelShrines"
	folder.Parent = parent
	local result = {}
	for id, definition in Config.Waypoints do
		local coordinates = definition.Position
		local position = Vector3.new(coordinates.x, coordinates.y, coordinates.z)
		local colors = regionColors[definition.RegionId]
		local accent = if colors then colors.accent else palette.magic
		local model = Instance.new("Model")
		model.Name = "Waypoint_" .. id
		-- Six small persistent platforms provide a floor before distant terrain streams in.
		model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		model.Parent = folder
		disc(model, "ShrinePlatform", position + Vector3.new(0, 0.3, 0), 11, palette.stone, Enum.Material.Slate)
		local rune = disc(model, "TravelRune", position + Vector3.new(0, 0.5, 0), 8, accent, Enum.Material.Neon)
		rune.Transparency = 0.5
		rune.CanCollide = false
		rune.CanTouch = false
		rune.CanQuery = false
		for _, side in {-1, 1} do
			local column = position + Vector3.new(side * 7, 0, -4)
			part(model, "ShrineColumn", Vector3.new(2.3, 7, 2.3), column + Vector3.new(0, 3.5, 0), palette.stone, Enum.Material.Slate)
			local gem = crystal(model, column + Vector3.new(0, 7, 0), 0.45)
			gem.Color = accent
		end
		local focus = crystal(model, position + Vector3.new(0, 0.7, -3), 1)
		focus.Color = accent
		label(focus, definition.Name, "SEYAHAT TÜRBESİ · Keşfet / haritayı aç: E", 340)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DiscoverWaypoint"
		prompt.ObjectText = definition.Name
		prompt.ActionText = "Keşfet / seyahat haritasını aç"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.MaxActivationDistance = 12
		prompt.HoldDuration = 0.5
		prompt.RequiresLineOfSight = false
		prompt.Parent = focus
		model.PrimaryPart = focus
		result[id] = {
			id = id, prompt = prompt, position = position,
			-- The open front of the platform stays clear of columns and the crystal.
			arrival = CFrame.new(position + Vector3.new(0, 4, 9)),
		}
	end
	return result
end

local function regionalContractBoards(parent)
	local folder = Instance.new("Folder")
	folder.Name = "RegionalContractBoards"
	folder.Parent = parent
	local result = {}
	for id, region in Config.Regions do
		local coordinates = Config.Waypoints[id].Position
		local position = Vector3.new(coordinates.x + 18, 2.8, coordinates.z + 10)
		local model = Instance.new("Model")
		model.Name = "ContractBoard_" .. id
		model:SetAttribute("RegionalContractId", id)
		model:SetAttribute("ContractPosition", position)
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		model.Parent = folder
		for _, side in {-1, 1} do
			part(model, "BoardPost", Vector3.new(0.7, 6.5, 0.7), position + Vector3.new(side * 3.4, 0.45, 0), palette.wood, Enum.Material.Wood)
		end
		local board = part(model, "NoticeBoard", Vector3.new(8, 4.8, 0.7), position + Vector3.new(0, 1.2, 0), palette.wood, Enum.Material.Wood)
		part(model, "ContractParchment", Vector3.new(6.6, 3.5, 0.1), position + Vector3.new(0, 1.2, 0.42), Color3.fromRGB(230, 213, 167))
		local seal = part(model, "RegionalSeal", Vector3.new(0.8, 0.8, 0.15), position + Vector3.new(2.2, 0.2, 0.53), regionColors[id].accent, Enum.Material.Neon)
		seal.Shape = Enum.PartType.Ball
		seal.CanCollide, seal.CanTouch, seal.CanQuery = false, false, false
		label(board, region.Name .. " · BÖLGE İŞLERİ", "5 yaratık · 3 toplama · Türbeyi keşfet\nGörevi al / ödülü teslim al: E", 340).MaxDistance = 75
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "RegionalContractPrompt"
		prompt.ObjectText = region.Name .. " · Görev Panosu"
		prompt.ActionText = "Bölge işlerini incele"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.MaxActivationDistance = 12
		prompt.HoldDuration = 0.35
		prompt.RequiresLineOfSight = false
		prompt.Parent = board
		model.PrimaryPart = board
		result[id] = {id = id, prompt = prompt, position = position}
	end
	return result
end

local function path(parent, from, to, width)
	from = Vector3.new(from.X, 0.4, from.Z)
	to = Vector3.new(to.X, 0.4, to.Z)
	local road = part(parent, "TravelRoad", Vector3.new(width, 0.18, (to - from).Magnitude),
		(from + to) / 2, Color3.fromRGB(159, 141, 111), Enum.Material.Ground)
	road.CFrame = CFrame.lookAt((from + to) / 2, to)
end

local function arena(parent, bossId, definition)
	local center = Vector3.new(definition.X, 0.25, definition.Z)
	local colors = regionColors[definition.RegionId]
	disc(parent, "Arena_" .. bossId, center, 64, palette.stone:Lerp(colors.ground, 0.65), Enum.Material.Slate)
	for index = 1, 12 do
		local angle = index * math.pi * 2 / 12
		local marker = center + Vector3.new(math.cos(angle) * 60, 1, math.sin(angle) * 60)
		local rune = part(parent, "ArenaRune", Vector3.new(2, 0.3, 6), marker, colors.accent, Enum.Material.Neon)
		rune.CFrame = CFrame.new(marker) * CFrame.Angles(0, -angle, 0)
		rune.CanCollide = false
		rune.CanQuery = false
	end
	for _, direction in {-1, 1} do
		local column = center + Vector3.new(direction * 53, 0, 25)
		part(parent, "ArenaColumn", Vector3.new(5, 12, 5), column + Vector3.new(0, 6, 0), palette.stone, Enum.Material.Slate)
		crystal(parent, column + Vector3.new(0, 12, 0), 0.8)
	end
	local sign = part(parent, "BossSign", Vector3.new(8, 6, 1), center + Vector3.new(0, 5, 73), palette.wood, Enum.Material.Wood)
	label(sign, definition.Name, string.format("HER SAAT :%02d · Nadir pet %%3", definition.Minute), 320)
end

local function eliteSanctums(parent)
	for id, definition in Config.Elites do
		local model = Instance.new("Model")
		model.Name = "EliteSanctum_" .. id
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		model.Parent = parent
		local position = Vector3.new(definition.X, 0.35, definition.Z)
		local colors = regionColors[definition.RegionId]
		disc(model, "EliteArena", position, 44, colors.ground:Lerp(palette.stone, 0.3), Enum.Material.Slate)
		for index = 1, 8 do
			local angle = index * math.pi / 4
			local marker = position + Vector3.new(math.cos(angle) * 40, 0.3, math.sin(angle) * 40)
			local rune = part(model, "EliteRune", Vector3.new(3, 0.2, 3), marker, colors.accent, Enum.Material.Neon)
			rune.CanCollide, rune.CanTouch, rune.CanQuery = false, false, false
		end
		for _, side in {-1, 1} do
			local column = position + Vector3.new(side * 31, 0, -23)
			part(model, "EliteObelisk", Vector3.new(3, 9, 3), column + Vector3.new(0, 4.5, 0), palette.stone, Enum.Material.Slate)
			local focus = crystal(model, column + Vector3.new(0, 9, 0), 0.5)
			focus.Color = colors.accent
		end
		local sign = part(model, "EliteSign", Vector3.new(8, 5, 1), position + Vector3.new(24, 3.3, 44), palette.wood, Enum.Material.Wood)
		label(sign, "ELİT · " .. definition.Name, "Alan uyarısından kaç · Pet eğitimi ve malzeme", 330)
	end
end

local function resourceNodes(parent)
	local folder = Instance.new("Folder")
	folder.Name = "GatheringNodes"
	folder.Parent = parent
	local result = {}
	local definitions = {
		{regionId = "forest", kind = "wood", name = "Yaban Odunu", color = Color3.fromRGB(140, 112, 70), material = Enum.Material.Wood},
		{regionId = "marsh", kind = "iron", name = "Sis Demiri", color = Color3.fromRGB(151, 181, 200), material = Enum.Material.Metal},
		{regionId = "volcanic", kind = "ember", name = "Köz Cevheri", color = Color3.fromRGB(247, 152, 81), material = Enum.Material.Neon},
		{regionId = "frost", kind = "iron", name = "Buzul Demiri", color = Color3.fromRGB(171, 223, 245), material = Enum.Material.Ice},
		{regionId = "desert", kind = "ember", name = "Güneş Cevheri", color = Color3.fromRGB(246, 209, 104), material = Enum.Material.Sandstone},
	}
	for _, definition in definitions do
		local region = Config.Regions[definition.regionId]
		for index, offset in gatherOffsets do
			local position = Vector3.new(region.X, 0.5, region.Z) + offset
			local node = Instance.new("Model")
			node.Name = definition.name .. " " .. index
			node.Parent = folder
			local base = part(node, "Resource", Vector3.new(3.2, 3.2, 3.2), position + Vector3.new(0, 1.7, 0), definition.color, definition.material)
			base.CFrame *= CFrame.Angles(0, index * 0.7, 0.12)
			if definition.kind == "wood" then
				for _, side in {-1, 1} do
					part(node, "WoodBundle", Vector3.new(1.2, 1.3, 4.3), position + Vector3.new(side * 1.3, 0.9, 0), definition.color, Enum.Material.Wood)
				end
			else
				local shard = part(node, "OreVein", Vector3.new(0.8, 3.6, 0.8), position + Vector3.new(1, 2.5, 0), definition.color, Enum.Material.Neon)
				shard.CFrame *= CFrame.Angles(0, 0.4, 0.3)
				shard.CanCollide = false
			end
			label(base, definition.name, "Topla · E", 190).MaxDistance = 65
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "GatherPrompt"
			prompt.ObjectText = definition.name
			prompt.ActionText = "Malzeme topla"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.HoldDuration = 1.2
			prompt.Parent = base
			node.PrimaryPart = base
			table.insert(result, {id = definition.regionId .. "_" .. index, regionId = definition.regionId, kind = definition.kind, amount = 1, prompt = prompt, position = base.Position})
		end
	end
	return result
end

function World.build()
	assert(not workspace:FindFirstChild("AetheriaWorld"), "World already exists")
	local folder = Instance.new("Folder")
	folder.Name = "AetheriaWorld"
	folder.Parent = workspace
	Lighting.ClockTime = 15.5
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(104, 119, 141)
	Lighting.OutdoorAmbient = Color3.fromRGB(131, 146, 161)
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.19
	atmosphere.Color = Color3.fromRGB(197, 217, 223)
	atmosphere.Decay = Color3.fromRGB(104, 126, 145)
	atmosphere.Parent = Lighting
	local bounds = Config.MapBounds
	-- BasePart dimensions are limited to 2048 studs; tile the expanded world.
	for x = bounds.MinX, bounds.MaxX - 1, 1000 do
		for z = bounds.MinZ, bounds.MaxZ - 1, 800 do
			part(folder, "OpenWorldGround", Vector3.new(1000, 6, 800), Vector3.new(x + 500, -3, z + 400), palette.grass, Enum.Material.Grass)
		end
	end
	part(folder, "VillageSquare", Vector3.new(110, 0.3, 100), Vector3.new(0, 0.12, 4), Color3.fromRGB(157, 147, 122), Enum.Material.Cobblestone)
	local boundary = disc(folder, "VillageSanctuary", Vector3.new(0, 0.35, 0), Config.SafeZoneRadius, palette.magic, Enum.Material.Neon)
	boundary.Transparency = 0.87
	boundary.CanCollide = false
	boundary.CanQuery = false
	house(folder, Vector3.new(-37, 0, 19), math.rad(70))
	house(folder, Vector3.new(39, 0, 27), math.rad(-90))
	house(folder, Vector3.new(-29, 0, -27), math.rad(15))
	house(folder, Vector3.new(36, 0, -34), math.rad(-35))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "VillageSpawn"
	spawn.Size = Vector3.new(7, 0.25, 7)
	spawn.Position = Vector3.new(0, 0.65, 19)
	spawn.Color = palette.magic
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Duration = 3
	spawn.Anchored = true
	spawn.Parent = folder
	local spawnLabel = label(spawn, "AETHERIA · UFUKLAR", "Güvenli köy · Eldrin ile konuş", 330)
	spawnLabel.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	local npc, prompt = guardian(folder)
	local smith, forgePrompt = blacksmith(folder)
	local board = part(folder, "ExpeditionBoard", Vector3.new(13, 8, 1), Vector3.new(-16, 6, 0), palette.wood, Enum.Material.Wood)
	label(board, "SINIF: C · GRUP: G", "HARİTA: M  ·  PETLER: P  ·  YETENEK: Q/R\nTürbeleri keşfet · Arkadaşlarınla savaş", 390)
	-- One continuous map; roads join all regions without loading screens.
	for id, region in Config.Regions do
		local colors = regionColors[id]
		local zone = Instance.new("Folder")
		zone.Name = "Region_" .. id
		zone.Parent = folder
		disc(zone, "BiomeGround", Vector3.new(region.X, 0.12, region.Z), region.Radius, colors.ground, Enum.Material[region.Ground])
	end
	for _, road in roads do path(folder, Vector3.new(road[1][1], 0, road[1][2]), Vector3.new(road[2][1], 0, road[2][2]), road[3]) end
	local junction = part(folder, "FrontierSign", Vector3.new(12, 6, 1), Vector3.new(0, 4, -535), palette.wood, Enum.Material.Wood)
	label(junction, "YENİ UFUKLAR", "Batı: Buzul · Sv.8  /  Doğu: Çöl · Sv.11\nGüney: Köy  /  Kuzey: Köz", 390)
	-- Village arch and regional welcome stones provide navigation on foot.
	for _, x in {-10, 10} do
		part(folder, "GatePillar", Vector3.new(4, 15, 4), Vector3.new(x, 7.5, -62), palette.stone, Enum.Material.Slate)
		crystal(folder, Vector3.new(x, 15, -62), 0.8)
	end
	local arch = part(folder, "GateArch", Vector3.new(24, 3, 4), Vector3.new(0, 16, -62), palette.stone, Enum.Material.Slate)
	label(arch, "AÇIK DÜNYAYA ÇIKIŞ", "Batı: Orman  ·  Doğu: Bataklık  ·  Kuzey: Köz", 370)
	local random = Random.new(418)
	for id, region in Config.Regions do
		local zone = folder["Region_" .. id]
		local colors = regionColors[id]
		local gatePosition = Vector3.new(region.X, 4, region.Z + region.Radius * 0.62)
		local marker = part(zone, "WelcomeStone", Vector3.new(7, 8, 3), gatePosition, palette.stone, Enum.Material.Slate)
		label(marker, region.Name, "Önerilen seviye " .. region.EnemyLevel .. " · Harita: M", 330)
		for _ = 1, (if id == "forest" then 85 elseif id == "frost" or id == "desert" then 100 else 45) do
			local x = region.X + random:NextNumber(-region.Radius, region.Radius)
			local z = region.Z + random:NextNumber(-region.Radius, region.Radius)
			local radial = Vector2.new(x - region.X, z - region.Z).Magnitude
			local blocked = radial > region.Radius or radial < 90
			if nearRoad(x, z) then blocked = true end
			for _, offset in gatherOffsets do
				if Vector2.new(x - region.X - offset.X, z - region.Z - offset.Z).Magnitude < 12 then blocked = true end
			end
			if Vector2.new(x + 910, z + 1110).Magnitude < 75 or Vector2.new(x - 920, z + 1110).Magnitude < 50 then blocked = true end
			for _, boss in Config.Bosses do
				if Vector2.new(x - boss.X, z - boss.Z).Magnitude < 86 then blocked = true end
			end
			for _, elite in Config.Elites do
				if Vector2.new(x - elite.X, z - elite.Z).Magnitude < 60 then blocked = true end
			end
			for _, waypoint in Config.Waypoints do
				local point = waypoint.Position
				if Vector2.new(x - point.x, z - point.z).Magnitude < 24 then blocked = true end
				if Vector2.new(x - point.x - 18, z - point.z - 10).Magnitude < 12 then blocked = true end
			end
			-- Wide approach lanes stay clear for simple Humanoid steering.
			if math.abs(x - region.X) < 28 or math.abs(z - region.Z) < 23 then blocked = true end
			if blocked then continue end
			local location = Vector3.new(x, 0.3, z)
			if id == "forest" then
				tree(zone, location, random:NextNumber(1.2, 2.1), random)
			elseif id == "marsh" then
				local pool = disc(zone, "ShallowMagicPool", location, random:NextNumber(7, 14), colors.accent, Enum.Material.Glass)
				pool.Transparency = 0.55
				pool.CanCollide = false
				pool.CanQuery = false
				crystal(zone, location + Vector3.new(4, 0, 3), random:NextNumber(1, 2))
			elseif id == "frost" then
				frostDecoration(zone, location, random)
			elseif id == "desert" then
				desertDecoration(zone, location, random)
			else
				local height = random:NextNumber(8, 23)
				part(zone, "ObsidianSpire", Vector3.new(7, height, 7), location + Vector3.new(0, height / 2, 0), Color3.fromRGB(53, 48, 60), Enum.Material.Basalt)
				local ember = part(zone, "EmberSeam", Vector3.new(0.25, height * 0.8, 7.2), location + Vector3.new(3.6, height / 2, 0), colors.accent, Enum.Material.Neon)
				ember.CanCollide = false
				ember.CanQuery = false
			end
		end
	end
	-- Distinct landmarks outside combat clearings, reachable from the regional roads.
	local glacier = part(folder, "FrozenLake", Vector3.new(110, 0.3, 74), Vector3.new(-910, 0.35, -1110), Color3.fromRGB(138, 199, 224), Enum.Material.Ice)
	glacier.Transparency = 0.25
	local oasis = disc(folder, "DesertOasis", Vector3.new(920, 0.38, -1110), 36, Color3.fromRGB(90, 178, 188), Enum.Material.Glass)
	oasis.Transparency = 0.35
	oasis.CanCollide = false
	oasis.CanQuery = false
	for id, definition in Config.Bosses do arena(folder, id, definition) end
	eliteSanctums(folder)
	local nodes = resourceNodes(folder)
	local waypoints = travelShrines(folder)
	local contractBoards = regionalContractBoards(folder)
	local enemySpawns = {}
	for id, region in Config.Regions do
		for _, offset in {Vector3.new(-58, 0, 42), Vector3.new(52, 0, 37), Vector3.new(-74, 0, -27), Vector3.new(72, 0, -32)} do
			table.insert(enemySpawns, {position = Vector3.new(region.X, 0.5, region.Z) + offset, regionId = id})
		end
	end
	-- Low-detail mountain ridges bound the walkable world.
	for x = bounds.MinX, bounds.MaxX - 1, 1000 do
		for _, z in {bounds.MinZ + 10, bounds.MaxZ - 10} do
			part(folder, "MountainRidge", Vector3.new(1000, 80, 20), Vector3.new(x + 500, 38, z), palette.forest, Enum.Material.Rock)
		end
	end
	for z = bounds.MinZ, bounds.MaxZ - 1, 800 do
		for _, x in {bounds.MinX + 10, bounds.MaxX - 10} do
			part(folder, "MountainRidge", Vector3.new(20, 80, 800), Vector3.new(x, 38, z + 400), palette.forest, Enum.Material.Rock)
		end
	end
	local enemies = Instance.new("Folder")
	enemies.Name = "Enemies"
	enemies.Parent = folder
	return {
		Spawn = spawn,
		QuestGiver = npc,
		QuestPrompt = prompt,
		Blacksmith = smith,
		ForgePrompt = forgePrompt,
		ResourceNodes = nodes,
		Waypoints = waypoints,
		ContractBoards = contractBoards,
		EnemySpawns = enemySpawns,
		EnemyFolder = enemies,
		SafeZoneCenter = Vector3.zero,
		SafeZoneRadius = Config.SafeZoneRadius,
	}
end

-- Equipment is cosmetic geometry. Combat stats come from validated server data.
function World.equipWeapon(character, classId, tier)
	local request = (weaponRequests[character] or 0) + 1
	weaponRequests[character] = request
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand then hand = character:WaitForChild("RightHand", 3) or character:FindFirstChild("Right Arm") end
	if not hand or not hand:IsA("BasePart") or not character.Parent or weaponRequests[character] ~= request then return end
	-- Clean up after the only yield; a stale request cannot duplicate equipment.
	local previous = character:FindFirstChild("AetheriaWeapon")
	if previous then previous:Destroy() end
	for _, name in {"SwordGrip", "SwordBlade"} do
		local legacy = character:FindFirstChild(name)
		if legacy then legacy:Destroy() end
	end
	local colors = {
		[0] = Color3.fromRGB(194, 216, 230),
		[1] = Color3.fromRGB(153, 224, 156),
		[2] = Color3.fromRGB(127, 211, 240),
		[3] = Color3.fromRGB(255, 175, 100),
	}
	local color = colors[tier] or colors[0]
	local weapon = Instance.new("Model")
	weapon.Name = "AetheriaWeapon"
	local grip = if classId == "mage" then hand.CFrame else hand.CFrame * CFrame.new(0, -0.2, -0.4) * CFrame.Angles(-math.pi / 2, 0, 0)
	local function piece(name, size, offset, tint, material)
		local item = part(weapon, name, size, Vector3.zero, tint, material)
		item.Anchored = false
		item.Massless = true
		item.CanCollide = false
		item.CanTouch = false
		item.CanQuery = false
		item.CFrame = grip * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = item
		weld.Parent = item
		return item
	end
	if classId == "mage" then
		piece("Staff", Vector3.new(0.3, 4, 0.3), CFrame.new(), palette.wood, Enum.Material.Wood)
		local gem = piece("Focus", Vector3.new(0.85, 0.85, 0.85), CFrame.new(0, 2.35, 0), color, Enum.Material.Neon)
		gem.Shape = Enum.PartType.Ball
		piece("FocusRing", Vector3.new(1.4, 0.2, 0.6), CFrame.new(0, 1.9, 0), palette.gold, Enum.Material.Metal)
	else
		piece("Grip", Vector3.new(0.3, 1, 0.3), CFrame.new(), palette.wood, Enum.Material.Wood)
		piece("Guard", Vector3.new(1.6, 0.25, 0.4), CFrame.new(0, 0.6, 0), palette.gold, Enum.Material.Metal)
		piece("Blade", Vector3.new(0.45, 3, 0.18), CFrame.new(0, 2.1, 0), color, Enum.Material.Metal)
	end
	weapon.Parent = character
end

function World.createEnemy(folder, position, index, regionId)
	local model = Instance.new("Model")
	local region = Config.Regions[regionId or "forest"] or Config.Regions.forest
	model.Name = region.EnemyName .. " " .. tostring(index)
	model:SetAttribute("AetheriaEnemy", true)
	model:SetAttribute("EnemyKind", "normal")
	model:SetAttribute("RegionId", regionId or "forest")
	local behavior = Config.EnemyBehaviors[regionId or "forest"]
	model:SetAttribute("EnemyBehavior", behavior and behavior.Kind or "melee")
	local base = position + Vector3.new(0, 3, 0)
	local colors = regionColors[regionId or "forest"] or regionColors.forest
	local skin = colors.skin
	local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), base, skin)
	root.Transparency = 1
	root.CanCollide = false
	local torso = part(model, "Torso", Vector3.new(2, 2, 1), base, colors.ground)
	local head = part(model, "Head", Vector3.new(2, 1, 1), base + Vector3.new(0, 1.5, 0), skin)
	local function joint(name, p0, p1, offset)
		local motor = Instance.new("Motor6D")
		motor.Name = name
		motor.Part0 = p0
		motor.Part1 = p1
		motor.C0 = CFrame.new(offset)
		motor.Parent = p0
	end
	joint("RootJoint", root, torso, Vector3.zero)
	joint("Neck", torso, head, Vector3.new(0, 1.5, 0))
	for _, side in {{"Left", -1}, {"Right", 1}} do
		local arm = part(model, side[1] .. " Arm", Vector3.new(1, 2, 1), base + Vector3.new(side[2] * 1.5, 0, 0), skin)
		joint(side[1] .. " Shoulder", torso, arm, Vector3.new(side[2] * 1.5, 0, 0))
		local leg = part(model, side[1] .. " Leg", Vector3.new(1, 2, 1), base + Vector3.new(side[2] * 0.5, -2, 0), palette.forest)
		joint(side[1] .. " Hip", torso, leg, Vector3.new(side[2] * 0.5, -2, 0))
	end
	for _, x in {-0.45, 0.45} do
		local eye = part(model, "GlowingEye", Vector3.new(0.25, 0.2, 0.15), base + Vector3.new(x, 1.6, -0.55), colors.accent, Enum.Material.Neon)
		joint("Eye", head, eye, Vector3.new(x, 0.1, -0.55))
		eye.CanCollide = false
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = region.EnemyName
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayDistance = 70
	humanoid.NameDisplayDistance = 70
	humanoid.HipHeight = 0
	humanoid.Parent = model
	model.PrimaryPart = root
	for _, item in model:GetChildren() do
		if item:IsA("BasePart") then
			item.Anchored = false
			if item ~= root and item ~= torso then
				item.CanCollide = false
				item.Massless = true
			end
		end
	end
	model.Parent = folder
	root:SetNetworkOwner(nil)
	return model
end

function World.createBoss(folder, definition)
	local model = World.createEnemy(folder, Vector3.new(definition.X, 0.5, definition.Z), definition.Name, definition.RegionId)
	model.Name = definition.Name
	model:SetAttribute("EnemyKind", "boss")
	model:SetAttribute("EnemyBehavior", "boss")
	model.Humanoid.DisplayName = "WORLD BOSS · " .. definition.Name
	model.Humanoid.HealthDisplayDistance = 180
	model.Humanoid.NameDisplayDistance = 180
	local colors = regionColors[definition.RegionId]
	local torso = model.Torso
	-- Distinct silhouettes without imported assets: antlers, fins, or drake wings.
	local function ornament(name, size, offset, color, material)
		local item = part(model, name, size, Vector3.zero, color, material)
		item.Anchored = false
		item.CanCollide = false
		item.CanTouch = false
		item.CanQuery = false
		item.Massless = true
		item.CFrame = torso.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = item
		weld.Parent = item
	end
	for _, direction in {-1, 1} do
		if definition.RegionId == "forest" then
			ornament("RootAntler", Vector3.new(0.4, 2.8, 0.4), CFrame.new(direction * 0.9, 2.4, 0) * CFrame.Angles(0, 0, -direction * 0.45), palette.wood, Enum.Material.Wood)
			ornament("LeafCrown", Vector3.new(1.6, 0.5, 1.5), CFrame.new(direction * 1.5, 3.5, 0), colors.accent, Enum.Material.Grass)
		elseif definition.RegionId == "marsh" then
			ornament("CrystalFin", Vector3.new(0.25, 3.2, 1.8), CFrame.new(direction * 1.4, 1, 0) * CFrame.Angles(0, 0, direction * 0.4), colors.accent, Enum.Material.Neon)
		else
			ornament("DrakeWing", Vector3.new(3.5, 2.2, 0.3), CFrame.new(direction * 2.5, 0.7, 0.7) * CFrame.Angles(0, direction * -0.5, direction * 0.3), colors.skin, Enum.Material.Basalt)
			ornament("EmberHorn", Vector3.new(0.4, 1.5, 0.4), CFrame.new(direction * 0.6, 2.3, 0), colors.accent, Enum.Material.Neon)
		end
	end
	local scale = 2.8
	model:ScaleTo(scale)
	model:PivotTo(CFrame.new(definition.X, 0.5 + 3 * scale, definition.Z))
	model.PrimaryPart:SetNetworkOwner(nil)
	return model
end

function World.createElite(folder, definition)
	local model = World.createEnemy(folder, Vector3.new(definition.X, 0.5, definition.Z), definition.Name, definition.RegionId)
	model.Name = definition.Name
	model:SetAttribute("EnemyKind", "elite")
	model:SetAttribute("EnemyBehavior", "elite")
	model.Humanoid.DisplayName = "ELİT · " .. definition.Name
	model.Humanoid.HealthDisplayDistance = 130
	model.Humanoid.NameDisplayDistance = 130
	local colors, torso = regionColors[definition.RegionId], model.Torso
	local function ornament(name, size, offset, color, material)
		local item = part(model, name, size, Vector3.zero, color, material)
		item.Anchored, item.Massless = false, true
		item.CanCollide, item.CanTouch, item.CanQuery = false, false, false
		item.CFrame = torso.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = torso, item, item
	end
	if definition.RegionId == "frost" then
		for _, side in {-1, 1} do
			ornament("GlacialShoulder", Vector3.new(1.6, 1.5, 1.4), CFrame.new(side * 1.3, 0.7, 0), colors.accent, Enum.Material.Ice)
			ornament("GlacialCrown", Vector3.new(0.4, 1.8, 0.5), CFrame.new(side * 0.7, 2.5, 0) * CFrame.Angles(0, 0, -side * 0.3), colors.accent, Enum.Material.Neon)
		end
	else
		ornament("SunCrown", Vector3.new(2.2, 0.4, 1.5), CFrame.new(0, 2.2, 0), palette.gold, Enum.Material.Metal)
		ornament("SolarSpear", Vector3.new(0.3, 5, 0.3), CFrame.new(-1.8, 0.4, 0), palette.gold, Enum.Material.Metal)
		ornament("SolarSpearhead", Vector3.new(0.8, 1, 0.4), CFrame.new(-1.8, 3.3, 0), colors.accent, Enum.Material.Neon)
		ornament("SandstoneGuard", Vector3.new(1.2, 2.5, 0.4), CFrame.new(1.6, 0.1, -0.6), colors.ground, Enum.Material.Sandstone)
	end
	local scale = 1.65
	model:ScaleTo(scale)
	model:PivotTo(CFrame.new(definition.X, 0.5 + 3 * scale, definition.Z))
	model.PrimaryPart:SetNetworkOwner(nil)
	return model
end

function World.createEliteTelegraph(position, _direction, definition)
	local colors = regionColors[definition.RegionId]
	local warning = disc(workspace.AetheriaWorld, "EliteAttackWarning", Vector3.new(position.X, 0.65, position.Z), definition.Radius, colors.accent, Enum.Material.Neon)
	warning.Transparency = 0.32
	warning.CanCollide, warning.CanTouch, warning.CanQuery = false, false, false
	local attack = if definition.RegionId == "frost" then "BUZ PATLAMASI" else "KUM DAMGASI"
	local notice = label(warning, attack .. " · ALANDAN ÇIK!", string.format("%.1f sn sonra saldırı", definition.Windup), 300)
	notice.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	Debris:AddItem(warning, definition.Windup)
	return warning
end

function World.createEnemyTelegraph(position, definition, regionId)
	local colors = regionColors[regionId]
	local color = colors and colors.accent or Color3.fromRGB(255, 192, 96)
	local warning = disc(workspace.AetheriaWorld, "EnemyAttackWarning", Vector3.new(position.X, 0.58, position.Z), definition.Radius, color, Enum.Material.Neon)
	warning.Transparency = 0.4
	warning.CanCollide, warning.CanTouch, warning.CanQuery = false, false, false
	local action = if definition.Kind == "ranged" or definition.Kind == "targeted" then "UZAK SALDIRI" elseif definition.Kind == "slam" or definition.Kind == "area" then "YER SARSINTISI" else "DARBE HAZIRLIĞI"
	local notice = label(warning, action, "İşaretli alandan çık", 220)
	notice.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	notice.MaxDistance = 70
	Debris:AddItem(warning, math.max(0.1, definition.Windup))
	return warning
end

function World.createTelegraph(position, radius, duration)
	local warning = disc(workspace.AetheriaWorld, "BossAttackWarning", Vector3.new(position.X, 0.6, position.Z), radius, Color3.fromRGB(255, 91, 74), Enum.Material.Neon)
	warning.Transparency = 0.38
	warning.CanCollide = false
	warning.CanTouch = false
	warning.CanQuery = false
	local notice = label(warning, "ALANDAN ÇIK!", "Boss saldırısı hazırlanıyor", 240)
	notice.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	Debris:AddItem(warning, duration)
	return warning
end

return World
