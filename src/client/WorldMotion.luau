-- Bounded client-only presentation. Never move a rig root or change combat state.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Motion = {}
local sessions = setmetatable({}, {__mode = "k"})
local RIG_LIMIT, RIG_RANGE = 24, 160
local CRYSTAL_LIMIT, CRYSTAL_RANGE = 12, 120
local FRAME = 1 / 25
local JOINTS = {
	["Left Shoulder"] = {side = -1, arm = true}, ["Right Shoulder"] = {side = 1, arm = true},
	["Left Hip"] = {side = 1, arm = false}, ["Right Hip"] = {side = -1, arm = false},
}

function Motion.start(gui)
	if sessions[gui] then sessions[gui]() end
	local active = true
	local rigs, crystals, connections = {}, {}, {}
	local bases = setmetatable({}, {__mode = "k"})
	local accumulated, scanAt = 0, 0
	local function restoreRig(state)
		for _, entry in state.joints do
			if entry.motor.Parent then entry.motor.Transform = CFrame.identity end
		end
	end
	local function restoreCrystal(part, state)
		if part.Parent then part.CFrame = state.base end
	end
	local function clearVisuals()
		for model, state in rigs do restoreRig(state); rigs[model] = nil end
		for part, state in crystals do restoreCrystal(part, state); crystals[part] = nil end
	end
	local function stop()
		if not active then return end
		active = false
		for _, connection in connections do connection:Disconnect() end
		table.clear(connections)
		clearVisuals()
		table.clear(bases)
		sessions[gui] = nil
	end
	sessions[gui] = stop
	local function origin()
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return root and root.Position
	end
	local function rescan(position)
		local world = workspace:FindFirstChild("AetheriaWorld")
		local enemyFolder = world and world:FindFirstChild("Enemies")
		local candidates = {}
		if enemyFolder then
			for _, model in enemyFolder:GetChildren() do
				if not model:IsA("Model") or model:GetAttribute("AetheriaEnemy") ~= true then continue end
				local root = model:FindFirstChild("HumanoidRootPart")
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 then
					local distance = (root.Position - position).Magnitude
					if distance <= RIG_RANGE then table.insert(candidates, {model = model, root = root, humanoid = humanoid, distance = distance}) end
				end
			end
		end
		table.sort(candidates, function(a, b) return a.distance < b.distance end)
		local keep = {}
		for index = 1, math.min(RIG_LIMIT, #candidates) do
			local entry = candidates[index]
			keep[entry.model] = true
			local state = rigs[entry.model]
			if state and (state.root ~= entry.root or state.humanoid ~= entry.humanoid) then restoreRig(state); state = nil end
			if not state then
				state = {root = entry.root, humanoid = entry.humanoid, phase = index * 0.7, weight = 0, joints = {}}
				for _, joint in entry.model:GetDescendants() do
					local definition = JOINTS[joint.Name]
					if definition and joint:IsA("Motor6D") then
						table.insert(state.joints, {motor = joint, side = definition.side, arm = definition.arm})
					end
				end
				rigs[entry.model] = state
			end
		end
		for model, state in rigs do
			if not keep[model] then restoreRig(state); rigs[model] = nil end
		end

		-- Crystals are selected as complete same-position pairs. Their original
		-- transforms are cached, never recaptured from an already animated frame.
		local landmarks = world and world:FindFirstChild("WorldLandmarks")
		local pairsByPosition = {}
		if landmarks then
			for _, part in landmarks:GetDescendants() do
				if not part:IsA("BasePart") or (part.Name ~= "FacetedCrystal" and part.Name ~= "CrystalHeart")
					or not part.Anchored or part.CanCollide or part.CanQuery or part.CanTouch then continue end
				local base = bases[part] or part.CFrame
				bases[part] = base
				local distance = (base.Position - position).Magnitude
				if distance > CRYSTAL_RANGE then continue end
				local p = base.Position
				local key = string.format("%.3f:%.3f:%.3f", p.X, p.Y, p.Z)
				local pair = pairsByPosition[key]
				if not pair then pair = {distance = distance, parts = {}, phase = (p.X * 0.071 + p.Z * 0.043) % (math.pi * 2)}; pairsByPosition[key] = pair end
				table.insert(pair.parts, {part = part, base = base})
			end
		end
		local pairs = {}
		for _, pair in pairsByPosition do table.insert(pairs, pair) end
		table.sort(pairs, function(a, b) return a.distance < b.distance end)
		local crystalKeep, budget = {}, 0
		for _, pair in pairs do
			if budget + #pair.parts > CRYSTAL_LIMIT then continue end
			for _, entry in pair.parts do
				crystalKeep[entry.part] = true
				crystals[entry.part] = {base = entry.base, phase = pair.phase}
				budget += 1
			end
		end
		for part, state in crystals do
			if not crystalKeep[part] then restoreCrystal(part, state); crystals[part] = nil end
		end
	end
	table.insert(connections, gui.Destroying:Connect(stop))
	table.insert(connections, gui.AncestryChanged:Connect(function() if not gui.Parent then stop() end end))
	table.insert(connections, RunService.PreSimulation:Connect(function(dt)
		if not active then return end
		accumulated += dt
		if accumulated < FRAME then return end
		local step = math.min(accumulated, 0.1)
		accumulated %= FRAME
		local position = origin()
		if not position then clearVisuals(); return end
		local time = os.clock()
		if time >= scanAt then rescan(position); scanAt = time + 0.75 end
		for model, state in rigs do
			local root, humanoid = state.root, state.humanoid
			if not model:IsDescendantOf(workspace) or not root.Parent or not humanoid.Parent or humanoid.Health <= 0
				or (root.Position - position).Magnitude > RIG_RANGE then
				restoreRig(state); rigs[model] = nil; continue
			end
			local velocity = root.AssemblyLinearVelocity
			local speed = math.max(Vector3.new(velocity.X, 0, velocity.Z).Magnitude, humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed)
			local targetWeight = math.clamp(speed / 10, 0, 1)
			state.weight += (targetWeight - state.weight) * math.min(1, step * 10)
			state.phase += step * (2 + math.min(speed, 20) * 0.4)
			local swing = math.sin(state.phase) * 0.55 * state.weight
			for _, entry in state.joints do
				if entry.motor.Parent then
					local idle = if entry.arm then math.sin(time * 1.4 + state.phase * 0.03) * 0.025 * (1 - state.weight) else 0
					entry.motor.Transform = CFrame.Angles(swing * entry.side + idle, 0, if entry.arm then entry.side * 0.025 else 0)
				end
			end
		end
		for part, state in crystals do
			if not part:IsDescendantOf(workspace) or (state.base.Position - position).Magnitude > CRYSTAL_RANGE then
				restoreCrystal(part, state); crystals[part] = nil; continue
			end
			local bob = math.sin(time * 1.3 + state.phase) * 0.16
			local spin = time * 0.16 + state.phase * 0.08
			part.CFrame = CFrame.new(state.base.Position + Vector3.new(0, bob, 0)) * CFrame.Angles(0, spin, 0) * state.base.Rotation
		end
	end))
	return stop
end
return Motion
