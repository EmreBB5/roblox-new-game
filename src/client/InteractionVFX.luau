-- Native prompts remain authoritative. Local floor runes only identify usable objects.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PromptService = game:GetService("ProximityPromptService")
local VFX = {}
local sessions = setmetatable({}, {__mode = "k"})
local colors = {
	QuestPrompt = Color3.fromRGB(246, 214, 139), ForgePrompt = Color3.fromRGB(255, 177, 119),
	GatherPrompt = Color3.fromRGB(142, 228, 172), DiscoverWaypoint = Color3.fromRGB(120, 228, 235),
	RegionalContractPrompt = Color3.fromRGB(246, 214, 139), DiscoverExplorationSite = Color3.fromRGB(180, 169, 255),
	OpenExplorationChest = Color3.fromRGB(246, 214, 139),
}
function VFX.start(gui, isBlocked)
	if sessions[gui] then sessions[gui]:destroy() end
	local self = {}
	local disposed, world, elapsed = false, nil, 0
	local connections, worldConnections, records, drawings = {}, {}, {}, {}
	local profile = {discovered = {}, claimed = {}}
	local revision = 0
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "LocalInteractionRunes", workspace
	local function removeDrawing(prompt)
		local drawing = drawings[prompt]
		if not drawing then return end
		drawing:Destroy()
		drawings[prompt] = nil
	end
	local function availability(record)
		local prompt = record.prompt
		if not prompt.Parent then return end
		local completed = (prompt.Name == "DiscoverExplorationSite" and profile.discovered[record.id] == true)
			or (prompt.Name == "OpenExplorationChest" and profile.claimed[record.id] == true)
		if record.id then prompt.Enabled = record.enabled and not completed end
	end
	local function track(item)
		if not item:IsA("ProximityPrompt") or not colors[item.Name] or records[item] then return end
		local model = item:FindFirstAncestorOfClass("Model")
		local id = model and model:GetAttribute("ExplorationSiteId")
		records[item] = {prompt = item, id = id, enabled = item.Enabled, shown = false}
		availability(records[item])
	end
	local function removeRecord(item)
		local record = records[item]
		if record and item.Parent then item.Enabled = record.enabled end
		records[item] = nil
		removeDrawing(item)
	end
	local function releaseWorld()
		for _, connection in ipairs(worldConnections) do connection:Disconnect() end
		table.clear(worldConnections)
		for prompt in pairs(records) do removeRecord(prompt) end
	end
	local function bindWorld(current)
		releaseWorld()
		world = current
		if not world then return end
		for _, item in ipairs(world:GetDescendants()) do track(item) end
		table.insert(worldConnections, world.DescendantAdded:Connect(track))
		table.insert(worldConnections, world.DescendantRemoving:Connect(removeRecord))
	end
	function self:setState(state)
		if disposed or type(state) ~= "table" then return end
		local incoming = state.feedbackRevision
		if incoming ~= nil then
			if type(incoming) ~= "number" or incoming ~= incoming or incoming % 1 ~= 0
				or incoming < 1 or incoming > 1000000000000 or incoming <= revision then return end
			revision = incoming
		elseif revision > 0 then return end
		local data = type(state.exploration) == "table" and state.exploration or {}
		profile = {discovered = type(data.discovered) == "table" and table.clone(data.discovered) or {}, claimed = type(data.claimed) == "table" and table.clone(data.claimed) or {}}
		for _, record in pairs(records) do availability(record) end
	end
	function self:destroy()
		if disposed then return end
		disposed = true
		for _, connection in ipairs(connections) do connection:Disconnect() end
		releaseWorld()
		folder:Destroy()
		sessions[gui] = nil
	end
	sessions[gui] = self
	table.insert(connections, PromptService.PromptShown:Connect(function(prompt)
		if not world or not prompt:IsDescendantOf(world) then return end
		track(prompt)
		if records[prompt] then records[prompt].shown = prompt.Enabled end
	end))
	table.insert(connections, PromptService.PromptHidden:Connect(function(prompt)
		if records[prompt] then records[prompt].shown = false end
		removeDrawing(prompt)
	end))
	table.insert(connections, gui.Destroying:Connect(function() self:destroy() end))
	table.insert(connections, gui.AncestryChanged:Connect(function() if not gui.Parent then self:destroy() end end))
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		if disposed then return end
		elapsed += dt
		if elapsed < 0.1 then return end
		elapsed %= 0.1
		local current = workspace:FindFirstChild("AetheriaWorld")
		if current ~= world then bindWorld(current) end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local blocked = isBlocked() or not root or not humanoid or humanoid.Health <= 0
		local candidates = {}
		if not blocked then
			for prompt, record in pairs(records) do
				local adornee = prompt.Parent
				if record.shown and prompt.Enabled and adornee and adornee:IsA("BasePart") and adornee:IsDescendantOf(workspace) then
					local distance = (adornee.Position - root.Position).Magnitude
					if distance <= math.min(16, prompt.MaxActivationDistance + 2) then table.insert(candidates, {prompt = prompt, position = adornee.Position, distance = distance}) end
				end
			end
		end
		table.sort(candidates, function(a, b) return a.distance < b.distance end)
		local keep = {}
		for index = 1, math.min(2, #candidates) do keep[candidates[index].prompt] = true end
		for prompt in pairs(drawings) do if not keep[prompt] then removeDrawing(prompt) end end
		for index = 1, math.min(2, #candidates) do
			local candidate = candidates[index]
			local prompt, position = candidate.prompt, candidate.position
			local drawing = drawings[prompt]
			if not drawing then
				drawing = Instance.new("Model")
				drawing.Name, drawing.Parent = "InteractionRune", folder
				for segment = 1, 8 do
					local item = Instance.new("Part")
					item.Name, item.Size = "RuneSegment", Vector3.new(0.12, 0.08, 0.8)
					item.Material, item.Color = Enum.Material.Neon, colors[prompt.Name]
					item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch, item.CastShadow = true, false, false, false, false
					item.Parent = drawing
				end
				drawings[prompt] = drawing
			end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			local filters = {character, folder, prompt.Parent}
			local source = prompt:FindFirstAncestorOfClass("Model")
			if source and (source.Name == "Eldrin" or source.Name == "Borin" or prompt.Name == "GatherPrompt") then
				table.insert(filters, source)
			elseif source and prompt.Name == "OpenExplorationChest" then
				local body = source:FindFirstChild("ChestBody")
				if body then table.insert(filters, body) end
			end
			params.FilterDescendantsInstances = filters
			local ground = workspace:Raycast(Vector3.new(position.X, root.Position.Y + 1, position.Z), Vector3.new(0, -12, 0), params)
			local y = ground and ground.Position.Y + 0.1 or root.Position.Y - 2.8
			local time = os.clock()
			local radius = 1.9 + math.sin(time * 2) * 0.08
			for segment, item in ipairs(drawing:GetChildren()) do
				local angle = segment * math.pi / 4
				item.CFrame = CFrame.new(position.X + math.cos(angle) * radius, y, position.Z + math.sin(angle) * radius) * CFrame.Angles(0, -angle, 0)
				item.Transparency = 0.35 + math.sin(time * 2) * 0.08
			end
		end
	end))
	return self
end
return VFX
