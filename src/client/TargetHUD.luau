-- Selection is a preference only. The server validates every combat request.
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TargetHUD = {}
local selected, highlight, blocked, started = nil, nil, function() return false end, false
local candidates, watches = {}, {}
local basicRange = 11
local function clear()
	selected = nil
	if highlight then highlight.Adornee = nil; highlight.Enabled = false end
end
local function valid(model)
	if typeof(model) ~= "Instance" or not model:IsA("Model") or not model:IsDescendantOf(workspace) or model:GetAttribute("AetheriaEnemy") ~= true then return false end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	local own = Players.LocalPlayer.Character
	local origin = own and own:FindFirstChild("HumanoidRootPart")
	local ownHumanoid = own and own:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") or not origin or not ownHumanoid or ownHumanoid.Health <= 0 then return false end
	local direction = root.Position - origin.Position
	local distance = direction.Magnitude
	if distance ~= distance or distance > 60 then return false end
	if distance > 0.01 then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {own}
		local result = workspace:Raycast(origin.Position, direction, params)
		if result and not result.Instance:IsDescendantOf(model) then return false end
	end
	return true, distance, humanoid
end
function TargetHUD.getTarget()
	if selected and valid(selected) then return selected end
	clear()
	return nil
end
function TargetHUD.cycle()
	if blocked() or UserInputService:GetFocusedTextBox() or GuiService.MenuIsOpen then return end
	local list = {}
	for model in pairs(candidates) do
		local ok, distance = valid(model)
		if ok then table.insert(list, {model = model, distance = distance}) end
	end
	table.sort(list, function(a, b)
		if a.distance == b.distance then return a.model:GetFullName() < b.model:GetFullName() end
		return a.distance < b.distance
	end)
	local index = 0
	for i, entry in ipairs(list) do
		if entry.model == selected then
			index = i
			break
		end
	end
	selected = list[index + 1] and list[index + 1].model or nil
	if highlight then highlight.Adornee = selected; highlight.Enabled = selected ~= nil end
end
function TargetHUD.setState(state)
	basicRange = state.stats and state.stats.basicRange or 11
end
function TargetHUD.getInfo()
	if not selected then return nil end
	local ok, distance, humanoid = valid(selected)
	if not ok then clear(); return nil end
	local kind = ({boss = "Boss", elite = "Seçkin"})[selected:GetAttribute("EnemyKind")]
		or ({targeted = "Menzilli", area = "Alan"})[selected:GetAttribute("EnemyBehavior")] or "Yaratık"
	return {name = selected.Name, kind = kind, health = math.ceil(humanoid.Health), maxHealth = math.ceil(humanoid.MaxHealth), distance = distance, inRange = distance <= basicRange}
end
function TargetHUD.start(gui, make, label, colors, isBlocked)
	if started then return end
	started, blocked = true, isBlocked
	local active, connections = true, {}
	highlight = Instance.new("Highlight")
	highlight.Name = "SelectedEnemy"
	highlight.FillColor, highlight.OutlineColor = colors.gold, Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.85
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	highlight.Parent = workspace
	local panel = make("Frame", {BackgroundColor3 = colors.panel, BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false, Active = false}, gui)
	make("UICorner", {CornerRadius = UDim.new(0, 9)}, panel)
	local name = label(panel, "", UDim2.fromOffset(8, 3), UDim2.new(1, -16, 0, 22), 12, colors.gold)
	name.TextWrapped, name.TextTruncate = false, Enum.TextTruncate.AtEnd
	local info = label(panel, "", UDim2.fromOffset(8, 25), UDim2.new(1, -16, 0, 30), 10)
	local track = make("Frame", {BackgroundColor3 = Color3.fromRGB(45, 54, 46), BorderSizePixel = 0, Position = UDim2.new(0, 8, 1, -9), Size = UDim2.new(1, -16, 0, 4)}, panel)
	local fill = make("Frame", {BackgroundColor3 = colors.health, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, track)
	local function watch(model)
		if not model:IsA("Model") or watches[model] then return end
		local function refresh() candidates[model] = model:GetAttribute("AetheriaEnemy") == true and true or nil end
		refresh()
		watches[model] = model:GetAttributeChangedSignal("AetheriaEnemy"):Connect(refresh)
	end
	for _, item in ipairs(workspace:GetDescendants()) do watch(item) end
	table.insert(connections, workspace.DescendantAdded:Connect(watch))
	table.insert(connections, workspace.DescendantRemoving:Connect(function(model)
		if watches[model] then watches[model]:Disconnect(); watches[model] = nil end
		candidates[model] = nil
		if model == selected then clear() end
	end))
	table.insert(connections, Players.LocalPlayer.CharacterRemoving:Connect(clear))
	ContextActionService:BindActionAtPriority("Aetheria_Target", function(_, inputState)
		if blocked() or UserInputService:GetFocusedTextBox() or GuiService.MenuIsOpen then return Enum.ContextActionResult.Pass end
		if inputState == Enum.UserInputState.Begin then TargetHUD.cycle() end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.Tab, Enum.KeyCode.ButtonR3)
	local function cleanup()
		if not active then return end
		active = false
		for _, connection in ipairs(connections) do connection:Disconnect() end
		for _, connection in pairs(watches) do connection:Disconnect() end
		table.clear(connections)
		table.clear(watches)
		table.clear(candidates)
		ContextActionService:UnbindAction("Aetheria_Target")
		clear()
		if highlight then highlight:Destroy(); highlight = nil end
		started, basicRange = false, 11
		blocked = function() return false end
		panel:Destroy()
	end
	table.insert(connections, gui.Destroying:Connect(cleanup))
	task.spawn(function()
		while active and gui.Parent do
			local model = TargetHUD.getTarget()
			local viewport = gui.AbsoluteSize
			local compact = UserInputService.TouchEnabled or viewport.X < 700 or viewport.Y < 450
			panel.Visible = model ~= nil and not compact and not blocked() and not GuiService.MenuIsOpen
			local portrait = viewport.X < 480
			panel.AnchorPoint = portrait and Vector2.new(1, 0) or Vector2.new(0.5, 0)
			panel.Position = portrait and UDim2.new(1, -12, 0, 12) or UDim2.new(0.5, 0, 0, 12)
			panel.Size = UDim2.fromOffset(portrait and 126 or 210, 68)
			if model then
				local ok, distance, humanoid = valid(model)
				if ok then
					name.Text = model.Name
					local kind = ({boss = "Boss", elite = "Seçkin"})[model:GetAttribute("EnemyKind")]
						or ({targeted = "Menzilli", area = "Alan"})[model:GetAttribute("EnemyBehavior")] or "Yaratık"
					info.Text = string.format("%s • %.0f stud%s\nCan %d / %d", kind, distance, distance > basicRange and " • Uzak" or "", math.ceil(humanoid.Health), math.ceil(humanoid.MaxHealth))
					fill.Size = UDim2.fromScale(math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1), 1)
				end
			end
			task.wait(0.15)
		end
	end)
	return cleanup
end
return TargetHUD
