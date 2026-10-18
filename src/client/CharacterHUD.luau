local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local TargetHUD = require(script.Parent:WaitForChild("TargetHUD"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local CharacterHUD = {}
function CharacterHUD.create(gui, parent, remotes, make, label, button, colors, blocked)
	local self = { state = {} }
	local selectRemote = remotes:WaitForChild("SelectClass")
	local abilityRemote = remotes:WaitForChild("UseAbility")
	local craftRemote = remotes:WaitForChild("CraftUpgrade")
	local claimRemote = remotes:WaitForChild("ClaimExpedition")
	local classButtons = {}
	for index, id in ipairs({ "warrior", "mage" }) do
		classButtons[id] = button(parent, Config.Classes[id].Name, UDim2.new((index - 1) * 0.5, index == 1 and 0 or 4, 0, 0), UDim2.new(0.5, -4, 0, 38), function() selectRemote:FireServer(id) end)
	end
	label(parent, "Sınıf değişimi: güvenli köyde, 10 sn savaş dışında.", UDim2.fromOffset(0, 40), UDim2.new(1, 0, 0, 20), 11, colors.muted)
	local stats = label(parent, "", UDim2.fromOffset(0, 64), UDim2.new(1, 0, 0, 25), 14, colors.gold)
	label(parent, "BORİN'İN OCAĞI", UDim2.fromOffset(0, 98), UDim2.new(1, 0, 0, 23), 15, colors.gold)
	local equipment = label(parent, "", UDim2.fromOffset(0, 124), UDim2.new(1, -126, 0, 44), 13)
	local craft = button(parent, "YÜKSELT", UDim2.new(1, -118, 0, 127), UDim2.fromOffset(118, 36), function()
		if Config.Equipment[(self.state.equipmentTier or 0) + 1] then craftRemote:FireServer() end
	end)
	local materials = label(parent, "", UDim2.fromOffset(0, 171), UDim2.new(1, 0, 0, 24), 12, colors.muted)
	label(parent, "Kaynaklara yaklaş → E ile topla. Üretim için Borin'e yaklaş.", UDim2.fromOffset(0, 213), UDim2.new(1, 0, 0, 23), 11, colors.muted)
	label(parent, "SEFER GÜNLÜĞÜ", UDim2.fromOffset(0, 243), UDim2.new(1, 0, 0, 24), 15, colors.gold)
	local expedition = label(parent, "", UDim2.fromOffset(0, 270), UDim2.new(1, -126, 0, 65), 12)
	local claim = button(parent, "ÖDÜLÜ AL", UDim2.new(1, -118, 0, 278), UDim2.fromOffset(118, 36), function()
		local progress = self.state.expedition
		local stage = progress and Config.Expedition[progress.stage]
		if stage and progress.progress >= stage.Target then claimRemote:FireServer() end
	end)
	local rewards = label(parent, "", UDim2.fromOffset(0, 338), UDim2.new(1, 0, 0, 28), 12, colors.muted)
	local contractHUD = require(script.Parent:WaitForChild("ContractHUD")).create(gui, parent, remotes, make, label, button, colors)

	local hotbar = make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -72), Size = UDim2.fromOffset(248, 89), BackgroundColor3 = colors.panel, BackgroundTransparency = 0.12, BorderSizePixel = 0 }, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, hotbar)
	local scale = make("UIScale", { Scale = 1 }, hotbar)
	local resource = label(hotbar, "Enerji • —", UDim2.fromOffset(9, 2), UDim2.new(1, -18, 0, 18), 11, colors.muted)
	resource.TextWrapped, resource.TextTruncate = false, Enum.TextTruncate.AtEnd
	local targetInfo = label(hotbar, "", UDim2.fromOffset(9, 17), UDim2.new(1, -18, 0, 14), 9, colors.muted)
	targetInfo.TextWrapped, targetInfo.TextTruncate = false, Enum.TextTruncate.AtEnd
	targetInfo.Visible = false
	local resourceTrack = make("Frame", { Size = UDim2.new(1, -18, 0, 4), Position = UDim2.fromOffset(9, 23), BackgroundColor3 = Color3.fromRGB(40, 55, 66), BorderSizePixel = 0 }, hotbar)
	local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(115, 169, 239), BorderSizePixel = 0 }, resourceTrack)
	local skills, lastCast = {}, 0
	local function cast(slot)
		if blocked() or UserInputService:GetFocusedTextBox() or GuiService.MenuIsOpen then return end
		local state = self.state
		local ability = (Config.Abilities[state.classId or "warrior"] or {})[slot]
		local character = Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not ability or not humanoid or humanoid.Health <= 0 then return end
		if (state.cooldowns or {})[slot] and state.cooldowns[slot] > workspace:GetServerTimeNow() then return end
		if (state.resource or 0) < ability.Cost or os.clock() - lastCast < 0.12 then return end
		lastCast = os.clock()
		local preferred = TargetHUD.getTarget()
		if preferred then abilityRemote:FireServer(slot, preferred) else abilityRemote:FireServer(slot) end
	end
	for index, slot in ipairs({ "primary", "secondary" }) do
		skills[slot] = button(hotbar, "—", UDim2.fromOffset(8 + (index - 1) * 120, 35), UDim2.fromOffset(112, 46), function() cast(slot) end)
		skills[slot].TextSize = 12
		skills[slot].TextWrapped = true
	end
	local targetButton = button(hotbar, "HEDEF\nTab / R3", UDim2.fromOffset(248, 35), UDim2.fromOffset(68, 46), function()
		if not blocked() then TargetHUD.cycle() end
	end)
	targetButton.TextSize = 11
	for _, entry in ipairs({ { "primary", Enum.KeyCode.Q, Enum.KeyCode.ButtonL1 }, { "secondary", Enum.KeyCode.R, Enum.KeyCode.ButtonR1 } }) do
		ContextActionService:BindActionAtPriority("Aetheria_" .. entry[1], function(_, inputState)
			if blocked() or UserInputService:GetFocusedTextBox() or GuiService.MenuIsOpen then return Enum.ContextActionResult.Pass end
			if inputState == Enum.UserInputState.Begin then cast(entry[1]) end
			return Enum.ContextActionResult.Sink
		end, false, 3000, entry[2], entry[3])
	end
	local names = { wood = "Odun", iron = "Demir", ember = "Köz" }
	local function materialText(values, includeZero)
		local texts = {}
		for _, id in ipairs({ "wood", "iron", "ember" }) do if includeZero or (values[id] or 0) > 0 then table.insert(texts, names[id] .. " " .. (values[id] or 0)) end end
		return #texts > 0 and table.concat(texts, " • ") or "—"
	end
	function self:setState(state)
		self.state = state
		contractHUD:setState(state)
		local classId = state.classId or "warrior"
		for id, item in pairs(classButtons) do item.Text = (id == classId and "✓ " or "") .. Config.Classes[id].Name end
		local values = state.stats or {}
		stats.Text = string.format("Can %d   •   Hasar %d   •   Menzil %d", values.maxHealth or Config.Classes[classId].MaxHealth, values.basicDamage or 0, values.basicRange or 0)
		local tier = state.equipmentTier or 0
		local nextTier = Config.Equipment[tier + 1]
		local current = Config.Equipment[tier]
		equipment.Text = current and (current.Name .. " • Kademe " .. tier) or "Başlangıç ekipmanı • Kademe 0"
		if nextTier then equipment.Text ..= "\nSonraki: " .. nextTier.Name end
		craft.Text = nextTier and "YÜKSELT" or "EN ÜST KADEME"
		craft.Selectable, craft.AutoButtonColor = nextTier ~= nil, nextTier ~= nil
		materials.Text = "Çantanda: " .. materialText(state.materials or {}, true)
		if nextTier then materials.Text ..= "\nGerekli: " .. materialText(nextTier.Materials) .. " • " .. nextTier.Gold .. " altın" end
		materials.Size = UDim2.new(1, 0, 0, 40)
		local progress = state.expedition or { stage = 1, progress = 0 }
		local stage = Config.Expedition[progress.stage]
		expedition.Text = stage and string.format("%d. %s\nİlerleme %d / %d", progress.stage, stage.Name, progress.progress or 0, stage.Target) or "Sefer tamamlandı!\nAetheria'yı keşfetmeye devam et."
		if stage then
			expedition.Text ..= "\n" .. (stage.Description or (stage.RegionId and "Bölgedeki yaratıkları yen." or "Bir dünya bossunu yenmeye katıl."))
		end
		local ready = stage ~= nil and (progress.progress or 0) >= stage.Target
		claim.Text = ready and "ÖDÜLÜ AL" or (stage and "DEVAM EDİYOR" or "TAMAMLANDI")
		claim.Selectable, claim.AutoButtonColor = ready, ready
		rewards.Text = stage and string.format("Ödül: %d XP • %d altın • %s", stage.XP, stage.Gold, materialText(stage.Materials or {})) or "Tüm sefer ödüllerini aldın."
	end
	function self:focusContract(id) contractHUD:focus(id) end
	function self:resize(viewport)
		scale.Scale = math.clamp(math.min(viewport.X / 900, viewport.Y / 680), 0.58, 1)
		hotbar.Size, hotbar.AnchorPoint = UDim2.fromOffset(324, 89), Vector2.new(0.5, 1)
		hotbar.Position = UDim2.new(0.5, 0, 1, -72)
		resource.Position, resource.Size = UDim2.fromOffset(9, 2), UDim2.new(1, -18, 0, 18)
		resourceTrack.Position = UDim2.fromOffset(9, 23)
		targetInfo.Visible = false
		targetButton.Position, targetButton.Size = UDim2.fromOffset(248, 35), UDim2.fromOffset(68, 46)
		for index, slot in ipairs({"primary", "secondary"}) do
			skills[slot].Position = UDim2.fromOffset(8 + (index - 1) * 120, 35)
			skills[slot].Size = UDim2.fromOffset(112, 46)
			skills[slot].TextSize = 12
		end
		if UserInputService.TouchEnabled or viewport.X < 700 or viewport.Y < 450 then
			scale.Scale = 1
			hotbar.Size = UDim2.fromOffset(200, 90)
			local landscape = viewport.X > viewport.Y
			hotbar.AnchorPoint = landscape and Vector2.new(0.5, 1) or Vector2.new(1, 1)
			hotbar.Position = landscape and UDim2.new(0.5, 0, 1, -20) or UDim2.new(1, -24, 1, -100)
			for index, slot in ipairs({ "primary", "secondary" }) do
				skills[slot].Position = UDim2.fromOffset(6 + (index - 1) * 66, 35)
				skills[slot].Size = UDim2.fromOffset(60, 46)
				skills[slot].TextSize = 11
			end
			targetButton.Position, targetButton.Size = UDim2.fromOffset(138, 35), UDim2.fromOffset(56, 46)
			resource.Position, resource.Size = UDim2.fromOffset(9, 0), UDim2.new(1, -18, 0, 16)
			resourceTrack.Position = UDim2.fromOffset(9, 31)
			targetInfo.Visible = true
		end
	end
	task.spawn(function()
		while gui.Parent do
			local state = self.state
			local value = math.clamp(state.resource or 0, 0, Config.ResourceMax)
			resource.Text = string.format("Enerji • %d / %d", math.floor(value), Config.ResourceMax)
			local selected = TargetHUD.getInfo()
			if targetInfo.Visible then
				resource.Text = selected and (selected.kind .. " • " .. selected.name) or "Hedef seç • Tab / R3"
				targetInfo.Text = selected and string.format("Can %d/%d • %.0fst%s • E %d", selected.health, selected.maxHealth, selected.distance, selected.inRange and "" or " UZAK", math.floor(value)) or string.format("Enerji %d/%d • HEDEF ile sıradaki", math.floor(value), Config.ResourceMax)
			end
			fill.Size = UDim2.fromScale(value / Config.ResourceMax, 1)
			local input = UserInputService:GetLastInputType()
			targetButton.Text = input == Enum.UserInputType.Touch and "HEDEF" or "HEDEF\nTab / R3"
			for index, slot in ipairs({ "primary", "secondary" }) do
				local ability = (Config.Abilities[state.classId or "warrior"] or {})[slot]
				if ability then
					local remaining = math.max(0, ((state.cooldowns or {})[slot] or 0) - workspace:GetServerTimeNow())
					local key = input == Enum.UserInputType.Touch and "" or (string.find(input.Name, "Gamepad") and (index == 1 and "L1 • " or "R1 • ") or (index == 1 and "Q • " or "R • "))
					skills[slot].Text = key .. ability.Name .. "\n" .. (remaining > 0 and string.format("%.1f sn", remaining) or (ability.Cost .. " enerji"))
					skills[slot].BackgroundColor3 = remaining <= 0 and value >= ability.Cost and Color3.fromRGB(50, 85, 84) or Color3.fromRGB(38, 47, 47)
				end
			end
			task.wait(0.1)
		end
	end)
	return self
end
return CharacterHUD
