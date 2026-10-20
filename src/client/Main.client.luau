-- Aetheria's HUD only presents state; combat and rewards belong to the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("AetheriaRemotes")
local attackRemote = remotes:WaitForChild("Attack")
local stateRemote = remotes:WaitForChild("State")
local requestState = remotes:WaitForChild("RequestState")
local notifyRemote = remotes:WaitForChild("Notify")
local GuiService = game:GetService("GuiService")
local gui = Instance.new("ScreenGui")
gui.Name = "AetheriaHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local colors = Theme.colors
local function create(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties) do object[key] = value end
	object.Parent = parent
	return object
end
local function panel(size, position, anchor)
	local frame = create("Frame", { Size = size, Position = position, AnchorPoint = anchor or Vector2.zero, BackgroundColor3 = colors.panel, BackgroundTransparency = 0.12, BorderSizePixel = 0 }, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, frame)
	create("UIStroke", { Color = colors.gold, Transparency = 0.65 }, frame)
	Theme.panel(frame)
	return frame
end
local function label(parent, text, position, size, textSize, color)
	return create("TextLabel", { BackgroundTransparency = 1, Position = position, Size = size, Text = text, TextSize = textSize or 14, Font = Enum.Font.GothamMedium, TextColor3 = color or colors.text, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true }, parent)
end
local function bar(parent, y, color)
	local track = create("Frame", { Position = UDim2.fromOffset(14, y), Size = UDim2.new(1, -28, 0, 7), BackgroundColor3 = Color3.fromRGB(42, 57, 51), BorderSizePixel = 0, ClipsDescendants = true }, parent)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
	local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = color, BorderSizePixel = 0 }, track)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	Theme.gradient(fill, Color3.fromRGB(240, 255, 255), Color3.fromRGB(124, 192, 223), 0)
	return fill
end

local stats = panel(UDim2.fromOffset(270, 155), UDim2.fromOffset(12, 12))
local brand = label(stats, "AETHERIA / UFUKLAR", UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 25), 18, colors.gold)
brand.Font = Enum.Font.GothamBold
local regionLabel = label(stats, "GÜVENLİ KÖY", UDim2.fromOffset(15, 33), UDim2.new(1, -28, 0, 18), 11, colors.muted)
require(script.Parent:WaitForChild("BiomeAmbience")).start(regionLabel)
local healthText = label(stats, "Can • —", UDim2.fromOffset(14, 56), UDim2.new(1, -28, 0, 20))
local healthFill = bar(stats, 80, colors.health)
local xpText = label(stats, "Seviye —  •  XP —", UDim2.fromOffset(14, 92), UDim2.new(1, -28, 0, 20))
local xpFill = bar(stats, 116, colors.xp)
local goldText = label(stats, "Altın 0", UDim2.fromOffset(14, 129), UDim2.new(1, -28, 0, 18), 12, colors.gold)

local quest = panel(UDim2.fromOffset(270, 132), UDim2.fromOffset(12, 177))
local saveText = label(quest, "", UDim2.fromOffset(14, 109), UDim2.new(1, -28, 0, 18), 10, colors.muted)

