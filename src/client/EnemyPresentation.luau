-- Local nameplates only. Replicated Humanoid state remains authoritative.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Theme = require(script.Parent:WaitForChild("UITheme"))
local Presentation = {}
local sessions = setmetatable({}, {__mode = "k"})
local LIMIT, STEP = 12, 1 / 10
local RANGE = {normal = 55, elite = 100, boss = 150}
local EDGE = {normal = Theme.colors.muted, elite = Theme.colors.teal, boss = Theme.colors.gold}
local RED = Color3.fromRGB(244, 112, 113)
local function frame(parent, name, color, position, size)
	local item = Instance.new("Frame")
	item.Name, item.BackgroundColor3 = name, color
	item.BorderSizePixel, item.Active = 0, false
	item.Position, item.Size, item.Parent = position, size, parent
	return item
end
local function text(parent, name, size, color, position, dimensions)
	local item = Instance.new("TextLabel")
	item.Name, item.BackgroundTransparency, item.Active = name, 1, false
	item.Font, item.TextSize, item.TextColor3 = Enum.Font.GothamMedium, size, color
	item.TextXAlignment, item.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
	item.TextTruncate = Enum.TextTruncate.AtEnd
	item.Position, item.Size, item.Parent = position, dimensions, parent
	return item
end
function Presentation.start(gui)
	if sessions[gui] then sessions[gui]() end
	local active, accumulator, nextScan = true, 0, 0
	local tracked, connections = {}, {}
	local function remove(model)
		local state = tracked[model]
		if not state then return end
		if state.humanoid.Parent then
			state.humanoid.HealthDisplayDistance = state.healthDistance
			state.humanoid.NameDisplayDistance = state.nameDistance
		end
		state.board:Destroy()
		tracked[model] = nil
	end
	local function stop()
		if not active then return end
		active = false
		for _, connection in connections do connection:Disconnect() end
		table.clear(connections)
		for model in tracked do remove(model) end
		sessions[gui] = nil
	end
	sessions[gui] = stop
	local function create(entry)
		local kind, model, humanoid = entry.kind, entry.model, entry.humanoid
		local board = Instance.new("BillboardGui")
		board.Name = "LocalEnemyPlate"
		board.Adornee = model:FindFirstChild("Head") or entry.root
		board.AlwaysOnTop, board.Active, board.LightInfluence = false, false, 0
		board.ResetOnSpawn = false
		board.MaxDistance = RANGE[kind]
		board.Size = UDim2.fromOffset(if kind == "boss" then 194 else 170, 54)
		local head = board.Adornee
		board.StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y / 2 + 1.7, 0)
		local plate = frame(board, "Plate", Theme.colors.panel, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
		plate.BackgroundTransparency = 0.2
		local corner = Instance.new("UICorner")
		corner.CornerRadius, corner.Parent = UDim.new(0, 6), plate
		local edge = Instance.new("UIStroke")
		edge.Color, edge.Thickness, edge.Transparency = EDGE[kind], if kind == "normal" then 1 else 1.5, 0.3
		edge.ApplyStrokeMode, edge.Parent = Enum.ApplyStrokeMode.Border, plate
		local name = text(plate, "EnemyName", 12, Theme.colors.text, UDim2.fromOffset(8, 3), UDim2.new(1, -16, 0, 17))
		name.Text = if humanoid.DisplayName ~= "" then humanoid.DisplayName else model.Name
		local role = text(plate, "EnemyRole", 10, EDGE[kind], UDim2.fromOffset(8, 19), UDim2.new(1, -16, 0, 14))
		local region = Config.Regions[model:GetAttribute("RegionId")]
		local behavior = model:GetAttribute("EnemyBehavior")
		local caption = if kind == "boss" then "DÜNYA BOSSU" elseif kind == "elite" then "ELİT"
			elseif behavior == "targeted" then "MENZİLLİ" elseif behavior == "area" then "ALAN SALDIRISI" else "YAKIN DÖVÜŞ"
		role.Text = "Sv. " .. tostring(if region then region.EnemyLevel else 1) .. "  ·  " .. caption
		local back = frame(plate, "HealthTrack", Color3.fromRGB(29, 47, 62), UDim2.fromOffset(8, 37), UDim2.new(1, -16, 0, 7))
		local trail = frame(back, "DamageTrail", Theme.colors.gold, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
		local fill = frame(back, "HealthFill", Theme.colors.health, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
		local state = {board = board, humanoid = humanoid, root = entry.root, kind = kind,
			healthDistance = humanoid.HealthDisplayDistance, nameDistance = humanoid.NameDisplayDistance,
			plate = plate, edge = edge, name = name, role = role, back = back, trail = trail, fill = fill,
			ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1), trailRatio = 1, trailAt = 0}
		state.trailRatio = state.ratio
		tracked[model] = state
		-- Put the overlay directly under PlayerGui; its lifetime belongs to gui.
		board.Parent = gui.Parent
		humanoid.HealthDisplayDistance, humanoid.NameDisplayDistance = 0, 0
	end
	local function rescan(position)
		local world = workspace:FindFirstChild("AetheriaWorld")
		local folder = world and world:FindFirstChild("Enemies")
		local candidates = {}
		if folder then
			for _, model in folder:GetChildren() do
				local kind = model:GetAttribute("EnemyKind")
				if not model:IsA("Model") or model:GetAttribute("AetheriaEnemy") ~= true or not RANGE[kind] then continue end
				local root, humanoid = model:FindFirstChild("HumanoidRootPart"), model:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 then
					local distance = (root.Position - position).Magnitude
					if distance <= RANGE[kind] then table.insert(candidates, {model = model, root = root, humanoid = humanoid, kind = kind, distance = distance}) end
				end
			end
		end
		table.sort(candidates, function(a, b) return a.distance < b.distance end)
		local keep = {}
		for index = 1, math.min(LIMIT, #candidates) do keep[candidates[index].model] = true end
		-- Release old overlays before allocating replacements, keeping the cap
		-- at twelve even during a complete nearest-target turnover.
		for model in tracked do if not keep[model] then remove(model) end end
		for index = 1, math.min(LIMIT, #candidates) do
			local entry = candidates[index]
			local previous = tracked[entry.model]
			if previous and (not previous.board.Parent or previous.root ~= entry.root or previous.humanoid ~= entry.humanoid or previous.kind ~= entry.kind) then remove(entry.model) end
			if not tracked[entry.model] then create(entry) end
		end
		for model in tracked do if not keep[model] then remove(model) end end
	end
	table.insert(connections, gui.Destroying:Connect(stop))
	table.insert(connections, gui.AncestryChanged:Connect(function() if not gui.Parent then stop() end end))
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		if not active then return end
		accumulator += dt
		if accumulator < STEP then return end
		local elapsed = math.min(accumulator, 0.25)
		accumulator %= STEP
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then for model in tracked do remove(model) end; return end
		local time = os.clock()
		if time >= nextScan then rescan(root.Position); nextScan = time + 0.75 end
		for model, state in tracked do
			local humanoid = state.humanoid
			local distance = if state.root.Parent then (state.root.Position - root.Position).Magnitude else math.huge
			if not state.board.Parent or not model:IsDescendantOf(workspace) or not humanoid.Parent or humanoid.Health <= 0
				or not state.root.Parent or distance > RANGE[state.kind] then remove(model); continue end
			local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
			if ratio < state.ratio then state.trailAt = time + 0.45 end
			if ratio > state.trailRatio then state.trailRatio = ratio end
			if time >= state.trailAt then state.trailRatio += (ratio - state.trailRatio) * math.min(1, elapsed * 5) end
			state.ratio = ratio
			state.fill.Size = UDim2.fromScale(ratio, 1)
			state.trail.Size = UDim2.fromScale(math.max(ratio, state.trailRatio), 1)
			local low = ratio <= 0.25
			state.fill.BackgroundColor3 = if low then RED else Theme.colors.health
			state.edge.Color = if low and state.kind == "normal" then RED else EDGE[state.kind]
			state.role.TextColor3 = if low then RED else EDGE[state.kind]
			-- A short edge fade avoids a sharp distant pop while remaining legible.
			local fade = math.clamp((distance / RANGE[state.kind] - 0.8) / 0.2, 0, 1) * 0.55
			state.plate.BackgroundTransparency = 0.2 + fade * 0.6
			state.edge.Transparency = 0.3 + fade
			state.name.TextTransparency, state.role.TextTransparency = fade, fade
			state.back.BackgroundTransparency = fade
			state.fill.BackgroundTransparency, state.trail.BackgroundTransparency = fade, 0.2 + fade
		end
	end))
	return stop
end
return Presentation
