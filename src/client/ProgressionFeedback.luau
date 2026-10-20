-- Read-only server-state feedback. One nonmodal card, at most three pending batches.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Progression = require(Shared:WaitForChild("Progression"))
local Rules = require(Shared:WaitForChild("FeedbackRules"))
local Theme = require(script.Parent:WaitForChild("UITheme"))
local Feedback = {}
local priority = {pet = 6, level = 5, equipment = 4, chest = 3, discovery = 2, xp = 1}
local function merge(primary, other)
	local result = table.clone(primary)
	result.xp, result.gold = (primary.xp or 0) + (other.xp or 0), (primary.gold or 0) + (other.gold or 0)
	result.count = (primary.count or 1) + (primary.kind == other.kind and (other.count or 1) or 0)
	result.level, result.tier = math.max(primary.level or 1, other.level or 1), math.max(primary.tier or 0, other.tier or 0)
	for _, key in ipairs({"petIds", "siteIds"}) do
		local ids, seen = {}, {}
		for _, source in ipairs({primary[key] or {}, other[key] or {}}) do
			for _, id in ipairs(source) do if not seen[id] and #ids < 3 then seen[id] = true; table.insert(ids, id) end end
		end
		result[key] = ids
	end
	return result
end
function Feedback.create(gui, make, label, colors)
	local self = {}
	local tracker = Rules.new(Config, Progression.xpNeeded)
	local pending, current, expires, fadeEnd = {}, nil, 0, nil
	local disposed, tween = false, nil
	local card = make("CanvasGroup", {Name = "ProgressionFeedback", Size = UDim2.fromOffset(280, 64), Position = UDim2.new(0.5, 0, 0, 92), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = colors.panel, BackgroundTransparency = 0.06, GroupTransparency = 1, BorderSizePixel = 0, Visible = false, Active = false, Selectable = false, ZIndex = 3}, gui)
	card:SetAttribute("AetheriaPassiveVisual", true)
	make("UICorner", {CornerRadius = UDim.new(0, 10)}, card)
	local border = make("UIStroke", {Color = colors.gold, Transparency = 0.5, Thickness = 1}, card)
	Theme.panel(card)
	local heading = label(card, "", UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 22), 14, colors.gold)
	heading.Font = Enum.Font.GothamBold
	local detail = label(card, "", UDim2.fromOffset(10, 27), UDim2.new(1, -20, 0, 32), 11, colors.text)
	for _, object in ipairs(card:GetDescendants()) do
		if object:IsA("GuiObject") then
			object.Active, object.ZIndex = false, 3
			object:SetAttribute("AetheriaPassiveVisual", true)
		end
	end
	local function render(event)
		local texts = {}
		local kind, count = event.kind, event.count or 1
		if kind == "pet" then
			heading.Text = count > 1 and "YENİ YOL ARKADAŞLARI" or "YENİ YOL ARKADAŞI"
			local id = (event.petIds or {})[1]
			table.insert(texts, (Config.Pets[id] or {}).Name or "Nadir pet")
		elseif kind == "level" then heading.Text = "SEVİYE " .. event.level
		elseif kind == "equipment" then
			heading.Text = "DONANIM GÜÇLENDİ"
			table.insert(texts, (Config.Equipment[event.tier] or {}).Name or ("Kademe " .. event.tier))
		elseif kind == "chest" or kind == "discovery" then
			heading.Text = kind == "chest" and "HAZİNE AÇILDI" or "YENİ BİR UFUK"
			local id = (event.siteIds or {})[1]
			table.insert(texts, (Config.ExplorationSites[id] or {}).Name or "Keşif")
		else heading.Text = "ÖDÜL KAZANDIN" end
		if count > 1 and kind ~= "xp" and kind ~= "level" then table.insert(texts, "+" .. (count - 1) .. " diğer") end
		if event.xp > 0 then table.insert(texts, "+" .. event.xp .. " XP") end
		if event.gold > 0 then table.insert(texts, "+" .. event.gold .. " altın") end
		detail.Text = #texts > 0 and table.concat(texts, " · ") or "Yolculuğun sürüyor."
		heading.TextColor3 = (kind == "level" or kind == "discovery") and colors.teal or colors.gold
		border.Color = heading.TextColor3
	end
	function self:resize(viewport)
		if disposed then return end
		local w, h = viewport.X, viewport.Y
		if w < 480 then
			-- The empty strip beside the compact quest HUD; toast stays at y12.
			card.Size, card.AnchorPoint = UDim2.fromOffset(math.clamp(w - 196, 100, 180), 84), Vector2.new(1, 0)
			card.Position = UDim2.new(1, -12, 0, 104)
			heading.Position, heading.Size, heading.TextSize = UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0, 36), 12
			detail.Position, detail.Size, detail.TextSize = UDim2.fromOffset(8, 42), UDim2.new(1, -16, 0, 36), 10
			heading.TextWrapped, detail.TextWrapped = true, true
		elseif w < 900 or h < 450 then
			-- Between left stats and right events, above the menu and hotbar.
			local base = math.clamp(math.min(w / 900, h / 680), 0.58, 1)
			local eventScale = math.clamp(math.min(w / 780, h / 650), 0.54, 1)
			local left, right = 22 + 270 * base, w - 22 - 290 * eventScale
			card.Size, card.AnchorPoint = UDim2.fromOffset(math.max(100, math.min(210, right - left)), 34), Vector2.new(0.5, 0)
			card.Position = UDim2.fromOffset((left + right) / 2, 88)
			heading.Position, heading.Size, heading.TextSize = UDim2.fromOffset(8, 0), UDim2.new(1, -16, 0, 17), 11
			detail.Position, detail.Size, detail.TextSize = UDim2.fromOffset(8, 17), UDim2.new(1, -16, 0, 16), 10
			heading.TextWrapped, detail.TextWrapped = false, false
		else
			card.Size, card.AnchorPoint, card.Position = UDim2.fromOffset(280, 64), Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 92)
			heading.Position, heading.Size, heading.TextSize = UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 22), 14
			detail.Position, detail.Size, detail.TextSize = UDim2.fromOffset(10, 27), UDim2.new(1, -20, 0, 32), 11
			heading.TextWrapped, detail.TextWrapped = true, true
		end
		heading.TextTruncate, detail.TextTruncate = Enum.TextTruncate.AtEnd, Enum.TextTruncate.AtEnd
	end
	function self:isVisible()
		return not disposed and (current ~= nil or #pending > 0)
	end
	function self:setState(state)
		if disposed then return end
		local event = Rules.observe(tracker, state)
		if not event then return end
		if current and current.kind == event.kind and not fadeEnd and expires - os.clock() > 0.8 then
			current = merge(current, event)
			render(current)
			return
		end
		for index, item in ipairs(pending) do
			if item.kind == event.kind then pending[index] = merge(item, event); return end
		end
		if #pending == 3 then
			-- Preserve important outcomes; fold the weakest batch's gains into one card.
			local weakest = #pending
			if priority[event.kind] > priority[pending[weakest].kind] then
				event = merge(event, table.remove(pending, weakest))
			else pending[weakest] = merge(pending[weakest], event); return end
		end
		table.insert(pending, event)
		table.sort(pending, function(a, b) return priority[a.kind] > priority[b.kind] end)
	end
	local destroyConnection, ancestryConnection
	function self:destroy()
		if disposed then return end
		disposed = true
		if tween then tween:Cancel() end
		if destroyConnection then destroyConnection:Disconnect() end
		if ancestryConnection then ancestryConnection:Disconnect() end
		table.clear(pending)
		current, tracker = nil, nil
		card:Destroy()
	end
	destroyConnection = gui.Destroying:Connect(function() self:destroy() end)
	ancestryConnection = gui.AncestryChanged:Connect(function() if not gui.Parent then self:destroy() end end)
	self:resize(gui.AbsoluteSize)
	task.spawn(function()
		while not disposed and gui.Parent do
			local now = os.clock()
			if not current and #pending > 0 then
				current = table.remove(pending, 1)
				render(current)
				card.Visible, card.GroupTransparency = true, 1
				expires, fadeEnd = now + 3.2, nil
				tween = TweenService:Create(card, TweenInfo.new(0.18), {GroupTransparency = 0})
				tween:Play()
			elseif current and not fadeEnd and now >= expires then
				fadeEnd = now + 0.22
				tween = TweenService:Create(card, TweenInfo.new(0.22), {GroupTransparency = 1})
				tween:Play()
			elseif fadeEnd and now >= fadeEnd then card.Visible = false; current, fadeEnd = nil, nil end
			task.wait(0.1)
		end
		self:destroy()
	end)
	return self
end
return Feedback
