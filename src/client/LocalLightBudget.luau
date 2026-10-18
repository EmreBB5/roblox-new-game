-- Only nearby world lights render on this client; server illumination state is untouched.
local Players = game:GetService("Players")
local Budget = {}
local sessions = setmetatable({}, {__mode = "k"})
function Budget.start(owner)
	if sessions[owner] then sessions[owner]() end
	local active, world = true, nil
	local lights = {}
	local added, removing
	local function restore(light, enabled)
		if light.Parent then light.Enabled = enabled end
	end
	local function clear()
		if added then added:Disconnect(); added = nil end
		if removing then removing:Disconnect(); removing = nil end
		for light, enabled in pairs(lights) do restore(light, enabled) end
		table.clear(lights)
	end
	local function track(item)
		if item:IsA("PointLight") and lights[item] == nil then
			lights[item] = item.Enabled
			item.Enabled = false
		end
	end
	local function stop()
		if not active then return end
		active = false
		clear()
		sessions[owner] = nil
	end
	sessions[owner] = stop
	local destroying = owner.Destroying:Connect(stop)
	task.spawn(function()
		while active and owner.Parent do
			local current = workspace:FindFirstChild("AetheriaWorld")
			if current ~= world then
				clear()
				world = current
				if world then
					for _, item in ipairs(world:GetDescendants()) do track(item) end
					added = world.DescendantAdded:Connect(track)
					removing = world.DescendantRemoving:Connect(function(item)
						if lights[item] ~= nil then restore(item, lights[item]); lights[item] = nil end
					end)
				end
			end
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local camera = workspace.CurrentCamera
			local origin = root and root.Position or (camera and camera.CFrame.Position)
			local visible = {}
			for light, enabled in pairs(lights) do
				local parent = light.Parent
				if not parent then lights[light] = nil
				else
					local position = parent:IsA("BasePart") and parent.Position or (parent:IsA("Attachment") and parent.WorldPosition)
					local distance = origin and position and (position - origin).Magnitude or math.huge
					if enabled and distance <= 110 then table.insert(visible, {light = light, distance = distance}) end
				end
			end
			table.sort(visible, function(a, b) return a.distance < b.distance end)
			local selected = {}
			for index = 1, math.min(12, #visible) do selected[visible[index].light] = true end
			for light in pairs(lights) do
				if light.Parent then light.Enabled = selected[light] == true end
			end
			task.wait(0.7)
		end
		stop()
		destroying:Disconnect()
	end)
	return stop
end
return Budget
