-- Cosmetic casts and personal confirmed impacts share one bounded, local part pool.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Effects = {}
local sessions = setmetatable({}, {__mode = "k"})
local GOLD = Color3.fromRGB(255, 216, 137)
local ARCANE = Color3.fromRGB(123, 216, 255)
local VIOLET = Color3.fromRGB(178, 150, 255)
local JADE = Color3.fromRGB(125, 249, 183)
local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function vector(value)
	return typeof(value) == "Vector3" and finite(value.X) and finite(value.Y) and finite(value.Z)
		and math.max(math.abs(value.X), math.abs(value.Y), math.abs(value.Z)) < 1e7
end
function Effects.start(castRemote, hitRemote, gui)
	if sessions[gui] then sessions[gui]() end
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "LocalCombatEffects", workspace
	local active, count = true, 0
	local live, connections = {}, {}
	local function clear()
		folder:ClearAllChildren()
		table.clear(live)
		count = 0
	end
	local function stop()
		if not active then return end
		active = false
		for _, connection in ipairs(connections) do connection:Disconnect() end
		clear()
		folder:Destroy()
		sessions[gui] = nil
	end
	sessions[gui] = stop
	local function piece(shape, color, size, cf, duration, transparency)
		if not active or count >= 100 then return nil end
		local item = Instance.new("Part")
		item.Shape, item.Color, item.Material = shape, color, Enum.Material.Neon
		item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch, item.CastShadow = true, false, false, false, false
		item.Size, item.CFrame, item.Transparency = size, cf, transparency or 0.1
		live[item], count = true, count + 1
		item.Destroying:Once(function()
			if live[item] then live[item] = nil; count -= 1 end
		end)
		item.Parent = folder
		TweenService:Create(item, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		Debris:AddItem(item, duration + 0.05)
		return item
	end
	local function move(item, duration, properties)
		if item then TweenService:Create(item, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play() end
	end
	local function ring(center, radius, color, duration, segments)
		segments = segments or 12
		for index = 1, segments do
			local angle = index * math.pi * 2 / segments
			local offset = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local rotation = CFrame.Angles(0, -angle, 0)
			local length = math.max(0.15, radius * math.pi * 2 / segments * 0.65)
			local item = piece(Enum.PartType.Block, color, Vector3.new(0.12, 0.1, length * 0.3), CFrame.new(center + offset * radius * 0.25) * rotation, duration, 0.2)
			move(item, duration, {CFrame = CFrame.new(center + offset * radius) * rotation, Size = Vector3.new(0.08, 0.08, length)})
		end
	end
	local function sparks(center, color, amount, reach, duration)
		for index = 1, amount do
			local angle = index * 2.399963
			local offset = Vector3.new(math.cos(angle), 0.35 + (index % 3) * 0.28, math.sin(angle))
			local item = piece(Enum.PartType.Ball, color, Vector3.new(0.16, 0.16, 0.16), CFrame.new(center), duration)
			move(item, duration, {Position = center + offset * reach, Size = Vector3.new(0.03, 0.03, 0.03)})
		end
	end
	local function allowed(position, range)
		local camera = workspace.CurrentCamera
		return active and vector(position) and camera and (camera.CFrame.Position - position).Magnitude <= range
	end
	local function slash(origin, target, wide, radius)
		local direction = target - origin
		if direction.Magnitude < 0.1 then return end
		local facing = CFrame.lookAt(origin, target)
		local segments = wide and 12 or 8
		for index = 1, segments do
			local angle = -0.95 + index / segments * 1.9
			local cf = facing * CFrame.Angles(0, angle, -0.25) * CFrame.new(0, 0, -(wide and 4.8 or 3.2))
			local item = piece(Enum.PartType.Block, GOLD, Vector3.new(0.13, 0.4, wide and 1.4 or 0.9), cf, 0.24)
			move(item, 0.24, {CFrame = cf * CFrame.new(0, 0.2, -0.7)})
		end
		if wide then ring(origin - Vector3.new(0, 2.7, 0), radius, GOLD, 0.36, 10) end
	end
	local function projectile(origin, target, empowered)
		local direction = target - origin
		local distance = direction.Magnitude
		if distance < 0.1 then return end
		if distance > 100 then target = origin + direction.Unit * 100; distance = 100 end
		local duration = math.clamp(distance / 150, 0.1, 0.4)
		local facing = CFrame.lookAt(origin, target)
		local thickness = empowered and 0.45 or 0.25
		-- An immediate thin tracer connects an instant server cast while its
		-- decorative core travels; this does not imply a confirmed impact.
		piece(Enum.PartType.Block, ARCANE, Vector3.new(0.07, 0.07, distance), CFrame.lookAt((origin + target) / 2, target), 0.12, 0.55)
		local core = piece(Enum.PartType.Ball, ARCANE, Vector3.new(thickness, thickness, thickness) * 2, facing, duration)
		move(core, duration, {Position = target})
		for _, side in {-1, 1} do
			local ribbon = piece(Enum.PartType.Block, empowered and VIOLET or ARCANE, Vector3.new(0.08, 0.08, math.min(distance, 4)), facing * CFrame.new(side * 0.25, 0, 0), duration, 0.25)
			move(ribbon, duration, {CFrame = CFrame.lookAt(target + facing.RightVector * side * 0.25, target + direction.Unit * 2)})
		end
		if empowered then ring(origin - Vector3.new(0, 2.7, 0), 2, ARCANE, 0.3, 6) end
	end
	table.insert(connections, castRemote.OnClientEvent:Connect(function(effect)
		if type(effect) ~= "table" or not allowed(effect.origin, 220) or type(effect.kind) ~= "string" then return end
		local origin = effect.origin + Vector3.new(0, 1, 0)
		local caster = finite(effect.userId) and Players:GetPlayerByUserId(effect.userId)
		local character = caster and caster.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera
		local forward = root and root.CFrame.LookVector or camera.CFrame.LookVector
		local target = vector(effect.target) and effect.target or origin + forward * 6
		local kind = effect.kind
		if kind == "heal" then
			ring(origin - Vector3.new(0, 2.7, 0), 4, JADE, 0.65, 10)
			for index = 1, 6 do
				local angle = index * math.pi / 3
				local position = origin + Vector3.new(math.cos(angle) * 1.6, -1, math.sin(angle) * 1.6)
				local mote = piece(Enum.PartType.Ball, JADE, Vector3.new(0.25, 0.25, 0.25), CFrame.new(position), 0.7)
				move(mote, 0.7, {Position = position + Vector3.new(0, 3.5, 0)})
			end
		elseif kind == "nova" or (kind == "area" and effect.classId == "mage") then
			local radius = finite(effect.radius) and math.clamp(effect.radius, 1, 40) or 17
			local ground = origin - Vector3.new(0, 2.7, 0)
			ring(ground, radius, VIOLET, 0.5, 16)
			ring(ground + Vector3.new(0, 0.14, 0), radius * 0.55, ARCANE, 0.65, 8)
			sparks(origin, VIOLET, 6, 2, 0.45)
		elseif kind == "bolt" or kind == "ranged" or kind == "projectile" then
			projectile(origin, target, effect.abilityId == "mage_primary")
		elseif kind == "basic" or kind == "area" then
			slash(origin, target, kind == "area", finite(effect.radius) and math.clamp(effect.radius, 1, 40) or 12)
		end
	end))
	-- Impacts require the private server-observed HP delta; casts never invent hits.
	table.insert(connections, hitRemote.OnClientEvent:Connect(function(hit)
		if type(hit) ~= "table" or (hit.kind ~= "damage" and hit.kind ~= "heal") or not finite(hit.amount)
			or hit.amount <= 0 or hit.amount > 1e6 or not allowed(hit.position, 180) then return end
		local position = hit.position + Vector3.new(0, 0.3, 0)
		if hit.kind == "heal" then sparks(position, JADE, 4, 1.5, 0.45)
		else
			local flash = piece(Enum.PartType.Ball, GOLD, Vector3.new(0.45, 0.45, 0.45), CFrame.new(position), 0.16, 0.35)
			move(flash, 0.16, {Size = Vector3.new(1.5, 1.5, 1.5)})
			sparks(position, GOLD, 5, 1.4, 0.28)
		end
	end))
	table.insert(connections, Players.LocalPlayer.CharacterRemoving:Connect(clear))
	table.insert(connections, Players.LocalPlayer.CharacterAdded:Connect(clear))
	table.insert(connections, gui.Destroying:Connect(stop))
	table.insert(connections, gui.AncestryChanged:Connect(function() if not gui.Parent then stop() end end))
	return stop
end
return Effects
