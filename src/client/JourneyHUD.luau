-- Recommendations and pins are local guidance, never actions or reward requests.
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Rules = require(Shared:WaitForChild("JourneyRules"))
local Theme = require(script.Parent:WaitForChild("UITheme"))
local Journey = {}
local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) <= 1000000
end
local function direction(dx, dz)
	local angle = math.atan2(dx, -dz)
	local index = math.floor(angle / (math.pi / 4) + 0.5) % 8 + 1
	return ({"K", "KD", "D", "GD", "G", "GB", "B", "KB"})[index]
end
function Journey.create(gui, questFrame, _remotes, make, label, colors, isBlocked)
	local self = {}
	local state, world, choices, pinned = {}, {}, {}, nil
	local disposed, mapView, selected = false, nil, nil
	local heading = label(questFrame, "YOLCULUĞUN", UDim2.fromOffset(14, 9), UDim2.new(1, -28, 0, 22), 13, colors.gold)
	heading.Font = Enum.Font.GothamBold
	local title = label(questFrame, "Yolculuğun hazırlanıyor…", UDim2.fromOffset(14, 34), UDim2.new(1, -28, 0, 20), 13, colors.text)
	title.Font, title.TextWrapped, title.TextTruncate = Enum.Font.GothamBold, false, Enum.TextTruncate.AtEnd
	local detail = label(questFrame, "", UDim2.fromOffset(14, 54), UDim2.new(1, -28, 0, 28), 11, colors.muted)
	detail.TextTruncate = Enum.TextTruncate.AtEnd
	local distanceText = label(questFrame, "", UDim2.fromOffset(14, 86), UDim2.new(1, -28, 0, 20), 11, colors.teal)
	distanceText.TextWrapped, distanceText.TextTruncate = false, Enum.TextTruncate.AtEnd
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "LocalJourneyGuide", workspace
	local function markerPart(name)
		local item = Instance.new("Part")
		item.Name, item.Size = name, Vector3.new(0.1, 0.1, 0.1)
		item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery, item.CastShadow = true, false, false, false, false
		item.Transparency, item.Parent = 1, folder
		return item
	end
	local anchor, ring = markerPart("GoalBeacon"), markerPart("GoalGroundPointer")
	ring.Shape, ring.Size, ring.Material, ring.Color = Enum.PartType.Cylinder, Vector3.new(0.08, 4, 4), Enum.Material.Neon, colors.gold
	local beacon = make("BillboardGui", {Name = "JourneyGoal", Adornee = anchor, Size = UDim2.fromOffset(140, 44), StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0), AlwaysOnTop = false, MaxDistance = 180, Enabled = false, Active = false}, anchor)
	local beaconText = label(beacon, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 12, colors.gold)
	beaconText.Font, beaconText.TextStrokeTransparency = Enum.Font.GothamBold, 0.35
	beaconText.TextXAlignment, beaconText.Active = Enum.TextXAlignment.Center, false
	local function hideMarker()
		beacon.Enabled, ring.Transparency = false, 1
	end
	local function blocked()
		return (isBlocked and isBlocked()) or GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() ~= nil
	end
	local function coordinates(option)
		return option ~= nil and finite(option.x) and finite(option.z)
	end
	local function selectedDistance(option, root)
		if not root or not coordinates(option) then return nil end
		local dx, dz = option.x - root.Position.X, option.z - root.Position.Z
		local distance = math.sqrt(dx * dx + dz * dz)
		if not finite(distance) then return nil end
		return distance, direction(dx, dz)
	end
	local function updateMap(root)
		if not mapView or not mapView.container.Parent then return end
		mapView.status.Text = pinned and "SABİT HEDEF • Tamamlandığında otomatik yenilenir" or "OTOMATİK • Güncel fırsatlara göre yenilenir"
		for index, card in ipairs(mapView.cards) do
			local option = choices[index]
			card.frame.Visible = option ~= nil
			if option then
				card.title.Text, card.detail.Text = option.title, option.detail
				local distance = selectedDistance(option, root)
				local suffix = distance and (" • " .. math.floor(distance + 0.5) .. " stud") or ""
				card.button.Text = (pinned == option.id and "OTOMATİĞE DÖN" or "HEDEFİ TAKİP ET") .. suffix
				card.button.BackgroundColor3 = pinned == option.id and Color3.fromRGB(91, 76, 44) or colors.button
			end
		end
		local height = 72 + #choices * 128
		mapView.container.Size = UDim2.new(1, -6, 0, height)
		local canvas = UDim2.new(mapView.original.X.Scale, mapView.original.X.Offset, 0, mapView.base + height + 12)
		if mapView.parent.CanvasSize ~= canvas then mapView.parent.CanvasSize = canvas end
		mapView.lastCanvas = canvas
	end
	local function update()
		if disposed then return end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and finite(root.Position.X) and finite(root.Position.Z) then
			choices = Rules.options(state, world, root.Position.X, root.Position.Z, Config, workspace:GetServerTimeNow(), pinned)
		else choices = {} end
		selected = nil
		if pinned then
			for _, option in ipairs(choices) do if option.id == pinned then selected = option; break end end
			if not selected and root then pinned = nil end
		end
		selected = selected or choices[1]
		title.Text = selected and selected.title or "Dünyayı keşfet"
		detail.Text = selected and selected.detail or "Haritadan yeni bir hedef seçebilirsin."
		local distance, bearing = selectedDistance(selected, root)
		distanceText.Text = distance and string.format("%d stud · %s yönü", math.floor(distance + 0.5), bearing) or (selected and selected.panel and (selected.panel .. " • Günlüğü aç") or "M • Dünya haritası")
		heading.Text = pinned and "◆  TAKİP ETTİĞİN HEDEF" or "◆  YOLCULUĞUN"
		local hidden = blocked()
		for _, text in ipairs({heading, title, detail, distanceText}) do text.Visible = not hidden end
		updateMap(root)
		hideMarker()
		if hidden or not selected or not distance or distance > 180 or not root or not humanoid or humanoid.Health <= 0 then return end
		local params = RaycastParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {character, folder}
		-- Offset avoids placing a floor pointer on an NPC's head or the chest lid.
		local hit = workspace:Raycast(Vector3.new(selected.x + 3, root.Position.Y + 80, selected.z + 3), Vector3.new(0, -240, 0), params)
		if not hit then return end
		if (root.Position - hit.Position).Magnitude > 180 then return end
		anchor.Position = hit.Position + Vector3.new(0, 0.3, 0)
		ring.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		beaconText.Text = selected.title .. "\n" .. math.floor(distance + 0.5) .. " stud"
		beacon.Enabled, ring.Transparency = true, 0.35
	end
	local function detachMap()
		if not mapView then return end
		if mapView.parent.Parent and mapView.parent.CanvasSize == mapView.lastCanvas then mapView.parent.CanvasSize = mapView.original end
		mapView.container:Destroy()
		mapView = nil
	end
	function self:attachMapPanel(parent)
		if disposed or (mapView and mapView.parent == parent) then return end
		detachMap()
		local original = parent.CanvasSize
		local base = math.max(1910, original.Y.Offset) + 16
		local container = make("Frame", {Name = "JourneyRecommendations", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, base), Size = UDim2.new(1, -6, 0, 72), Active = false}, parent)
		label(container, "SIRADAKİ ADIMIN", UDim2.fromOffset(0, 0), UDim2.new(1, -4, 0, 28), 15, colors.gold).Font = Enum.Font.GothamBold
		local status = label(container, "", UDim2.fromOffset(0, 30), UDim2.new(1, -4, 0, 36), 11, colors.muted)
		local cards = {}
		for index = 1, 6 do
			local item = make("Frame", {BackgroundColor3 = colors.panel, Position = UDim2.fromOffset(0, 72 + (index - 1) * 128), Size = UDim2.new(1, 0, 0, 120), BorderSizePixel = 0, Visible = false}, container)
			make("UICorner", {CornerRadius = UDim.new(0, 10)}, item)
			Theme.panel(item)
			local itemTitle = label(item, "", UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 23), 13, colors.gold)
			itemTitle.TextWrapped, itemTitle.TextTruncate = false, Enum.TextTruncate.AtEnd
			local itemDetail = label(item, "", UDim2.fromOffset(10, 29), UDim2.new(1, -20, 0, 32), 11, colors.muted)
			itemDetail.TextTruncate = Enum.TextTruncate.AtEnd
			local button = make("TextButton", {Text = "HEDEFİ TAKİP ET", Position = UDim2.fromOffset(10, 68), Size = UDim2.new(1, -20, 0, 44), BackgroundColor3 = colors.button, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = colors.text, TextWrapped = true, BorderSizePixel = 0, Selectable = true}, item)
			make("UICorner", {CornerRadius = UDim.new(0, 8)}, button)
			Theme.button(button)
			button.Activated:Connect(function()
				local option = choices[index]
				if option then
					if pinned == option.id then pinned = nil else pinned = option.id end
					update()
				end
			end)
			cards[index] = {frame = item, title = itemTitle, detail = itemDetail, button = button}
		end
		for _, object in ipairs(container:GetDescendants()) do if object:IsA("GuiObject") then object.ZIndex = 7 end end
		container.ZIndex = 7
		mapView = {parent = parent, container = container, cards = cards, status = status, original = original, base = base}
		update()
	end
	function self:setState(value) if not disposed and type(value) == "table" then state = value; update() end end
	function self:setWorld(value) if not disposed and type(value) == "table" then world = value; update() end end
	function self:resize(_viewport) if not disposed then update() end end
	local destroyConnection, ancestryConnection, removingConnection
	function self:destroy()
		if disposed then return end
		disposed = true
		for _, connection in ipairs({destroyConnection, ancestryConnection, removingConnection}) do if connection then connection:Disconnect() end end
		detachMap()
		folder:Destroy()
		for _, text in ipairs({heading, title, detail, distanceText}) do text:Destroy() end
		state, world, choices, selected = nil, nil, {}, nil
	end
	destroyConnection = gui.Destroying:Connect(function() self:destroy() end)
	ancestryConnection = gui.AncestryChanged:Connect(function() if not gui.Parent then self:destroy() end end)
	removingConnection = Players.LocalPlayer.CharacterRemoving:Connect(hideMarker)
	task.spawn(function()
		while not disposed and gui.Parent do update(); task.wait(0.5) end
		self:destroy()
	end)
	return self
end
return Journey