local hint = panel(UDim2.fromOffset(350, 48), UDim2.new(0.5, 0, 1, -12), Vector2.new(0.5, 1))
local hintText = label(hint, "Muhafıza yaklaş • Görevi al • Ormanı koru", UDim2.fromOffset(12, 4), UDim2.new(1, -24, 1, -8), 12, colors.muted)
local attackButton = create("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -155), Size = UDim2.fromOffset(112, 76), BackgroundColor3 = colors.button, TextColor3 = colors.text, Text = "SALDIR\nSol tık / F", TextSize = 16, Font = Enum.Font.GothamBold, AutoButtonColor = true, BorderSizePixel = 0 }, gui)
create("UICorner", { CornerRadius = UDim.new(0, 22) }, attackButton)
create("UIStroke", { Color = colors.gold, Transparency = 0.3 }, attackButton)
Theme.gradient(attackButton, Color3.fromRGB(242, 255, 251), Color3.fromRGB(133, 194, 227))
local toast = panel(UDim2.fromOffset(350, 65), UDim2.new(0.5, 0, 0, 12), Vector2.new(0.5, 0))
toast.Visible = false
local toastText = label(toast, "", UDim2.fromOffset(14, 7), UDim2.new(1, -28, 1, -14), 15)
local progressionFeedback = require(script.Parent:WaitForChild("ProgressionFeedback")).create(gui, create, label, colors)
local worldHUD = require(script.Parent:WaitForChild("WorldHUD")).create(gui, remotes, create, label, colors)
local journeyHUD = require(script.Parent:WaitForChild("JourneyHUD")).create(gui, quest, remotes, create, label, colors, function() return worldHUD.open end)
worldHUD:attachJourney(journeyHUD)
local interactionVFX = require(script.Parent:WaitForChild("InteractionVFX")).start(gui, function() return worldHUD.open or GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() ~= nil end)
local regionIntro = require(script.Parent:WaitForChild("RegionIntro")).create(gui, create, label, colors, function()
	return worldHUD.open or GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() ~= nil or progressionFeedback:isVisible()
end)
local targetHUD = require(script.Parent:WaitForChild("TargetHUD"))
targetHUD.start(gui, create, label, colors, function() return worldHUD.open end)
require(script.Parent:WaitForChild("PetVisuals")).start()
require(script.Parent:WaitForChild("CombatEffects")).start(remotes:WaitForChild("CombatEffect"), remotes:WaitForChild("CombatHit"), gui)
require(script.Parent:WaitForChild("CombatText")).start(remotes:WaitForChild("CombatHit"), gui)
require(script.Parent:WaitForChild("WorldMotion")).start(gui)
require(script.Parent:WaitForChild("EnemyPresentation")).start(gui)

local scales = {}
for _, frame in ipairs({ stats, quest, hint, attackButton, toast }) do
	scales[frame] = create("UIScale", { Scale = 1 }, frame)
end
local function resize()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = gui.AbsoluteSize
	if viewport.X <= 0 or viewport.Y <= 0 then viewport = camera.ViewportSize end
	local scale = math.clamp(math.min(viewport.X / 900, viewport.Y / 680), 0.58, 1)
	for _, item in pairs(scales) do item.Scale = scale end
	hint.Visible = true
	attackButton.Size = UDim2.fromOffset(112, 76)
	quest.Position = UDim2.fromOffset(12, 24 + 155 * scale)
	local eventScale = math.clamp(math.min(viewport.X / 780, viewport.Y / 650), 0.54, 1)
	local toastTop = viewport.X < 480 and (60 + 287 * scale + 264 * eventScale) or 12
	toast.AnchorPoint = viewport.X < 480 and Vector2.zero or Vector2.new(0.5, 0)
	toast.Position = viewport.X < 480 and UDim2.fromOffset(12, toastTop) or UDim2.new(0.5, 0, 0, toastTop)
	attackButton.Position = viewport.Y < 450 and viewport.X > viewport.Y
		and UDim2.new(1, -140, 1, -70) or UDim2.new(1, -24, 1, -155)
	if UserInputService.TouchEnabled or viewport.X < 700 or viewport.Y < 450 then
		hint.Visible = false
		scales[attackButton].Scale = 1
		attackButton.Size = UDim2.fromOffset(72, 48)
		attackButton.Position = viewport.X > viewport.Y and UDim2.new(1, -96, 1, -56) or UDim2.new(1, -24, 1, -215)
		-- On short portrait phones, keep the jump corner and the skill row clear.
		if viewport.X <= viewport.Y and viewport.Y < 620 then attackButton.Position = UDim2.new(0, 84, 1, -142) end
		toast.Position = UDim2.fromOffset(12, 12)
		toast.AnchorPoint = Vector2.zero
	end
	worldHUD:resize(viewport)
	progressionFeedback:resize(viewport)
	journeyHUD:resize(viewport)
	regionIntro:resize(viewport)
end
local viewportConnection
local function watchCamera()
	if viewportConnection then viewportConnection:Disconnect() end
	if workspace.CurrentCamera then viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
	resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
watchCamera()

local function updateInputHint()
	local input = UserInputService:GetLastInputType()
	if input == Enum.UserInputType.Touch then
		attackButton.Text = "SALDIR"
		hintText.Text = "Haritadan hedef seç • Etkileşim simgesine dokun"
	elseif string.find(input.Name, "Gamepad") then
		attackButton.Text = "SALDIR\nR2"
		hintText.Text = "Etkileşim: X • Harita: L3"
	else
		attackButton.Text = "SALDIR\nSol tık / F"
		hintText.Text = "Hedef seç: M • Etkileşim: E • Saldırı: F"
	end
end
UserInputService.LastInputTypeChanged:Connect(updateInputHint)
updateInputHint()

local lastAttack = 0
local function attack()
	if UserInputService:GetFocusedTextBox() or worldHUD.open or GuiService.MenuIsOpen then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or os.clock() - lastAttack < 0.2 then return end
	lastAttack = os.clock()
	local preferred = targetHUD.getTarget()
	if preferred then attackRemote:FireServer(preferred) else attackRemote:FireServer() end
	attackButton.BackgroundColor3 = colors.gold
	TweenService:Create(attackButton, TweenInfo.new(0.2), { BackgroundColor3 = colors.button }):Play()
end
attackButton.Activated:Connect(attack)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonR2 then attack()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		local objects = player.PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
		for _, object in ipairs(objects) do
			if object:GetAttribute("AetheriaPassiveVisual") == true then continue end
			if object.Visible and (object:IsDescendantOf(gui) or object:IsA("GuiButton") or object:IsA("TextBox") or object.Active) then return end
		end
		attack()
	end
end)

