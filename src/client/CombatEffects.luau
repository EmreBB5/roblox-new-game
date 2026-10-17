-- Server-accepted actions only; these parts never participate in combat.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local CombatEffects = {}
function CombatEffects.start(remote)
	local folder = Instance.new("Folder")
	folder.Name = "LocalCombatEffects"
	folder.Parent = workspace
	local function part(shape, color, size, cf, lifetime)
		local item = Instance.new("Part")
		item.Shape = shape
		item.Color = color
		item.Material = Enum.Material.Neon
		item.Anchored = true
		item.CanCollide, item.CanQuery, item.CanTouch = false, false, false
		item.CastShadow = false
		item.Size, item.CFrame = size, cf
		item.Parent = folder
		TweenService:Create(item, TweenInfo.new(lifetime), { Transparency = 1 }):Play()
		Debris:AddItem(item, lifetime)
		return item
	end
	remote.OnClientEvent:Connect(function(effect)
		if type(effect) ~= "table" or typeof(effect.origin) ~= "Vector3" then return end
		local camera = workspace.CurrentCamera
		if not camera or (camera.CFrame.Position - effect.origin).Magnitude > 240 then return end
		local origin = effect.origin + Vector3.new(0, 1, 0)
		local kind = string.lower(tostring(effect.kind))
		local caster = type(effect.userId) == "number" and Players:GetPlayerByUserId(effect.userId)
		local character = caster and caster.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local forward = root and root.CFrame.LookVector or camera.CFrame.LookVector
		local target = typeof(effect.target) == "Vector3" and effect.target or origin + forward * 6
		if kind == "heal" then
			local glow = part(Enum.PartType.Ball, Color3.fromRGB(112, 244, 161), Vector3.new(3, 3, 3), CFrame.new(origin), 0.5)
			glow.Transparency = 0.55
			TweenService:Create(glow, TweenInfo.new(0.5), { Size = Vector3.new(6, 6, 6), Transparency = 1 }):Play()
		elseif kind == "nova" or (kind == "area" and string.find(tostring(effect.abilityId), "mage")) then
			local radius = math.clamp(tonumber(effect.radius) or 16, 1, 40)
			local ring = part(Enum.PartType.Cylinder, Color3.fromRGB(151, 130, 255), Vector3.new(0.2, 1, 1), CFrame.new(origin - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), 0.45)
			TweenService:Create(ring, TweenInfo.new(0.45), { Size = Vector3.new(0.2, radius * 2, radius * 2), Transparency = 1 }):Play()
		elseif kind == "bolt" or kind == "ranged" or kind == "projectile" then
			local distance = math.min((target - origin).Magnitude, 100)
			if distance < 0.1 then return end
			local direction = (target - origin).Unit
			local center = origin + direction * distance / 2
			part(Enum.PartType.Block, Color3.fromRGB(104, 207, 255), Vector3.new(0.25, 0.25, distance), CFrame.lookAt(center, center + direction), 0.2)
		else
			local aim = (target - origin)
			local facing = aim.Magnitude > 0.1 and CFrame.lookAt(origin, target) or CFrame.new(origin)
			for index = -2, 2 do
				part(Enum.PartType.Block, Color3.fromRGB(255, 221, 140), Vector3.new(0.15, 0.35, 2.2), facing * CFrame.Angles(0, index * 0.24, -0.5) * CFrame.new(0, 0, -3), 0.18)
			end
		end
	end)
end
return CombatEffects
