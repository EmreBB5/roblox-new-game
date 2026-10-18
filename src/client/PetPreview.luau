-- Native, asset-free collectible portraits. Static scenes avoid render-loop cost.
local Preview = {}
local palette = {mossling = Color3.fromRGB(123, 231, 163), tidefin = Color3.fromRGB(99, 210, 249), embercub = Color3.fromRGB(253, 159, 102)}
function Preview.create(parent, id)
	local view = Instance.new("ViewportFrame")
	view.Name = "CompanionPortrait"
	view.Position, view.Size = UDim2.fromOffset(10, 32), UDim2.fromOffset(80, 78)
	view.BackgroundColor3 = Color3.fromRGB(12, 27, 46)
	view.BackgroundTransparency, view.BorderSizePixel = 0.15, 0
	view.Ambient, view.LightColor = Color3.fromRGB(145, 181, 209), Color3.fromRGB(255, 234, 200)
	view.LightDirection = Vector3.new(-1, -1, -2)
	view.Active = false
	view.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 12), view
	local world = Instance.new("WorldModel")
	world.Parent = view
	local model = Instance.new("Model")
	model.Name, model.Parent = id, world
	local paint = {}
	local color = palette[id]
	local function part(name, size, position, tint, shape, angle)
		local item = Instance.new("Part")
		item.Name, item.Size = name, size
		item.Shape = shape or Enum.PartType.Ball
		item.Material = Enum.Material.SmoothPlastic
		item.Color = tint
		item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
		item.CFrame = CFrame.new(position) * (angle or CFrame.identity)
		item.Parent = model
		paint[item] = tint
		return item
	end
	part("Body", Vector3.new(1.2, 1.35, 1.1), Vector3.zero, color)
	for _, side in ipairs({-1, 1}) do
		part("Eye", Vector3.new(0.24, 0.28, 0.12), Vector3.new(side * 0.24, 0.2, -0.5), Color3.fromRGB(250, 255, 255))
		part("Pupil", Vector3.new(0.11, 0.17, 0.08), Vector3.new(side * 0.24, 0.2, -0.57), Color3.fromRGB(18, 36, 53))
		if id == "mossling" then
			part("Leaf", Vector3.new(0.5, 1.25, 0.55), Vector3.new(side * 0.67, 0.6, 0), color:Lerp(Color3.fromRGB(231, 243, 126), 0.35), nil, CFrame.Angles(0, 0, math.rad(-side * 40)))
			part("Sprout", Vector3.new(0.25, 0.65, 0.3), Vector3.new(side * 0.2, 1, 0), color)
		elseif id == "tidefin" then
			for feather = 1, 3 do
				part("Fin", Vector3.new(1.25, 0.16, 0.36), Vector3.new(side * 1.02, 0.45 - feather * 0.2, feather * 0.22), color:Lerp(Color3.new(1, 1, 1), feather * 0.13), nil, CFrame.Angles(0, math.rad(side * 15), math.rad(side * (10 + feather * 8))))
			end
		else
			part("Horn", Vector3.new(0.25, 0.8, 0.25), Vector3.new(side * 0.42, 0.93, 0), Color3.fromRGB(255, 223, 142), Enum.PartType.Block, CFrame.Angles(0, 0, math.rad(-side * 20)))
			for _, z in ipairs({-0.35, 0.35}) do part("Paw", Vector3.new(0.43, 0.42, 0.5), Vector3.new(side * 0.48, -0.5, z), color) end
		end
	end
	for index = 1, 10 do
		local angle = index * math.pi / 5
		part("Rune", Vector3.new(0.1, 0.08, 0.3), Vector3.new(math.cos(angle) * 1.18, -0.85, math.sin(angle) * 1.18), Color3.fromRGB(230, 196, 124), Enum.PartType.Block, CFrame.Angles(0, -angle, 0))
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = CFrame.lookAt(Vector3.new(3, 2, -5.5), Vector3.new(0, 0.2, 0))
	camera.Parent, view.CurrentCamera = view, camera
	local self = {}
	local lastOwned, lastLevel, alive = nil, nil, true
	view.Destroying:Connect(function() alive = false; table.clear(paint) end)
	function self:setState(owned, level)
		if not alive or (owned == lastOwned and level == lastLevel) then return end
		lastOwned, lastLevel = owned, level
		for item, tint in pairs(paint) do item.Color = owned and tint or tint:Lerp(Color3.fromRGB(62, 80, 103), 0.78) end
		view.ImageColor3 = owned and Color3.new(1, 1, 1) or Color3.fromRGB(161, 179, 201)
		model:ScaleTo(1 + math.clamp((level or 1) - 1, 0, 9) * 0.012)
	end
	self:setState(false, 1)
	return self
end
return Preview
