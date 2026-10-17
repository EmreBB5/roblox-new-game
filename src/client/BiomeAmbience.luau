-- Local atmosphere feedback follows the viewer without changing other players' lighting.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local WorldMap = require(Shared:WaitForChild("WorldMap"))
local Ambience = {}
function Ambience.start(regionLabel)
	local previous = Lighting:FindFirstChild("AetheriaBiomeTint")
	if previous then previous:Destroy() end
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "AetheriaBiomeTint"
	correction.Parent = Lighting
	local tints = {
		forest = Color3.fromRGB(237, 255, 242), marsh = Color3.fromRGB(224, 242, 255),
		volcanic = Color3.fromRGB(255, 231, 222), frost = Color3.fromRGB(224, 245, 255),
		desert = Color3.fromRGB(255, 243, 218),
	}
	local active, transition = false, nil
	task.spawn(function()
		while regionLabel.Parent do
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local id = root and WorldMap.regionAt(root.Position.X, root.Position.Z, Config) or nil
			if id ~= active then
				active = id
				local region = Config.Regions[id]
				regionLabel.Text = id == "village" and "GÜVENLİ KÖY" or (region and (region.Name .. " • Sv." .. region.EnemyLevel) or "AETHERIA • ESKİ YOLLAR")
				if transition then transition:Cancel() end
				transition = TweenService:Create(correction, TweenInfo.new(2), {TintColor = tints[id] or Color3.new(1, 1, 1), Contrast = region and 0.04 or 0, Saturation = id == "frost" and -0.08 or 0.02})
				transition:Play()
			end
			task.wait(0.5)
		end
		if transition then transition:Cancel() end
		correction:Destroy()
	end)
end
return Ambience
