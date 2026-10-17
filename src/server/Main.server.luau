local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Progression = require(ReplicatedStorage.Shared.Progression)
local ProfileStore = require(script.Parent.ProfileStore)
local World = require(script.Parent.World)
local Pets = require(ReplicatedStorage.Shared.Pets)
local Combat = require(ReplicatedStorage.Shared.Combat)
local Campaign = require(ReplicatedStorage.Shared.Campaign)
local PlayerActions = require(script.Parent.PlayerActions)
local BossService = require(script.Parent.BossService)
local PartyService = require(script.Parent.PartyService)
local TravelService = require(script.Parent.TravelService)
local PartyRules = require(ReplicatedStorage.Shared.PartyRules)
local PetGrowth = require(ReplicatedStorage.Shared.PetGrowth)
local EliteService = require(script.Parent.EliteService)
local world = World.build()
local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "AetheriaRemotes"
remoteFolder.Parent = ReplicatedStorage
local remotes = {}
for _, name in {"Attack", "State", "RequestState", "Notify", "WorldState", "EquipPet", "SelectClass", "UseAbility", "CraftUpgrade", "ClaimExpedition", "CombatEffect", "CombatHit", "PartyAction", "PartyState", "TravelRequest", "OpenTravel"} do
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
local lastEquip = {}
local bossService
local actions
local partyService
local travelService
local eliteService

local function state(player)
	local handle = profiles[player]
	if not handle or not player.Parent then return end
	local p = handle.data
	local petStats = {}
	for petId, owned in p.pets do
		if owned then petStats[petId] = PetGrowth.info(p, petId, Config) end
	end
	local equippedInfo = petStats[p.equippedPet]
	local petLevel = if equippedInfo then equippedInfo.level else 0
	if player:GetAttribute("PetLevel") ~= petLevel then player:SetAttribute("PetLevel", petLevel) end
	local resource, cooldowns = 100, {}
	if actions then resource, cooldowns = actions:snapshot(player) end
	remotes.State:FireClient(player, {
		level = p.level, xp = p.xp, xpNeeded = Progression.xpNeeded(p.level),
		gold = p.gold, kills = p.kills, questStatus = p.questStatus,
		questKills = p.questKills, questTarget = Config.QuestTarget,
		hasCrystal = p.hasCrystal, saveStatus = handle.status,
		classId = p.classId, equipmentTier = p.equipmentTier, materials = table.clone(p.materials),
		expedition = table.clone(p.expedition), resource = resource, cooldowns = cooldowns, stats = Combat.stats(p, Config),
		petXP = table.clone(p.petXP), petStats = petStats,
		pets = table.clone(p.pets), equippedPet = p.equippedPet or "",
		petPity = table.clone(p.petPity), bossVictories = table.clone(p.bossVictories), stardust = p.stardust,
		waypoints = table.clone(p.waypoints), travel = if travelService then travelService:snapshot(player) else nil,
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

local function awardPet(player, amount)
	local handle = profiles[player]
	if not handle then return end
	local result = PetGrowth.award(handle.data, amount, Config)
	if result and result.leveledUp then
		remotes.Notify:FireClient(player, "Petin seviye atladı! Yeni seviye: " .. tostring(result.level))
	end
end
local function worldSnapshot()
	local snapshot = bossService:snapshot()
	snapshot.elites = if eliteService then eliteService:snapshot() else {}
	return snapshot
end

local function savePlayer(player)
	task.spawn(function()
		if not profiles[player] then return end
		if not ProfileStore.save(player, false) and player.Parent then
			-- Stop mutations before the removal callback yields on final persistence.
			profiles[player] = nil
			player:Kick("İlerlemen güvenle kaydedilemedi. Lütfen yeniden katıl.")
		end
		state(player)
	end)
end
bossService = BossService.new(world, {
	profiles = profiles, living = livingCharacter, trusted = trustedPosition, safe = isSafe,
	state = state, save = savePlayer,
	eligible = function(player)
		Campaign.recordBoss(profiles[player].data, Config)
		awardPet(player, Config.PetProgression.BossXP)
	end,
	notify = function(player, message) remotes.Notify:FireClient(player, message) end,
	broadcast = function(message) remotes.Notify:FireAllClients(message) end,
})
remotes.EquipPet.OnServerEvent:Connect(function(player, petId, ...)
	if select("#", ...) ~= 0 or type(petId) ~= "string" or #petId > 32 then return end
	local handle = profiles[player]
	local now = os.clock()
	if not handle or now - (lastEquip[player] or 0) < 0.5 then return end
	lastEquip[player] = now
	if Pets.equip(handle.data, petId, Config) then
		player:SetAttribute("EquippedPet", handle.data.equippedPet or "")
		state(player)
	end
end)

remotes.RequestState.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) ~= 0 then return end
	local now = os.clock()
	if now - (lastRequest[player] or 0) < 0.5 then return end
	lastRequest[player] = now
	state(player)
	remotes.WorldState:FireClient(player, worldSnapshot())
	if partyService then remotes.PartyState:FireClient(player, partyService:snapshot(player)) end
end)

