local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local WorldHUD = {}

function WorldHUD.create(gui, remotes, make, label, colors)
	local self = { open = false, state = {}, world = { bosses = {} } }
	local function frame(parent, size, position, anchor)
		local item = make("Frame", { Size = size, Position = position, AnchorPoint = anchor or Vector2.zero, BackgroundColor3 = colors.panel, BackgroundTransparency = 0.06, BorderSizePixel = 0, Active = true }, parent)
		make("UICorner", { CornerRadius = UDim.new(0, 12) }, item)
		make("UIStroke", { Color = colors.gold, Transparency = 0.65 }, item)
		return item
	end
	local function button(parent, text, position, size, callback)
		local item = make("TextButton", { Text = text, Position = position, Size = size, BackgroundColor3 = Color3.fromRGB(46, 70, 59), TextColor3 = colors.text, Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0, Selectable = true }, parent)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, item)
		item.Activated:Connect(callback)
		return item
	end
	local events = frame(gui, UDim2.fromOffset(290, 188), UDim2.new(1, -12, 0, 12), Vector2.new(1, 0))
	label(events, "DÜNYA MUHAFIZLARI", UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 20), 14, colors.gold)
	local clock = label(events, "İstanbul • Sunucu saati bekleniyor", UDim2.fromOffset(12, 29), UDim2.new(1, -24, 0, 17), 10, colors.muted)
	local eventLabels = {}
	local order = { "thornwarden", "tide_sentinel", "ember_drake" }
	for index, id in ipairs(order) do
		eventLabels[id] = label(events, Config.Bosses[id].Name .. "\nSaat bekleniyor…", UDim2.fromOffset(12, 51 + (index - 1) * 43), UDim2.new(1, -24, 0, 40), 12)
	end
	local menu = frame(gui, UDim2.fromOffset(208, 40), UDim2.new(1, -12, 0, 210), Vector2.new(1, 0))
	local overlay = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3, Visible = false, Active = true, ZIndex = 5 }, gui)
	local content = frame(overlay, UDim2.fromOffset(540, 440), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	content.ZIndex = 6
	local contentScale = make("UIScale", { Scale = 1 }, content)
	local title = label(content, "", UDim2.fromOffset(18, 9), UDim2.new(1, -100, 0, 30), 21, colors.gold)
	local collection = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -32, 1, -60), Position = UDim2.fromOffset(16, 52) }, content)
	local map = make("Frame", { BackgroundColor3 = Color3.fromRGB(26, 46, 40), BorderSizePixel = 0, Size = UDim2.new(1, -32, 1, -84), Position = UDim2.fromOffset(16, 50), ClipsDescendants = true }, content)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, map)
	local mapHint = label(content, "Şematik harita • İşaretler konumu gösterir; ışınlanma yok.", UDim2.fromOffset(18, 408), UDim2.new(1, -36, 0, 22), 11, colors.muted)
	mapHint.Visible = false
	local function setZ(parent)
		for _, item in ipairs(parent:GetDescendants()) do if item:IsA("GuiObject") then item.ZIndex = 7 end end
	end
	local selectedMenu = "pets"
	local previousSelection
	local closeButton
	local function show(mode)
		local wasOpen = self.open
		local visible = not (self.open and selectedMenu == mode)
		selectedMenu = mode
		self.open = visible
		overlay.Visible = visible
		collection.Visible = mode == "pets"
		map.Visible = mode == "map"
		mapHint.Visible = mode == "map"
		title.Text = mode == "pets" and "YOL ARKADAŞLARIN" or "AETHERIA • DÜNYA HARİTASI"
		if visible then
			if not wasOpen then previousSelection = GuiService.SelectedObject end
			if UserInputService.GamepadEnabled then GuiService.SelectedObject = closeButton end
		elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(content) then GuiService.SelectedObject = previousSelection end
	end
	closeButton = button(content, "KAPAT", UDim2.new(1, -86, 0, 10), UDim2.fromOffset(70, 30), function() show(selectedMenu) end)
	button(menu, "PET [P / Y]", UDim2.fromOffset(5, 5), UDim2.fromOffset(94, 30), function() show("pets") end)
	button(menu, "HARİTA [M / L3]", UDim2.fromOffset(105, 5), UDim2.fromOffset(98, 30), function() show("map") end)
	local cards = {}
	for index, bossId in ipairs(order) do
		local boss = Config.Bosses[bossId]
		local petId = boss.PetId
		local card = frame(collection, UDim2.new(1, 0, 0, 87), UDim2.fromOffset(0, (index - 1) * 95))
		label(card, Config.Pets[petId].Name, UDim2.fromOffset(12, 6), UDim2.new(1, -136, 0, 23), 16, colors.gold)
		local detail = label(card, "", UDim2.fromOffset(12, 30), UDim2.new(1, -136, 0, 49), 11, colors.muted)
		local equip = button(card, "KİLİTLİ", UDim2.new(1, -112, 0, 22), UDim2.fromOffset(100, 40), function()
			if not (self.state.pets or {})[petId] then return end
			remotes:WaitForChild("EquipPet"):FireServer(self.state.equippedPet == petId and "" or petId)
		end)
		cards[petId] = { detail = detail, equip = equip, bossId = bossId }
	end
	local dropPercent = math.floor(Config.PetDropChance * 100 + 0.5)
	label(collection, string.format("Her uygun zaferde %%%d şans • %d. denemede garanti\nKatılım: en az %d isabet ve boss canının %%%d'i kadar hasar.\nAynı anda yalnızca bir yol arkadaşı takılır.", dropPercent, Config.PetPityLimit, Config.BossMinAcceptedHits, math.floor(Config.BossMinDamageFraction * 100 + 0.5)), UDim2.fromOffset(4, 286), UDim2.new(1, -8, 0, 76), 12, colors.muted)
	local function mapPosition(x, z)
		return UDim2.fromScale(math.clamp((x + 530) / 1060, 0.02, 0.98), math.clamp((z + 1010) / 1200, 0.02, 0.98))
	end
	local zones = { { "GÜVENLİ KÖY", 0, 0, Color3.fromRGB(151, 179, 123) } }
	local regionColors = { forest = Color3.fromRGB(79, 140, 95), marsh = Color3.fromRGB(82, 135, 151), volcanic = Color3.fromRGB(181, 108, 76) }
	for id, region in pairs(Config.Regions) do table.insert(zones, { region.Name, region.X, region.Z, regionColors[id] }) end
	for _, zone in ipairs(zones) do
		local area = make("Frame", { Size = UDim2.fromScale(0.33, 0.2), Position = mapPosition(zone[2], zone[3]), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = zone[4], BackgroundTransparency = 0.5, BorderSizePixel = 0 }, map)
		make("UICorner", { CornerRadius = UDim.new(0.45, 0) }, area)
		label(area, zone[1], UDim2.fromScale(0, 0.55), UDim2.fromScale(1, 0.4), 10).TextXAlignment = Enum.TextXAlignment.Center
	end
	local markers = {}
	for _, id in ipairs(order) do
		local marker = label(map, "◆", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(24, 24), 22, colors.gold)
		marker.AnchorPoint = Vector2.new(0.5, 0.5)
		marker.TextXAlignment = Enum.TextXAlignment.Center
		markers[id] = marker
		marker.Position = mapPosition(Config.Bosses[id].X, Config.Bosses[id].Z)
	end
	local playerMarker = label(map, "●", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(22, 22), 20, Color3.new(1, 1, 1))
	playerMarker.AnchorPoint = Vector2.new(0.5, 0.5)
	playerMarker.TextXAlignment = Enum.TextXAlignment.Center
	label(map, "Kuzey ↑     ◆ Boss     ● Sen", UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0, 20), 11, colors.muted)
	setZ(content)
	function self:setState(state)
		self.state = state
		for id, card in pairs(cards) do
			local owned = (state.pets or {})[id] == true
			local equipped = state.equippedPet == id
			card.equip.Text = equipped and "ÇIKAR" or (owned and "TAK" or "KİLİTLİ")
			card.equip.Selectable = owned
			card.equip.AutoButtonColor = owned
			card.detail.Text = string.format("%s • +%d hasar\n%s • Garanti sayacı %d / %d", Config.Bosses[card.bossId].Name, Config.Pets[id].DamageBonus, owned and "Koleksiyonunda" or ("%" .. dropPercent .. " nadir düşüş"), (state.petPity or {})[card.bossId] or 0, Config.PetPityLimit)
		end
	end
	function self:resize(viewport)
		local scale = math.clamp(math.min((viewport.X - 24) / 540, (viewport.Y - 90) / 440), 0.4, 1)
		contentScale.Scale = scale
		local compact = viewport.X < 700
		local eventScale = math.clamp(math.min(viewport.X / 780, viewport.Y / 650), 0.54, 1)
		if not events:FindFirstChildOfClass("UIScale") then make("UIScale", {}, events); make("UIScale", {}, menu) end
		events:FindFirstChildOfClass("UIScale").Scale = eventScale
		menu:FindFirstChildOfClass("UIScale").Scale = eventScale
		local baseScale = math.clamp(math.min(viewport.X / 900, viewport.Y / 680), 0.58, 1)
		local top = viewport.X < 480 and (36 + 287 * baseScale) or 12
		events.Position = UDim2.new(1, -12, 0, top)
		menu.Position = UDim2.new(1, -12, 0, top + 10 + 188 * eventScale)
		clock.TextSize = compact and 11 or 10
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if UserInputService:GetFocusedTextBox() then return end
		if self.open and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then show(selectedMenu); return end
		if processed then return end
		if input.KeyCode == Enum.KeyCode.P or input.KeyCode == Enum.KeyCode.ButtonY then show("pets")
		elseif input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.ButtonL3 then show("map") end
	end)
	remotes:WaitForChild("WorldState").OnClientEvent:Connect(function(world)
		if type(world) ~= "table" then return end
		self.world = world
		self.receivedAt = os.clock()
	end)
	local function timeText(seconds)
		seconds = math.max(0, math.floor(seconds))
		return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
	end
	task.spawn(function()
		while gui.Parent do
			local world = self.world
			local now = (world.serverNow or os.time()) + (self.receivedAt and os.clock() - self.receivedAt or 0)
			clock.Text = world.studioDemo and "STUDIO • Hızlandırılmış demo takvimi" or ("İstanbul " .. os.date("!%H:%M:%S", math.floor(now) + 10800) .. " • Saatlik bosslar")
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			playerMarker.Visible = root ~= nil
			if root then playerMarker.Position = mapPosition(root.Position.X, root.Position.Z) end
			for _, boss in ipairs(world.bosses or {}) do
				local line = eventLabels[boss.id]
				if line then
					local cfg = Config.Bosses[boss.id]
					local alive = boss.status == "alive" or boss.status == "active"
					local when = boss.nextAt or now
					local status = alive and ("CANLI • " .. timeText((boss.despawnAt or now) - now)) or ("Sonraki " .. os.date("!%H:%M", math.floor(when) + 10800) .. " • " .. timeText(when - now))
					local near = root and boss.x and boss.z and (root.Position - Vector3.new(boss.x, root.Position.Y, boss.z)).Magnitude < 200
					if alive and near then status = string.format("CAN %d / %d • %s", boss.health or 0, boss.maxHealth or 1, timeText((boss.despawnAt or now) - now)) end
					if boss.status == "defeated" then status = "Yenildi • " .. status elseif boss.status == "expired" then status = "Süre doldu • " .. status end
					line.Text = cfg.Name .. "\n" .. status
					line.TextColor3 = alive and colors.gold or colors.text
					markers[boss.id].Position = mapPosition(boss.x or cfg.X or 0, boss.z or cfg.Z or 0)
					markers[boss.id].TextColor3 = alive and Color3.fromRGB(255, 134, 100) or colors.gold
				end
			end
			task.wait(0.25)
		end
	end)
	return self
end
return WorldHUD
