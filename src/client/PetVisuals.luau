-- Cosmetic companions only. Streaming and missing characters are expected.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local colors = { mossling = Color3.fromRGB(135, 231, 155), tidefin = Color3.fromRGB(112, 205, 244), embercub = Color3.fromRGB(255, 159, 94) }
local PetVisuals = {}
function PetVisuals.start()
	local visuals = {}
	local characters = {}
	local folder = Instance.new("Folder")
	folder.Name = "LocalCompanions"
	folder.Parent = workspace
	local function remove(player)
		if visuals[player] then visuals[player]:Destroy(); visuals[player] = nil end
		characters[player] = nil
	end
	Players.PlayerRemoving:Connect(remove)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 1 / 30 then return end
		local step = elapsed
		elapsed = 0
		local own = Players.LocalPlayer.Character
		local origin = own and own:FindFirstChild("HumanoidRootPart")
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local id = player:GetAttribute("EquippedPet")
			if not root or not origin or not humanoid or humanoid.Health <= 0 or not colors[id] or (root.Position - origin.Position).Magnitude > 180 then
				remove(player)
			else
				local visual = visuals[player]
				if visual and (visual:GetAttribute("PetId") ~= id or characters[player] ~= character) then remove(player); visual = nil end
				if not visual then
					visual = Instance.new("Model")
					visual.Name = Config.Pets[id].Name
					visual:SetAttribute("PetId", id)
					characters[player] = character
					for index = 1, 3 do
						local part = Instance.new("Part")
						part.Name = index == 1 and "Core" or (id == "mossling" and "Leaf" or (id == "tidefin" and "Fin" or "Horn"))
						part.Shape = Enum.PartType.Ball
						local side = index == 2 and -1 or 1
						local offset = CFrame.identity
						if index == 1 then
							part.Size = id == "embercub" and Vector3.new(1.5, 1.1, 1.1) or Vector3.new(1.2, 1.4, 1.2)
						elseif id == "mossling" then
							part.Size = Vector3.new(0.45, 1.5, 0.8)
							offset = CFrame.new(side * 0.65, 0.9, 0) * CFrame.Angles(0, 0, math.rad(-side * 35))
						elseif id == "tidefin" then
							part.Size = Vector3.new(1.9, 0.25, 1)
							offset = CFrame.new(side * 1.05, 0.1, 0) * CFrame.Angles(0, 0, math.rad(side * 12))
						else
							part.Shape = Enum.PartType.Block
							part.Size = Vector3.new(0.3, 1.1, 0.3)
							offset = CFrame.new(side * 0.5, 0.8, -0.25) * CFrame.Angles(math.rad(-20), 0, math.rad(-side * 20))
						end
						part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
						part.CastShadow = false
						part.Material = Enum.Material.Neon
						part.Color = colors[id]
						part.CFrame = root.CFrame * offset
						part.Parent = visual
						if index == 1 then visual.PrimaryPart = part end
					end
					visual.Parent = folder
					visual:PivotTo(root.CFrame * CFrame.new(3, 1.5, 2))
					visuals[player] = visual
				end
				local target = root.CFrame * CFrame.new(3, 1.5 + math.sin(os.clock() * 3) * 0.35, 2)
				visual:PivotTo(visual:GetPivot():Lerp(target, 1 - math.exp(-7 * step)))
			end
		end
	end)
end
return PetVisuals