eliteService = EliteService.new(world, {
	changed = function() remotes.WorldState:FireAllClients(worldSnapshot()) end,
	profiles = profiles, living = livingCharacter, trusted = trustedPosition, safe = isSafe,
	assists = function(player, position) return if partyService then partyService:assists(player, position) else {} end,
	reward = function(player, definition, personal)
		local profile = profiles[player].data
		local xp = PartyRules.rewardXP(definition.XP, not personal, Config)
		Progression.recordRegionKill(profile, definition.RegionId, xp, Config)
		Campaign.recordKill(profile, definition.RegionId, Config)
		if personal then
			profile.gold = math.min(999999999, profile.gold + definition.Gold)
			local material = Config.Regions[definition.RegionId].Material
			if material then profile.materials[material] = math.min(100000000, profile.materials[material] + math.max(0, definition.MaterialAmount - 1)) end
		end
		awardPet(player, if personal then Config.PetProgression.EliteXP else Config.PetProgression.NormalXP)
		remotes.Notify:FireClient(player, if personal then "Elit yenildi! Kişisel ödüllerin verildi; elitlerden pet düşmez." else "Grup desteği: %70 XP, bir malzeme ve kuşanılmış pet XP'si.")
		state(player)
		savePlayer(player)
	end,
})
actions = PlayerActions.new(world, {
	profiles = profiles, enemies = enemies, bosses = bossService, elites = eliteService,
	living = livingCharacter, trusted = trustedPosition, safe = isSafe,
	state = state, save = savePlayer,
	notify = function(player, message) remotes.Notify:FireClient(player, message) end,
	effect = function(payload) remotes.CombatEffect:FireAllClients(payload) end,
	hit = function(player, payload)
		local amount = payload.amount
		if player.Parent and type(amount) == "number" and amount == amount and amount > 0 and amount < math.huge then
			remotes.CombatHit:FireClient(player, payload)
		end
	end,
})
actions:connectGathering()
partyService = PartyService.new({
	profiles = profiles, living = livingCharacter, trusted = trustedPosition,
	state = function(player, snapshot) if player.Parent then remotes.PartyState:FireClient(player, snapshot) end end,
	notify = function(player, message) remotes.Notify:FireClient(player, message) end,
})
travelService = TravelService.new(world, {
	profiles = profiles, living = livingCharacter, trusted = trustedPosition,
	combatInfo = function(player) return actions:combatInfo(player) end,
	state = state, save = savePlayer,
	open = function(player) remotes.OpenTravel:FireClient(player) end,
	notify = function(player, message) remotes.Notify:FireClient(player, message) end,
	moved = function(player, root)
		movement[player] = {position = root.Position, time = os.clock(), blockedUntil = os.clock() + 0.5}
	end,
})
travelService:connect()
remotes.PartyAction.OnServerEvent:Connect(function(player, action, targetId, ...)
	if select("#", ...) == 0 then partyService:action(player, action, targetId) end
end)
remotes.TravelRequest.OnServerEvent:Connect(function(player, id, ...)
	if select("#", ...) == 0 then travelService:request(player, id) end
end)
remotes.Attack.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) == 0 then actions:basic(player) end
end)
remotes.UseAbility.OnServerEvent:Connect(function(player, slot, ...)
	if select("#", ...) == 0 and type(slot) == "string" then actions:ability(player, slot) end
end)
remotes.SelectClass.OnServerEvent:Connect(function(player, classId, ...)
	if select("#", ...) == 0 then actions:selectClass(player, classId) end
end)
remotes.CraftUpgrade.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) == 0 then actions:craft(player) end
end)
remotes.ClaimExpedition.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) == 0 then actions:claim(player) end
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

