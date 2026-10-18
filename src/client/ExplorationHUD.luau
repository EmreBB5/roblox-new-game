-- Permanent personal discoveries, with shared guards; all claims are server-owned.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local ExplorationHUD = {}
function ExplorationHUD.create(gui, parent, map, remotes, make, label, button, colors, mapPosition)
	local self = {state = {}, sites = {}}
	local order = {"forest_ruins", "marsh_outpost", "volcanic_archive", "frost_watch", "desert_caravan"}
	local materialNames = {wood = "odun", iron = "demir", ember = "köz"}
	local request = remotes:WaitForChild("RequestExploration")
	label(parent, "KEŞİF GÜNLÜĞÜ", UDim2.fromOffset(2, 684), UDim2.new(1, -12, 0, 28), 15, colors.gold)
	local progress = label(parent, "", UDim2.fromOffset(2, 716), UDim2.new(1, -12, 0, 24), 12, colors.gold)
	label(parent, "İşaretlere yürü → E ile keşfet → 2 muhafızı yen → sandığı aç.\nKeşif ve sandık ödülleri kalıcıdır; sandık kişi başına yalnızca bir kez açılır.\nSandık için 5 sn savaş dışında kal. Pet veya pet XP'si düşmez.", UDim2.fromOffset(2, 746), UDim2.new(1, -12, 0, 78), 11, colors.muted)
	local cards = {}
	local chestViews = setmetatable({}, {__mode = "k"})
	local active = true
	local function cleared(id)
		-- Guard death/respawn broadcasts arrive before the periodic profile snapshot.
		if self.sites[id] then return self.sites[id].clear == true end
		local ready = (self.state.explorationReady or {})[id]
		if type(ready) == "boolean" then return ready end
		return false
	end
	local function chestVisuals(claimed)
		for model in pairs(chestViews) do
			if not model:IsDescendantOf(workspace) then chestViews[model] = nil end
		end
		local world = workspace:FindFirstChild("AetheriaWorld")
		local folder = world and world:FindFirstChild("ExplorationSites")
		if not folder then return end
		for _, model in ipairs(folder:GetChildren()) do
			local id = model:GetAttribute("ExplorationSiteId")
			local closed = model:GetAttribute("ChestClosedCFrame")
			local lid = model:FindFirstChild("ChestLid")
			if Config.ExplorationSites[id] and typeof(closed) == "CFrame" and lid and lid:IsA("BasePart") then
				local opened = claimed[id] == true
				local previous = chestViews[model]
				if not previous or previous.lid ~= lid or previous.opened ~= opened or previous.closed ~= closed then
					-- These anchored-part changes are local cosmetics, never a claim request.
					local half = lid.Size.Z / 2
					lid.CFrame = opened and closed * CFrame.new(0, 0, -half) * CFrame.Angles(math.rad(-72), 0, 0) * CFrame.new(0, 0, half) or closed
					for _, child in ipairs(model:GetChildren()) do
						if child.Name == "TreasureGold" and child:IsA("BasePart") then child.LocalTransparencyModifier = opened and 1 or 0 end
					end
					chestViews[model] = {lid = lid, closed = closed, opened = opened}
				end
			end
		end
	end
	gui.Destroying:Connect(function()
		active = false
		for model, view in pairs(chestViews) do
			if view.lid.Parent then view.lid.CFrame = view.closed end
			for _, child in ipairs(model:GetChildren()) do
				if child.Name == "TreasureGold" and child:IsA("BasePart") then child.LocalTransparencyModifier = 0 end
			end
		end
		table.clear(chestViews)
	end)
	local function nearby(id, attribute)
		local world = workspace:FindFirstChild("AetheriaWorld")
		local folder = world and world:FindFirstChild("ExplorationSites")
		if not folder then return false end
		local position
		for _, model in ipairs(folder:GetChildren()) do
			if model:GetAttribute("ExplorationSiteId") == id then position = model:GetAttribute(attribute); break end
		end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if typeof(position) ~= "Vector3" or not root or not humanoid or humanoid.Health <= 0 then return false end
		local distance = (root.Position - position).Magnitude
		return distance == distance and distance <= 14
	end
	for index, id in ipairs(order) do
		local definition = Config.ExplorationSites[id]
		local y = 832 + (index - 1) * 216
		local card = make("Frame", {Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, -6, 0, 206), BackgroundColor3 = Color3.fromRGB(25, 43, 37), BorderSizePixel = 0}, parent)
		make("UICorner", {CornerRadius = UDim.new(0, 10)}, card)
		local name = label(card, "", UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 24), 14, colors.gold)
		local detail = label(card, "", UDim2.fromOffset(10, 32), UDim2.new(1, -20, 0, 68), 12)
		label(card, string.format("Tek seferlik ödül: %d XP • %d altın\n%d %s • Pet ödülü yok", definition.XP, definition.Gold, definition.MaterialAmount, materialNames[definition.RewardMaterial]), UDim2.fromOffset(10, 104), UDim2.new(1, -20, 0, 44), 11, colors.muted)
		local action = button(card, "KEŞİF NOKTASINA YAKLAŞ", UDim2.fromOffset(10, 154), UDim2.new(1, -20, 0, 44), function()
			local state = self.state.exploration or {}
			if (state.claimed or {})[id] then return end
			if not (state.discovered or {})[id] then
				if nearby(id, "DiscoveryPosition") then request:FireServer("discover", id) end
			else
				if cleared(id) and nearby(id, "ChestPosition") then request:FireServer("claim", id) end
			end
		end)
		local marker = label(map, "?", mapPosition(definition.X, definition.Z), UDim2.fromOffset(18, 20), 16, colors.muted)
		marker.AnchorPoint, marker.TextXAlignment = Vector2.new(0.5, 0.5), Enum.TextXAlignment.Center
		cards[id] = {name = name, detail = detail, action = action, marker = marker, y = y}
	end
	parent.CanvasSize = UDim2.fromOffset(0, 1910)
	function self:setState(state) self.state = state end
	function self:setWorld(world)
		self.sites = {}
		for _, site in ipairs(world.sites or {}) do self.sites[site.id] = site end
	end
	function self:focus(id)
		local card = cards[id]
		if not card then return end
		parent.CanvasPosition = Vector2.new(0, card.y)
		if UserInputService.GamepadEnabled and card.action.Selectable then GuiService.SelectedObject = card.action end
	end
	task.spawn(function()
		while active and gui.Parent do
			local exploration = self.state.exploration or {}
			chestVisuals(exploration.claimed or {})
			local knownCount, claimedCount = 0, 0
			for id, card in pairs(cards) do
				local definition = Config.ExplorationSites[id]
				local known = (exploration.discovered or {})[id] == true
				local claimed = (exploration.claimed or {})[id] == true
				local site = self.sites[id]
				local clear = cleared(id)
				if known then knownCount += 1 end
				if claimed then claimedCount += 1 end
				card.name.Text = known and definition.Name or (Config.Regions[definition.RegionId].Name .. " • ?")
				card.marker.Text = known and "▣" or "?"
				card.marker.TextColor3 = known and not claimed and clear and colors.gold or colors.muted
				local guards = site and string.format("Muhafızlar: %d / %d hayatta", site.guardsAlive, site.guardCount) or "Muhafız bilgisi bekleniyor…"
				card.detail.Text = (known and "Keşfedildi ✓" or "Henüz keşfedilmedi") .. "\n" .. guards .. "\n" .. (claimed and "Sandık açıldı • Kalıcı olarak tamamlandı" or (clear and "Muhafızlar temizlendi • Sandık hazır" or "Önce muhafızları yen"))
				local near = nearby(id, known and "ChestPosition" or "DiscoveryPosition")
				local enabled = not claimed and near and (not known or clear)
				card.action.Text = claimed and "ÖDÜL ALINDI" or (not near and (known and "SANDIĞA YAKLAŞ" or "KEŞİF NOKTASINA YAKLAŞ") or (not known and "KEŞFET" or (clear and "SANDIĞI AÇ" or "MUHAFIZLARI YEN")))
				card.action.Selectable, card.action.AutoButtonColor = enabled, enabled
				card.action.BackgroundColor3 = enabled and Color3.fromRGB(46, 85, 69) or Color3.fromRGB(38, 47, 47)
			end
			progress.Text = string.format("Keşfedilen %d / %d • Açılan sandık %d / %d", knownCount, #order, claimedCount, #order)
			task.wait(0.25)
		end
	end)
	return self
end
return ExplorationHUD
