-- Viewer-local atmosphere and a bounded ambient particle field, never combat state.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local WorldMap = require(Shared:WaitForChild("WorldMap"))
local Ambience = {}
local styles = {
	village = {tint = Color3.fromRGB(255, 249, 233), color = Color3.fromRGB(239, 221, 193), density = 0.2, haze = 1, rate = 3, speed = 0.6, wind = Vector3.new(0.1, 0.35, 0), size = 0.1},
	forest = {tint = Color3.fromRGB(234, 255, 239), color = Color3.fromRGB(197, 222, 201), density = 0.25, haze = 1.4, rate = 7, speed = 0.7, wind = Vector3.new(0.25, 0.5, 0), size = 0.13},
	marsh = {tint = Color3.fromRGB(220, 244, 255), color = Color3.fromRGB(180, 208, 221), density = 0.29, haze = 1.8, rate = 6, speed = 0.45, wind = Vector3.new(0.5, 0.1, 0), size = 0.16},
	volcanic = {tint = Color3.fromRGB(255, 232, 220), color = Color3.fromRGB(230, 194, 172), density = 0.24, haze = 1.6, rate = 9, speed = 1.4, wind = Vector3.new(0.4, 1.5, 0.1), size = 0.12},
	frost = {tint = Color3.fromRGB(225, 244, 255), color = Color3.fromRGB(210, 231, 248), density = 0.24, haze = 1.3, rate = 13, speed = 1.2, wind = Vector3.new(0.8, -0.55, 0.15), size = 0.14},
	desert = {tint = Color3.fromRGB(255, 243, 218), color = Color3.fromRGB(242, 218, 179), density = 0.23, haze = 1.7, rate = 7, speed = 1, wind = Vector3.new(1.1, 0.05, 0.2), size = 0.09},
}
function Ambience.start(regionLabel)
	local stopLights = require(script.Parent:WaitForChild("LocalLightBudget")).start(regionLabel)
	local previous = Lighting:FindFirstChild("AetheriaBiomeTint")
	if previous then previous:Destroy() end
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name, correction.Parent = "AetheriaBiomeTint", Lighting
	local field = Instance.new("Part")
	field.Name, field.Size, field.Transparency = "AetheriaLocalAmbientField", Vector3.new(54, 12, 54), 1
	field.Anchored, field.CanCollide, field.CanTouch, field.CanQuery, field.CastShadow = true, false, false, false, false
	local motes = Instance.new("ParticleEmitter")
	motes.Name, motes.Texture = "BiomeMotes", "rbxasset://textures/particles/sparkles_main.dds"
	motes.Lifetime, motes.SpreadAngle = NumberRange.new(3, 5), Vector2.new(180, 180)
	motes.LightEmission, motes.LightInfluence, motes.Drag = 0.35, 0.4, 0.2
	motes.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.45), NumberSequenceKeypoint.new(0.8, 0.6), NumberSequenceKeypoint.new(1, 1)})
	motes.Enabled, motes.Rate, motes.Parent = false, 0, field
	field.Parent = workspace
	local active, transition, fogTransition, atmosphere, baseline = false, nil, nil, nil, nil
	local alive = true
	local function cleanup()
		if not alive then return end
		alive = false
		stopLights()
		if transition then transition:Cancel() end
		if fogTransition then fogTransition:Cancel() end
		if atmosphere and atmosphere.Parent and baseline then
			for name, value in pairs(baseline) do atmosphere[name] = value end
		end
		correction:Destroy()
		field:Destroy()
	end
	regionLabel.Destroying:Connect(cleanup)
	task.spawn(function()
		while alive and regionLabel.Parent do
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local id = root and WorldMap.regionAt(root.Position.X, root.Position.Z, Config) or nil
			local style = styles[id]
			motes.Enabled = style ~= nil and root ~= nil and humanoid ~= nil and humanoid.Health > 0
			if root then field.Position = root.Position + Vector3.new(0, id == "frost" and 10 or 1, 0) end
			if not atmosphere or not atmosphere.Parent then
				atmosphere = Lighting:FindFirstChild("AetheriaAtmosphere")
				if atmosphere then
					baseline = {Color = atmosphere.Color, Density = atmosphere.Density, Haze = atmosphere.Haze}
					active = false
				end
			end
			if id ~= active then
				active = id
				local region = Config.Regions[id]
				regionLabel.Text = id == "village" and "GÜVENLİ KÖY" or (region and (region.Name .. " • Sv." .. region.EnemyLevel) or "AETHERIA • ESKİ YOLLAR")
				if transition then transition:Cancel() end
				transition = TweenService:Create(correction, TweenInfo.new(2), {TintColor = style and style.tint or Color3.new(1, 1, 1), Contrast = region and 0.055 or 0.025, Saturation = id == "frost" and -0.05 or 0.045})
				transition:Play()
				if atmosphere and baseline then
					if fogTransition then fogTransition:Cancel() end
					fogTransition = TweenService:Create(atmosphere, TweenInfo.new(2.5), {Color = style and style.color or baseline.Color, Density = style and style.density or baseline.Density, Haze = style and style.haze or baseline.Haze})
					fogTransition:Play()
				end
				if style then
					motes:Clear()
					motes.Rate, motes.Speed, motes.Acceleration = style.rate, NumberRange.new(style.speed * 0.6, style.speed), style.wind
					motes.Color = ColorSequence.new(id == "volcanic" and Color3.fromRGB(255, 168, 85) or style.tint)
					motes.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.25, style.size), NumberSequenceKeypoint.new(1, 0)})
				else motes:Clear() end
			end
			task.wait(0.35)
		end
		cleanup()
	end)
end
return Ambience