local healthConnections = {}
local characterVersion = 0
local function bindCharacter(character)
	characterVersion += 1
	local version = characterVersion
	for _, connection in ipairs(healthConnections) do connection:Disconnect() end
	table.clear(healthConnections)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or version ~= characterVersion then return end
	local function updateHealth()
		healthText.Text = string.format("Can • %d / %d", math.ceil(humanoid.Health), math.ceil(humanoid.MaxHealth))
		healthFill.Size = UDim2.fromScale(math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1), 1)
	end
	table.insert(healthConnections, humanoid.HealthChanged:Connect(updateHealth))
	table.insert(healthConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth))
	updateHealth()
end
player.CharacterAdded:Connect(bindCharacter)
if player.Character then task.spawn(bindCharacter, player.Character) end

stateRemote.OnClientEvent:Connect(function(state)
	if type(state) ~= "table" then return end
	local xp, needed = tonumber(state.xp) or 0, math.max(1, tonumber(state.xpNeeded) or 100)
	xpText.Text = string.format("Seviye %d  •  XP %d / %d", state.level or 1, xp, needed)
	xpFill.Size = UDim2.fromScale(math.clamp(xp / needed, 0, 1), 1)
	goldText.Text = string.format("Altın %d  •  Yıldız tozu %d", state.gold or 0, state.stardust or 0)
	worldHUD:setState(state)
	progressionFeedback:setState(state)
	journeyHUD:setState(state)
	interactionVFX:setState(state)
	targetHUD.setState(state)
	local saveMessages = { ["Studio: geçici"] = "Studio • İlerleme bu oturum için geçici", ["Kaydedildi"] = "İlerleme kaydedildi", ["Kayıt hatası"] = "Kayıt hatası • İlerlemen kaydedilemedi" }
	saveText.Text = saveMessages[state.saveStatus] or ""
end)
local toastVersion = 0
notifyRemote.OnClientEvent:Connect(function(message)
	if type(message) ~= "string" then return end
	toastVersion += 1
	local version = toastVersion
	toastText.Text = message
	toast.Visible = true
	task.delay(4, function() if version == toastVersion then toast.Visible = false end end)
end)
requestState:FireServer()