local function spawnEnemy(position, index, regionId)
	if closing then return end
	local model = World.createEnemy(world.EnemyFolder, position, index, regionId)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then model:Destroy() return end
	local region = Config.Regions[regionId] or Config.Regions.forest
	humanoid.MaxHealth = region.EnemyHealth
	humanoid.Health = region.EnemyHealth
	humanoid.WalkSpeed = Config.EnemyWalkSpeed
	root:SetNetworkOwner(nil)
	local info = {spawn = position, lastAttack = 0, lastAttacker = nil, damage = region.EnemyDamage}
	enemies[model] = info
	humanoid.Died:Connect(function()
		enemies[model] = nil
		local player = info.lastAttacker
		if player and profiles[player] then
			local recipients = {player}
			for _, member in partyService:assists(player, root.Position) do table.insert(recipients, member) end
			for _, recipient in recipients do
				local profile = profiles[recipient].data
				local wasReady = profile.questStatus == "return"
				local xp = PartyRules.rewardXP(Config.KillXP * region.EnemyLevel, recipient ~= player, Config)
				Progression.recordRegionKill(profile, regionId, xp, Config)
				Campaign.recordKill(profile, regionId, Config)
				awardPet(recipient, Config.PetProgression.NormalXP)
				state(recipient)
				if not wasReady and profile.questStatus == "return" then
					remotes.Notify:FireClient(recipient, "Hedef tamamlandı! Köydeki bilgeye dön.")
				end
			end
		end
		task.delay(3, function() model:Destroy() end)
		task.delay(Config.EnemyRespawnSeconds, function() spawnEnemy(position, index, regionId) end)
	end)
end
for index, entry in world.EnemySpawns do spawnEnemy(entry.position, index, entry.regionId) end

task.spawn(function()
	while not closing do
		task.wait(0.25)
		local now = os.clock()
		bossService:update()
		eliteService:update()
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
		partyService:update()
		travelService:update()
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
						targetHumanoid:TakeDamage(info.damage)
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
	actions:characterAdded(player, character)
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
	if player.Character then actions:applyStats(player) end
	player:SetAttribute("EquippedPet", handle.data.equippedPet or "")
	state(player)
	remotes.WorldState:FireClient(player, worldSnapshot())
	partyService:push()
end
Players.PlayerAdded:Connect(playerAdded)
for _, player in Players:GetPlayers() do task.spawn(playerAdded, player) end
Players.PlayerRemoving:Connect(function(player)
	profiles[player] = nil
	lastEquip[player] = nil
	actions:remove(player)
	travelService:remove(player)
	partyService:remove(player)
	movement[player], lastAttack[player], lastRequest[player], lastPrompt[player] = nil, nil, nil, nil
	ProfileStore.save(player, true)
end)
task.spawn(function()
	while not closing do
		task.wait(45)
		for player in profiles do savePlayer(player) end
	end
end)
task.spawn(function()
	while not closing do
		task.wait(1)
		for player in profiles do state(player) end
	end
end)
task.spawn(function()
	while not closing do
		remotes.WorldState:FireAllClients(worldSnapshot())
		task.wait(3)
	end
end)
game:BindToClose(function()
	closing = true
	bossService:close()
	eliteService:close()
	local pending = 0
	for player in profiles do
		pending += 1
		task.spawn(function() ProfileStore.save(player, true) pending -= 1 end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do task.wait(0.1) end
end)
