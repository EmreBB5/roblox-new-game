-- Personal, server-confirmed combat numbers. Never infer damage from a cast.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CombatText = {}
local started = false
local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function CombatText.start(remote)
	if started then return end
	started = true
	local player = Players.LocalPlayer
	local folder = Instance.new("Folder")
	folder.Name = "LocalHitNumbers"
	folder.Parent = workspace
	local entries, sequence = {}, 0
	local function clear()
		folder:ClearAllChildren()
		table.clear(entries)
	end
	player.CharacterRemoving:Connect(clear)
	player.CharacterAdded:Connect(clear)
	remote.OnClientEvent:Connect(function(hit)
		if type(hit) ~= "table" or (hit.kind ~= "damage" and hit.kind ~= "heal") then return end
		if typeof(hit.position) ~= "Vector3" or not finite(hit.amount) or hit.amount <= 0 or hit.amount > 1e6 then return end
		local position = hit.position
		if not finite(position.X) or not finite(position.Y) or not finite(position.Z) then return end
		if math.max(math.abs(position.X), math.abs(position.Y), math.abs(position.Z)) > 1e7 then return end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local distance = (root.Position - position).Magnitude
		if not finite(distance) or distance > 180 then return end
		local amount = math.floor(hit.amount + 0.5)
		if amount == 0 then return end
		while #entries >= 30 do table.remove(entries, 1):Destroy() end
		sequence += 1
		local anchor = Instance.new("Part")
		anchor.Name = "CombatNumber"
		anchor.Anchored = true
		anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = false, false, false
		anchor.CastShadow = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.Position = position + Vector3.new((sequence % 3 - 1) * 0.35, 2.5, 0)
		anchor.Parent = folder
		table.insert(entries, anchor)
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "Value"
		billboard.Adornee = anchor
		billboard.Size = UDim2.fromOffset(100, 42)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = 180
		billboard.Active = false
		billboard.Parent = anchor
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Active = false
		text.Font = Enum.Font.GothamBold
		text.TextSize = 24
		text.Text = (hit.kind == "heal" and "+" or "") .. tostring(amount)
		text.TextColor3 = hit.kind == "heal" and Color3.fromRGB(123, 247, 160) or Color3.fromRGB(255, 229, 162)
		text.TextStrokeColor3 = Color3.fromRGB(30, 36, 31)
		text.TextStrokeTransparency = 0.35
		text.Parent = billboard
		TweenService:Create(anchor, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = anchor.Position + Vector3.new(0, 2, 0)}):Play()
		TweenService:Create(text, TweenInfo.new(0.8), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		Debris:AddItem(anchor, 1)
		task.delay(1, function()
			local index = table.find(entries, anchor)
			if index then table.remove(entries, index) end
		end)
	end)
end
return CombatText
