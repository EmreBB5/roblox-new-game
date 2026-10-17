local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Progression = require(ReplicatedStorage.Shared.Progression)
local ProfileStore = require(script.Parent.ProfileStore)
local World = require(script.Parent.World)
local world = World.build()
local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "AetheriaRemotes"
remoteFolder.Parent = ReplicatedStorage
local remotes = {}
for _, name in {"Attack", "State", "RequestState", "Notify"} do
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remoteFolder
	remotes[name] = event
end
local profiles = {}
local lastAttack = {}
local lastRequest = {}
local lastPrompt = {}
local movement = {}
local enemies = {}
local closing = false

local function state(player)
	local handle = profiles[player]
	if not handle or not player.Parent then return end
	local p = handle.data
	remotes.State:FireClient(player, {
		level = p.level, xp = p.xp, xpNeeded = Progression.xpNeeded(p.level),
		gold = p.gold, kills = p.kills, questStatus = p.questStatus,
		questKills = p.questKills, questTarget = Config.QuestTarget,
		hasCrystal = p.hasCrystal, saveStatus = handle.status,
	})
end
local function livingCharacter(player)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if root and humanoid and humanoid.Health > 0 then return root, humanoid end
	return nil, nil
end
local function isSafe(position)
	local delta = position - world.SafeZoneCenter
	return Vector3.new(delta.X, 0, delta.Z).Magnitude <= world.SafeZoneRadius
end
local function trustedPosition(player, root)
	local check = movement[player]
	return check and os.clock() >= check.blockedUntil and (root.Position - check.position).Magnitude < 12
end

remotes.RequestState.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) ~= 0 then return end
	local now = os.clock()
	if now - (lastRequest[player] or 0) < 0.5 then return end
	lastRequest[player] = now
	state(player)
end)

remotes.Attack.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) ~= 0 or not profiles[player] then return end
	local now = os.clock()
	if now - (lastAttack[player] or 0) < Config.AttackCooldown then return end
	lastAttack[player] = now
	local root = livingCharacter(player)
	if not root or not trustedPosition(player, root) or isSafe(root.Position) then return end
	local nearest, distance = nil, Config.AttackRange
	for model, info in enemies do
		local enemyRoot = model:FindFirstChild("HumanoidRootPart")
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if enemyRoot and humanoid and humanoid.Health > 0 then
			local candidate = (enemyRoot.Position - root.Position).Magnitude
			if candidate <= distance then nearest, distance = model, candidate end
		end
	end
	if nearest then
		local targetRoot = nearest.HumanoidRootPart
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {player.Character}
		local hit = workspace:Raycast(root.Position, targetRoot.Position - root.Position, params)
		if hit and not hit.Instance:IsDescendantOf(nearest) then return end
		enemies[nearest].lastAttacker = player
		nearest.Humanoid:TakeDamage(Config.AttackDamage)
	end
end)

world.QuestPrompt.Triggered:Connect(function(player)
	local handle = profiles[player]
	local root = livingCharacter(player)
	local now = os.clock()
	if not handle or not root or not trustedPosition(player, root) then return end
	if now - (lastPrompt[player] or 0) < 1 then return end
	if (root.Position - world.QuestGiver:GetPivot().Position).Magnitude > world.QuestPrompt.MaxActivationDistance + 3 then return end
	lastPrompt[player] = now
	local result = Progression.interact(handle.data, Config)
	local messages = {started = "Görev alındı: 3 orman canavarını yen!", active = "Ormandaki canavarları yen ve geri dön.",
		completed = "Görev tamamlandı! +75 XP, +25 altın ve bir kristal."}
	remotes.Notify:FireClient(player, messages[result])
	state(player)
end)

local function spawnEnemy(position, index)
	if closing then return end
	local model = World.createEnemy(world.EnemyFolder, position, index)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then model:Destroy() return end
	humanoid.MaxHealth = Config.EnemyHealth
	humanoid.Health = Config.EnemyHealth
	humanoid.WalkSpeed = Config.EnemyWalkSpeed
	root:SetNetworkOwner(nil)
	local info = {spawn = position, lastAttack = 0, lastAttacker = nil}
	enemies[model] = info
	humanoid.Died:Connect(function()
		enemies[model] = nil
		local player = info.lastAttacker
		if player and profiles[player] then
			Progression.recordKill(profiles[player].data, Config)
			state(player)
			if profiles[player].data.questStatus == "return" then
				remotes.Notify:FireClient(player, "Hedef tamamlandı! Köydeki bilgeye dön.")
			end
		end
		task.delay(3, function() model:Destroy() end)
		task.delay(Config.EnemyRespawnSeconds, function() spawnEnemy(position, index) end)
	end)
