-- Cosmetic companions only. Streaming and missing characters are expected.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local colors = { mossling = Color3.fromRGB(135, 231, 155), tidefin = Color3.fromRGB(112, 205, 244), embercub = Color3.fromRGB(255, 159, 94) }
local PetVisuals = {}
local function petLevel(value)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return 1 end
	return math.clamp(math.floor(value), 1, Config.PetProgression.MaxLevel)
end
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
			local level = petLevel(player:GetAttribute("PetLevel"))
			if not root or not origin or not humanoid or humanoid.Health <= 0 or not colors[id] or (root.Position - origin.Position).Magnitude > 180 then
				remove(player)
			else
				local visual = visuals[player]
				if visual and (visual:GetAttribute("PetId") ~= id or visual:GetAttribute("PetLevel") ~= level or characters[player] ~= character) then remove(player); visual = nil end
				if not visual then
					visual = Instance.new("Model")
					visual.Name = Config.Pets[id].Name
					visual:SetAttribute("PetId", id)
					visual:SetAttribute("PetLevel", level)
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
						part.Color = colors[id]:Lerp(Color3.new(1, 1, 1), (level - 1) * 0.025)
						part.CFrame = root.CFrame * offset
						part.Parent = visual
						if index == 1 then visual.PrimaryPart = part end
					end
					local function feature(name, size, offset, color, shape)
						local detail = Instance.new("Part")
						detail.Name, detail.Size, detail.Color = name, size, color
						detail.Shape, detail.Material = shape or Enum.PartType.Ball, Enum.Material.SmoothPlastic
						detail.Anchored, detail.CanCollide, detail.CanTouch, detail.CanQuery, detail.CastShadow = true, false, false, false, false
						detail.CFrame, detail.Parent = root.CFrame * CFrame.new(offset), visual
					end
					for _, side in {-1, 1} do
						feature("CompanionEye", Vector3.new(0.28, 0.3, 0.16), Vector3.new(side * 0.25, 0.2, -0.56), Color3.fromRGB(245, 255, 255))
						feature("CompanionPupil", Vector3.new(0.13, 0.19, 0.1), Vector3.new(side * 0.25, 0.2, -0.65), Color3.fromRGB(19, 43, 61))
						if id == "embercub" then
							for _, z in {-0.35, 0.35} do feature("CubPaw", Vector3.new(0.42, 0.4, 0.45), Vector3.new(side * 0.5, -0.5, z), colors[id]) end
						elseif id == "mossling" then
							feature("FlowerBud", Vector3.new(0.32, 0.4, 0.32), Vector3.new(side * 0.28, 0.9, 0), Color3.fromRGB(237, 225, 149))
						else
							feature("FinTip", Vector3.new(0.7, 0.15, 0.65), Vector3.new(side * 1.65, -0.05, 0.15), Color3.fromRGB(217, 244, 255))
						end
					end
					-- Level milestones add a segmented rune halo around the companion.
					if level >= 3 then
						local count = level >= 7 and 10 or 6
						for index = 1, count do
							local angle = index * math.pi * 2 / count
							local rune = Instance.new("Part")
							rune.Name = "GrowthRune"
							rune.Anchored, rune.CanCollide, rune.CanQuery, rune.CanTouch = true, false, false, false
							rune.CastShadow = false
							rune.Material = Enum.Material.Neon
							rune.Color = colors[id]:Lerp(Color3.fromRGB(255, 228, 159), 0.5)
							rune.Size = Vector3.new(0.15, 0.12, 0.4)
							rune.CFrame = root.CFrame * CFrame.new(math.cos(angle) * 1.1, -0.75, math.sin(angle) * 1.1) * CFrame.Angles(0, -angle, 0)
							rune.Parent = visual
						end
					end
					visual:ScaleTo(1 + (level - 1) * 0.04)
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
