-- Brief viewer-local chapter cards; reuse the reward card's empty HUD slot.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local WorldMap = require(Shared:WaitForChild("WorldMap"))
local Theme = require(script.Parent:WaitForChild("UITheme"))
local Intro = {}
local flavor = {village = "Maceran burada başlıyor", forest = "Kadim köklerin izinde", marsh = "Sisin ardındaki sırlar", volcanic = "Közün kalbine doğru", frost = "Donmuş ufuklara adım at", desert = "Kumun altındaki miras"}
local tones = {village = Theme.colors.gold, forest = Color3.fromRGB(164, 230, 151), marsh = Color3.fromRGB(135, 223, 237), volcanic = Color3.fromRGB(255, 171, 119), frost = Color3.fromRGB(190, 237, 255), desert = Color3.fromRGB(248, 218, 142)}
function Intro.create(gui, make, label, colors, isBlocked)
	local self = {}
	local disposed, candidate, candidateAt, committed, pending = false, nil, 0, nil, nil
	local lastShown, tweens, connections = {}, {}, {}
	local expires, fadeEnd = 0, nil
	local card = make("CanvasGroup", {Name = "RegionChapter", Size = UDim2.fromOffset(280, 64), Position = UDim2.new(0.5, 0, 0, 92), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = colors.panel, BackgroundTransparency = 0.1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, Active = false, ZIndex = 3}, gui)
	make("UICorner", {CornerRadius = UDim.new(0, 10)}, card)
	local edge = make("UIStroke", {Color = colors.gold, Transparency = 0.45, Thickness = 1}, card)
	Theme.panel(card)
	local title = label(card, "", UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 24), 15, colors.gold)
	title.Font = Enum.Font.GothamBold
	local subtitle = label(card, "", UDim2.fromOffset(10, 28), UDim2.new(1, -20, 0, 31), 11, colors.muted)
	card:SetAttribute("AetheriaPassiveVisual", true)
	for _, item in ipairs(card:GetDescendants()) do
		if item:IsA("GuiObject") then item.Active, item.ZIndex = false, 3; item:SetAttribute("AetheriaPassiveVisual", true) end
	end
	local function cancel()
		for _, tween in ipairs(tweens) do tween:Cancel() end
		table.clear(tweens)
	end
	local function hide()
		cancel()
		card.Visible, card.GroupTransparency, fadeEnd = false, 1, nil
	end
	function self:resize(viewport)
		if disposed then return end
		local w, h = viewport.X, viewport.Y
		if w < 480 then
			card.Size, card.AnchorPoint, card.Position = UDim2.fromOffset(math.clamp(w - 196, 100, 180), 84), Vector2.new(1, 0), UDim2.new(1, -12, 0, 104)
			title.Position, title.Size, title.TextSize = UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0, 36), 12
			subtitle.Position, subtitle.Size, subtitle.TextSize = UDim2.fromOffset(8, 42), UDim2.new(1, -16, 0, 36), 10
		elseif w < 900 or h < 450 then
			local base = math.clamp(math.min(w / 900, h / 680), 0.58, 1)
			local eventScale = math.clamp(math.min(w / 780, h / 650), 0.54, 1)
			local left, right = 22 + 270 * base, w - 22 - 290 * eventScale
			card.Size, card.AnchorPoint, card.Position = UDim2.fromOffset(math.max(100, math.min(210, right - left)), 34), Vector2.new(0.5, 0), UDim2.fromOffset((left + right) / 2, 88)
			title.Position, title.Size, title.TextSize = UDim2.fromOffset(8, 0), UDim2.new(1, -16, 0, 17), 11
			subtitle.Position, subtitle.Size, subtitle.TextSize = UDim2.fromOffset(8, 17), UDim2.new(1, -16, 0, 16), 10
		else
			card.Size, card.AnchorPoint, card.Position = UDim2.fromOffset(280, 64), Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 92)
			title.Position, title.Size, title.TextSize = UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 24), 15
			subtitle.Position, subtitle.Size, subtitle.TextSize = UDim2.fromOffset(10, 28), UDim2.new(1, -20, 0, 31), 11
		end
		title.TextTruncate, subtitle.TextTruncate = Enum.TextTruncate.AtEnd, Enum.TextTruncate.AtEnd
		title.TextWrapped, subtitle.TextWrapped = w < 480 or w >= 900, w < 480 or w >= 900
	end
	function self:destroy()
		if disposed then return end
		disposed = true
		cancel()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		card:Destroy()
	end
	table.insert(connections, gui.Destroying:Connect(function() self:destroy() end))
	table.insert(connections, gui.AncestryChanged:Connect(function() if not gui.Parent then self:destroy() end end))
	self:resize(gui.AbsoluteSize)
	task.spawn(function()
		while not disposed and gui.Parent do
			local time = os.clock()
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local id = root and humanoid and humanoid.Health > 0 and WorldMap.regionAt(root.Position.X, root.Position.Z, Config) or nil
			if id ~= candidate then candidate, candidateAt = id, time end
			if candidate and candidate ~= committed and time - candidateAt >= 1.2 then
				committed = candidate
				pending = time - (lastShown[candidate] or -math.huge) >= 12 and candidate or nil
			elseif not id then committed, pending = nil, nil end
			local blocked = isBlocked() or not root or not humanoid or humanoid.Health <= 0
			if blocked and card.Visible then hide() end
			if pending and pending == id and not blocked then
				hide()
				local region = Config.Regions[pending]
				title.Text = region and region.Name or "AETHERIA · GÜVENLİ KÖY"
				subtitle.Text = (flavor[pending] or "Yeni bir ufuk") .. (region and (" · Sv." .. region.EnemyLevel) or "")
				title.TextColor3, edge.Color = tones[pending] or colors.gold, tones[pending] or colors.gold
				card.Visible, expires, fadeEnd = true, time + 2.8, nil
				local tween = TweenService:Create(card, TweenInfo.new(0.3), {GroupTransparency = 0})
				table.insert(tweens, tween); tween:Play()
				lastShown[pending], pending = time, nil
			elseif card.Visible and not fadeEnd and time >= expires then
				fadeEnd = time + 0.25
				local tween = TweenService:Create(card, TweenInfo.new(0.25), {GroupTransparency = 1})
				table.insert(tweens, tween); tween:Play()
			elseif fadeEnd and time >= fadeEnd then hide() end
			task.wait(0.2)
		end
		self:destroy()
	end)
	return self
end
return Intro