end
for index, position in world.EnemySpawns do spawnEnemy(position, index) end

task.spawn(function()
	while not closing do
		task.wait(0.25)
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local root = livingCharacter(player)
			if root then
				local previous = movement[player]
				if previous then
					local delta = root.Position - previous.position
					local horizontal = Vector3.new(delta.X, 0, delta.Z).Magnitude
					if horizontal > Config.MaxTravelSpeed * (now - previous.time) + 8 then
						root.CFrame = CFrame.new(previous.position)
						root.AssemblyLinearVelocity = Vector3.zero
						previous.blockedUntil = now + 1
					end
					previous.position, previous.time = root.Position, now
				else
					movement[player] = {position = root.Position, time = now, blockedUntil = now + 0.5}
				end
			else movement[player] = nil end
		end
		for model, info in enemies do
			local root = model:FindFirstChild("HumanoidRootPart")
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid or humanoid.Health <= 0 then continue end
			local targetRoot, targetHumanoid = nil, nil
			local distance = Config.EnemyAggroRange
			if (root.Position - info.spawn).Magnitude < Config.EnemyAggroRange * 1.5 then
				for _, player in Players:GetPlayers() do
					local candidate, candidateHumanoid = livingCharacter(player)
					if candidate and profiles[player] and not isSafe(candidate.Position) and trustedPosition(player, candidate) then
						local candidateDistance = (candidate.Position - root.Position).Magnitude
						if candidateDistance < distance then targetRoot, targetHumanoid, distance = candidate, candidateHumanoid, candidateDistance end
					end
				end
			end
			if targetRoot then
				humanoid:MoveTo(targetRoot.Position)
				if distance <= Config.EnemyAttackRange and now - info.lastAttack >= Config.EnemyAttackCooldown then
					info.lastAttack = now
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Exclude
					params.FilterDescendantsInstances = {model}
					local hit = workspace:Raycast(root.Position, targetRoot.Position - root.Position, params)
					if not hit or hit.Instance:IsDescendantOf(targetRoot.Parent) then
						targetHumanoid:TakeDamage(Config.EnemyDamage)
					end
				end
			else humanoid:MoveTo(info.spawn) end
		end
	end
end)

local function characterAdded(player, character)
	movement[player] = nil
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then humanoid.WalkSpeed = Config.PlayerWalkSpeed end
	local hand = character:WaitForChild("RightHand", 3) or character:FindFirstChild("Right Arm")
	if hand and hand:IsA("BasePart") then
		for _, spec in {
			{name = "SwordGrip", size = Vector3.new(0.3, 1.2, 0.3), offset = CFrame.new(0, -0.6, 0), color = Color3.fromRGB(100, 65, 35)},
			{name = "SwordBlade", size = Vector3.new(0.45, 3.2, 0.18), offset = CFrame.new(0, -2.5, 0), color = Color3.fromRGB(190, 220, 240)},
		} do
			local part = Instance.new("Part")
			part.Name, part.Size, part.Color = spec.name, spec.size, spec.color
			part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, true
			part.CFrame = hand.CFrame * spec.offset
			part.Parent = character
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = hand, part, part
		end
	end
	state(player)
end
local function playerAdded(player)
	player.CharacterAdded:Connect(function(character) characterAdded(player, character) end)
	if player.Character then task.spawn(characterAdded, player, player.Character) end
	local handle = ProfileStore.load(player)
	if not handle then
		player:Kick("İlerlemen güvenle yüklenemedi. Lütfen biraz sonra tekrar katıl.")
		return
	end
	if not player.Parent then ProfileStore.save(player, true) return end
	profiles[player] = handle
	state(player)
end
Players.PlayerAdded:Connect(playerAdded)
for _, player in Players:GetPlayers() do task.spawn(playerAdded, player) end
Players.PlayerRemoving:Connect(function(player)
	profiles[player] = nil
	movement[player], lastAttack[player], lastRequest[player], lastPrompt[player] = nil, nil, nil, nil
	ProfileStore.save(player, true)
end)
task.spawn(function()
	while not closing do
		task.wait(45)
		for player in profiles do
			task.spawn(function()
				if not ProfileStore.save(player, false) and player.Parent then
					player:Kick("İlerlemen güvenle kaydedilemedi. Lütfen yeniden katıl.")
				end
				state(player)
			end)
		end
	end
end)
game:BindToClose(function()
	closing = true
	local pending = 0
	for player in profiles do
		pending += 1
		task.spawn(function() ProfileStore.save(player, true) pending -= 1 end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do task.wait(0.1) end
end)
