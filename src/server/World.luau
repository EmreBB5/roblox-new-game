-- An asset-free, shared fantasy zone. Generated at server startup, never per player.
local Lighting = game:GetService("Lighting")
local World = {}

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

function World.build()
	assert(not workspace:FindFirstChild("AetheriaWorld"), "World already exists")
	local folder = Instance.new("Folder")
	folder.Name = "AetheriaWorld"
	folder.Parent = workspace
	Lighting.ClockTime = 16
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(104, 119, 141)
	Lighting.OutdoorAmbient = Color3.fromRGB(131, 146, 161)
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.24
	atmosphere.Color = Color3.fromRGB(197, 217, 223)
	atmosphere.Decay = Color3.fromRGB(104, 126, 145)
	atmosphere.Parent = Lighting
	part(folder, "Ground", Vector3.new(460, 4, 380), Vector3.new(0, -2, -65), palette.grass, Enum.Material.Grass)
	part(folder, "VillageSquare", Vector3.new(75, 0.15, 68), Vector3.new(0, 0.06, 4), Color3.fromRGB(157, 147, 122), Enum.Material.Cobblestone)
	part(folder, "ForestPath", Vector3.new(13, 0.12, 125), Vector3.new(0, 0.08, -85), Color3.fromRGB(160, 143, 111), Enum.Material.Ground)
	house(folder, Vector3.new(-30, 0, 13), math.rad(70))
	house(folder, Vector3.new(31, 0, 23), math.rad(-90))
	house(folder, Vector3.new(-22, 0, -23), math.rad(15))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "VillageSpawn"
	spawn.Size = Vector3.new(7, 0.25, 7)
	spawn.Position = Vector3.new(0, 0.25, 19)
	spawn.Color = palette.magic
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Duration = 3
	spawn.Anchored = true
	spawn.Parent = folder
	local spawnLabel = label(spawn, "AETHERIA", "Güvenli bölge · Eldrin ile konuş", 300)
	spawnLabel.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	local npc, prompt = guardian(folder)
	-- Ruined gate points the player toward the combat area.
	for _, x in {-10, 10} do
		part(folder, "GatePillar", Vector3.new(4, 15, 4), Vector3.new(x, 7.5, -45), palette.stone, Enum.Material.Slate)
		crystal(folder, Vector3.new(x, 15, -45), 0.8)
	end
	local arch = part(folder, "GateArch", Vector3.new(24, 3, 4), Vector3.new(0, 16, -45), palette.stone, Enum.Material.Slate)
	label(arch, "FISILTI ORMANI", "Yoldan ilerle · Yaratıklara dikkat", 300)
	local random = Random.new(418)
	for _ = 1, 78 do
		local x = random:NextNumber(-190, 190)
		local z = random:NextNumber(-220, 85)
		-- Keep village, main path, and the central combat clearing unobstructed.
		local village = Vector2.new(x, z).Magnitude < 60
		local path = math.abs(x) < 17 and z > -155
		local clearing = math.abs(x) < 70 and z < -60 and z > -155
		if not village and not path and not clearing then
			tree(folder, Vector3.new(x, 0, z), random:NextNumber(0.8, 1.5), random)
		end
	end
	for _, position in {Vector3.new(-44, 0, -75), Vector3.new(49, 0, -105), Vector3.new(-42, 0, -142)} do
		part(folder, "CrystalBase", Vector3.new(7, 2, 6), position + Vector3.new(0, 1, 0), palette.stone, Enum.Material.Slate)
		crystal(folder, position + Vector3.new(0, 2, 0), 1.3)
	end
	-- A perimeter prevents falling off the prototype map.
	for _, wall in {
		{Vector3.new(460, 30, 8), Vector3.new(0, 13, -253)},
		{Vector3.new(460, 30, 8), Vector3.new(0, 13, 123)},
		{Vector3.new(8, 30, 380), Vector3.new(-226, 13, -65)},
		{Vector3.new(8, 30, 380), Vector3.new(226, 13, -65)},
	} do
		part(folder, "MountainRidge", wall[1], wall[2], palette.forest, Enum.Material.Rock)
	end
	local enemies = Instance.new("Folder")
	enemies.Name = "Enemies"
	enemies.Parent = folder
	return {
		Spawn = spawn,
		QuestGiver = npc,
		QuestPrompt = prompt,
		EnemySpawns = {Vector3.new(-22, 0, -86), Vector3.new(23, 0, -105), Vector3.new(-24, 0, -128), Vector3.new(28, 0, -143)},
		EnemyFolder = enemies,
		SafeZoneCenter = Vector3.zero,
		SafeZoneRadius = 43,
	}
end

function World.createEnemy(folder, position, index)
	local model = Instance.new("Model")
	model.Name = "Orman Yaratığı " .. tostring(index)
	local base = position + Vector3.new(0, 3, 0)
	local skin = Color3.fromRGB(113, 144, 107)
	local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), base, skin)
	root.Transparency = 1
	root.CanCollide = false
	local torso = part(model, "Torso", Vector3.new(2, 2, 1), base, palette.wood)
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
		local eye = part(model, "GlowingEye", Vector3.new(0.25, 0.2, 0.15), base + Vector3.new(x, 1.6, -0.55), palette.magic, Enum.Material.Neon)
		joint("Eye", head, eye, Vector3.new(x, 0.1, -0.55))
		eye.CanCollide = false
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = "Orman Yaratığı"
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

return World
