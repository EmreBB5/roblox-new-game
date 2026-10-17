local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local WorldMap = require(game:GetService("ReplicatedStorage").Shared:WaitForChild("WorldMap"))
local WorldHUD = {}

function WorldHUD.create(gui, remotes, make, label, colors)
	local self = {open = false, state = {}, world = {bosses = {}}}
	local function frame(parent, size, position, anchor)
		local item = make("Frame", {Size = size, Position = position, AnchorPoint = anchor or Vector2.zero, BackgroundColor3 = colors.panel, BackgroundTransparency = 0.06, BorderSizePixel = 0, Active = true}, parent)
		make("UICorner", {CornerRadius = UDim.new(0, 12)}, item)
		make("UIStroke", {Color = colors.gold, Transparency = 0.65}, item)
		return item
	end
	local function button(parent, text, position, size, callback)
		local item = make("TextButton", {Text = text, Position = position, Size = size, BackgroundColor3 = Color3.fromRGB(46, 70, 59), TextColor3 = colors.text, Font = Enum.Font.GothamBold, TextSize = 13, TextWrapped = true, BorderSizePixel = 0, Selectable = true}, parent)
		make("UICorner", {CornerRadius = UDim.new(0, 8)}, item)
		item.Activated:Connect(callback)
		return item
	end
	local events = frame(gui, UDim2.fromOffset(290, 188), UDim2.new(1, -12, 0, 12), Vector2.new(1, 0))
	label(events, "DÜNYA MUHAFIZLARI", UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 20), 14, colors.gold)
	local clock = label(events, "İstanbul • Sunucu saati bekleniyor", UDim2.fromOffset(12, 29), UDim2.new(1, -24, 0, 17), 10, colors.muted)
	local eventLabels, order = {}, Config.BossOrder
	for index, id in ipairs(order) do
		eventLabels[id] = label(events, Config.Bosses[id].Name .. "\nSaat bekleniyor…", UDim2.fromOffset(12, 51 + (index - 1) * 43), UDim2.new(1, -24, 0, 40), 12)
	end
	local eventScale = make("UIScale", {Scale = 1}, events)
	local menu = frame(gui, UDim2.fromOffset(224, 102), UDim2.new(1, -12, 0, 210), Vector2.new(1, 0))
	local overlay = make("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3, Visible = false, Active = true, ZIndex = 5}, gui)
	local content = frame(overlay, UDim2.fromOffset(540, 560), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	content.ZIndex = 6
	local title = label(content, "", UDim2.fromOffset(16, 8), UDim2.new(1, -108, 0, 44), 18, colors.gold)
	local function body()
		return make("ScrollingFrame", {Position = UDim2.fromOffset(16, 64), Size = UDim2.new(1, -32, 1, -76), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, 380), ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 4, Active = true, Visible = false}, content)
	end
	local collection, characterPanel, mapPanel, partyPanel = body(), body(), body(), body()
	local map = make("Frame", {BackgroundColor3 = Color3.fromRGB(26, 46, 40), BorderSizePixel = 0, Size = UDim2.new(1, -6, 0, 220), Position = UDim2.fromOffset(0, 0), ClipsDescendants = true}, mapPanel)
	make("UICorner", {CornerRadius = UDim.new(0, 10)}, map)
	local mapHint = label(mapPanel, "", UDim2.fromOffset(2, 414), UDim2.new(1, -12, 0, 64), 12, colors.muted)
	mapPanel.CanvasSize = UDim2.fromOffset(0, 488)
	local selectedMenu, previousSelection, closeButton = "pets", nil, nil
	local function show(mode, force)
		local wasOpen = self.open
		local visible = force == true or not (self.open and selectedMenu == mode)
		selectedMenu, self.open = mode, visible
		overlay.Visible = visible
		collection.Visible, characterPanel.Visible = mode == "pets", mode == "character"
		mapPanel.Visible, partyPanel.Visible = mode == "map", mode == "party"
		title.Text = ({pets = "YOL ARKADAŞLARIN", character = "KAHRAMANIN", map = "DÜNYA HARİTASI", party = "MACERA GRUBU"})[mode] or "AETHERIA"
		if visible then
			if not wasOpen then previousSelection = GuiService.SelectedObject end
			if UserInputService.GamepadEnabled then GuiService.SelectedObject = closeButton end
		elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(content) then
			GuiService.SelectedObject = previousSelection and previousSelection.Parent and previousSelection or nil
		end
	end
	closeButton = button(content, "KAPAT", UDim2.new(1, -88, 0, 8), UDim2.fromOffset(72, 44), function() show(selectedMenu) end)
	local modes, captions = {"pets", "map", "character", "party"}, {"PET", "HARİTA", "KARAKTER", "GRUP"}
	local menuButtons, invitePending = {}, false
	for index, mode in ipairs(modes) do
		menuButtons[index] = button(menu, captions[index], UDim2.fromOffset(5, 5), UDim2.fromOffset(104, 44), function() show(mode) end)
	end
	local characterHUD = require(script.Parent:WaitForChild("CharacterHUD")).create(gui, characterPanel, remotes, make, label, button, colors, function() return self.open end)
	require(script.Parent:WaitForChild("PartyHUD")).create(gui, partyPanel, remotes, make, label, button, colors, function(pending)
		invitePending = pending
		menuButtons[4].Text = pending and "GRUP !" or "GRUP"
		menuButtons[4].BackgroundColor3 = pending and Color3.fromRGB(114, 91, 44) or Color3.fromRGB(46, 70, 59)
	end)
	local cards = {}
	for index, bossId in ipairs(order) do
		local boss, petId = Config.Bosses[bossId], Config.Bosses[bossId].PetId
		local card = frame(collection, UDim2.new(1, -6, 0, 104), UDim2.fromOffset(0, (index - 1) * 112))
		label(card, Config.Pets[petId].Name, UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 24), 15, colors.gold)
		local detail = label(card, "", UDim2.fromOffset(10, 30), UDim2.new(1, -112, 0, 68), 11, colors.muted)
		local equip = button(card, "KİLİTLİ", UDim2.new(1, -96, 0, 42), UDim2.fromOffset(86, 44), function()
			if not (self.state.pets or {})[petId] then return end
			remotes:WaitForChild("EquipPet"):FireServer(self.state.equippedPet == petId and "" or petId)
		end)
		cards[petId] = {detail = detail, equip = equip, bossId = bossId}
	end
	local dropPercent = math.floor(Config.PetDropChance * 100 + 0.5)
	label(collection, string.format("Uygun zaferde %%%d şans • %d. denemede garanti\nKatılım: en az %d isabet ve boss canının %%%d'i kadar hasar.\nAynı anda yalnızca bir pet takılır.", dropPercent, Config.PetPityLimit, Config.BossMinAcceptedHits, math.floor(Config.BossMinDamageFraction * 100 + 0.5)), UDim2.fromOffset(4, 338), UDim2.new(1, -12, 0, 92), 12, colors.muted)
	collection.CanvasSize = UDim2.fromOffset(0, 438)
	local function mapPosition(x, z)
		local u, v = WorldMap.normalized(x, z, Config)
		return UDim2.fromScale(u or 0.5, v or 0.5)
	end
	local zoneColors = {forest = Color3.fromRGB(79, 140, 95), marsh = Color3.fromRGB(82, 135, 151), volcanic = Color3.fromRGB(181, 108, 76), frost = Color3.fromRGB(168, 213, 236), desert = Color3.fromRGB(217, 178, 98)}
	for id, region in pairs(Config.Regions) do
		local bounds = Config.MapBounds
		local area = make("Frame", {Size = UDim2.fromScale(region.Radius * 2 / (bounds.MaxX - bounds.MinX), region.Radius * 2 / (bounds.MaxZ - bounds.MinZ)), Position = mapPosition(region.X, region.Z), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = zoneColors[id], BackgroundTransparency = 0.3, BorderSizePixel = 0}, map)
		make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, area)
		local shortName = ({forest = "ORMAN", marsh = "SİS", volcanic = "KÖZ", frost = "BUZUL", desert = "ÇÖL"})[id]
		local text = label(map, shortName .. "\nSv." .. region.EnemyLevel, mapPosition(region.X, region.Z + region.Radius + 90), UDim2.fromOffset(40, 26), 9)
		text.AnchorPoint, text.TextXAlignment = Vector2.new(0.5, 0.5), Enum.TextXAlignment.Center
	end
	local village = label(map, "GÜVENLİ KÖY", mapPosition(0, 85), UDim2.fromOffset(100, 24), 10, colors.gold)
	village.AnchorPoint, village.TextXAlignment = Vector2.new(0.5, 0), Enum.TextXAlignment.Center
	local markers, waypointMarkers, travelButtons = {}, {}, {}
	for _, id in ipairs(order) do
		local marker = label(map, "◆", mapPosition(Config.Bosses[id].X, Config.Bosses[id].Z), UDim2.fromOffset(22, 22), 20, colors.gold)
		marker.AnchorPoint, marker.TextXAlignment = Vector2.new(0.5, 0.5), Enum.TextXAlignment.Center
		markers[id] = marker
	end
	local waypointOrder = {"village", "forest", "marsh", "volcanic", "frost", "desert"}
	for index, id in ipairs(waypointOrder) do
		local definition = Config.Waypoints[id]
		local marker = label(map, "◇", mapPosition(definition.Position.x, definition.Position.z), UDim2.fromOffset(20, 20), 20, colors.muted)
		marker.AnchorPoint, marker.TextXAlignment = Vector2.new(0.5, 0.5), Enum.TextXAlignment.Center
		waypointMarkers[id] = marker
		local column, row = (index - 1) % 2, math.floor((index - 1) / 2)
		travelButtons[id] = button(mapPanel, definition.Name, UDim2.new(column * 0.5, column == 0 and 0 or 4, 0, 236 + row * 56), UDim2.new(0.5, -6, 0, 48), function()
			if (self.state.waypoints or {})[id] and not self.state.travel then remotes:WaitForChild("TravelRequest"):FireServer(id) end
		end)
		travelButtons[id].TextSize = 11
	end
	local playerMarker = label(map, "●", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(22, 22), 20, Color3.new(1, 1, 1))
	playerMarker.AnchorPoint, playerMarker.TextXAlignment = Vector2.new(0.5, 0.5), Enum.TextXAlignment.Center
	label(map, "Kuzey ↑   ◆ Boss   ◇ Türbe   ● Sen", UDim2.fromOffset(6, 2), UDim2.new(1, -12, 0, 20), 10, colors.muted)
	local function setZ()
		for _, item in ipairs(content:GetDescendants()) do if item:IsA("GuiObject") then item.ZIndex = 7 end end
	end
	setZ()
	function self:setState(state)
		self.state = state
		characterHUD:setState(state)
		for id, card in pairs(cards) do
			local owned = (state.pets or {})[id] == true
			card.equip.Text = state.equippedPet == id and "ÇIKAR" or (owned and "TAK" or "KİLİTLİ")
			card.equip.Selectable, card.equip.AutoButtonColor = owned, owned
			card.detail.Text = string.format("%s • +%d hasar\n%s\nGaranti %d / %d", Config.Bosses[card.bossId].Name, Config.Pets[id].DamageBonus, owned and "Koleksiyonunda" or ("%" .. dropPercent .. " nadir düşüş"), (state.petPity or {})[card.bossId] or 0, Config.PetPityLimit)
		end
	end
	function self:resize(viewport)
		characterHUD:resize(viewport)
		-- Native dimensions retain readable text and 44px buttons; long panels scroll.
		content.Size = UDim2.fromOffset(math.min(540, viewport.X - 24), math.min(560, viewport.Y - 24))
		local scale = math.clamp(math.min(viewport.X / 780, viewport.Y / 650), 0.54, 1)
		eventScale.Scale = scale
		local baseScale = math.clamp(math.min(viewport.X / 900, viewport.Y / 680), 0.58, 1)
		local portrait = viewport.X < 480
		local top = portrait and (36 + 287 * baseScale) or 12
		events.Position = UDim2.new(1, -12, 0, top)
		local compactControls = UserInputService.TouchEnabled or viewport.X < 700 or viewport.Y < 450
		local shortRows = portrait and compactControls
		events.Size = UDim2.fromOffset(290, shortRows and 140 or 188)
		clock.Position = UDim2.fromOffset(12, shortRows and 25 or 29)
		for index, id in ipairs(order) do
			eventLabels[id].Position = UDim2.fromOffset(12, (shortRows and 40 or 51) + (index - 1) * (shortRows and 30 or 43))
			eventLabels[id].Size = UDim2.new(1, -24, 0, shortRows and 28 or 40)
		end
		local width = compactControls and (portrait and math.min(viewport.X - 24, 320) or 264) or 224
		menu.Size = UDim2.fromOffset(width, compactControls and 50 or 102)
		menu.Position = UDim2.new(1, -12, 0, top + 10 + events.Size.Y.Offset * scale)
		for index, item in ipairs(menuButtons) do
			local column, row = compactControls and (index - 1) or ((index - 1) % 2), compactControls and 0 or math.floor((index - 1) / 2)
			local cell = (width - 14) / (compactControls and 4 or 2)
			item.Position, item.Size = UDim2.fromOffset(4 + column * (cell + 2), 3 + row * 49), UDim2.fromOffset(cell, 44)
			item.TextSize = compactControls and 10 or 12
			item.Text = index == 4 and invitePending and "GRUP !" or captions[index]
		end
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if UserInputService:GetFocusedTextBox() then return end
		if self.open and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then show(selectedMenu) return end
		if processed or GuiService.MenuIsOpen then return end
		if input.KeyCode == Enum.KeyCode.P or input.KeyCode == Enum.KeyCode.ButtonY then show("pets")
		elseif input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.ButtonL3 then show("map")
		elseif input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.DPadUp then show("character")
		elseif input.KeyCode == Enum.KeyCode.G or input.KeyCode == Enum.KeyCode.DPadLeft then show("party") end
	end)
	remotes:WaitForChild("OpenTravel").OnClientEvent:Connect(function() show("map", true) end)
	remotes:WaitForChild("WorldState").OnClientEvent:Connect(function(world) if type(world) == "table" then self.world = world end end)
	local function timeText(seconds)
		seconds = math.max(0, math.floor(seconds))
		return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
	end
	task.spawn(function()
		while gui.Parent do
			local now, world = workspace:GetServerTimeNow(), self.world
			clock.Text = world.studioDemo and "STUDIO • Hızlandırılmış demo takvimi" or ("İstanbul " .. os.date("!%H:%M:%S", math.floor(now) + 10800) .. " • Saatlik bosslar")
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			playerMarker.Visible = root ~= nil
			if root then playerMarker.Position = mapPosition(root.Position.X, root.Position.Z) end
			local atShrine
			if root then
				for id, point in pairs(Config.Waypoints) do
					local p = point.Position
					if (root.Position - Vector3.new(p.x, p.y, p.z)).Magnitude <= Config.Travel.SourceRange then atShrine = id break end
				end
			end
			for id, item in pairs(travelButtons) do
				local unlocked = (self.state.waypoints or {})[id] == true
				item.Text = Config.Waypoints[id].Name .. "\n" .. (not unlocked and "Önce keşfet" or (atShrine == id and "Buradasın" or "Seyahat et • 3 sn"))
				local enabled = unlocked and atShrine ~= nil and atShrine ~= id and not self.state.travel
				item.Selectable, item.AutoButtonColor = enabled, enabled
				item.BackgroundColor3 = enabled and Color3.fromRGB(46, 85, 69) or Color3.fromRGB(38, 47, 47)
				waypointMarkers[id].TextColor3 = unlocked and colors.gold or colors.muted
			end
			local channel = self.state.travel
			mapHint.Text = channel and string.format("%s • %.1f sn\nHareket etmek veya savaşmak seyahati iptal eder.", (Config.Waypoints[channel.destination] or {}).Name or "Seyahat", math.max(0, channel.endsAt - now))
				or (atShrine and "Keşfedilmiş bir hedef seç. Savaş dışında 10 sn bekle; 3 sn boyunca hareketsiz kal." or "Türbelere yürüyüp E ile keşfet. Seyahat etmek için bir türbenin 16 stud yakınına gel.")
			for _, boss in ipairs(world.bosses or {}) do
				local line, cfg = eventLabels[boss.id], Config.Bosses[boss.id]
				if line and cfg then
					local alive, when = boss.status == "alive" or boss.status == "active", boss.nextAt or now
					local status = alive and ("CANLI • " .. timeText((boss.despawnAt or now) - now)) or ("Sonraki " .. os.date("!%H:%M", math.floor(when) + 10800) .. " • " .. timeText(when - now))
					local near = root and boss.x and boss.z and (root.Position - Vector3.new(boss.x, root.Position.Y, boss.z)).Magnitude < 200
					if alive and near then status = string.format("CAN %d / %d • %s", boss.health or 0, boss.maxHealth or 1, timeText((boss.despawnAt or now) - now)) end
					if boss.status == "defeated" then status = "Yenildi • " .. status elseif boss.status == "expired" then status = "Süre doldu • " .. status end
					line.Text, line.TextColor3 = cfg.Name .. "\n" .. status, alive and colors.gold or colors.text
					markers[boss.id].Position = mapPosition(boss.x or cfg.X, boss.z or cfg.Z)
					markers[boss.id].TextColor3 = alive and Color3.fromRGB(255, 134, 100) or colors.gold
				end
			end
			task.wait(0.25)
		end
	end)
	return self
end
return WorldHUD
