local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Schedule = require(ReplicatedStorage.Shared.BossSchedule)
local Pets = require(ReplicatedStorage.Shared.Pets)
local Progression = require(ReplicatedStorage.Shared.Progression)
local World = require(script.Parent.World)
local BossService = {}
BossService.__index = BossService

function BossService.new(world, callbacks)
	return setmetatable({world = world, callbacks = callbacks, targets = {}, current = nil,
		epoch = os.time(), started = os.clock(), demo = RunService:IsStudio(), seen = {}, random = Random.new(), closed = false}, BossService)
end

function BossService:clear(status)
	local current = self.current
	if not current then return end
	current.status = status
	current.generation += 1
	self.targets[current.model] = nil
	if current.model.Parent then current.model:Destroy() end
end

function BossService:finish(current)
	if self.current ~= current or current.status ~= "alive" then return end
	if os.time() >= current.endsAt then self:clear("expired") return end
	current.status = "defeated"
	current.generation += 1
	self.targets[current.model] = nil
	for player, contribution in current.participants do
		local handle = self.callbacks.profiles[player]
		if handle and player.Parent then
			local result = Pets.claim(handle.data, current.id, current.occurrence,
				contribution.damage, contribution.hits, current.maxHealth, self.random:NextNumber(), Config)
			if result.status == "rewarded" then
				handle.data.level, handle.data.xp = Progression.addXP(handle.data.level, handle.data.xp, result.xp or 0)
				local message = "Dünya bossu yenildi! Kişisel ödüllerin verildi."
				if result.petId then
					message = if result.duplicate then "Aynı pet yeniden düştü: +10 yıldız tozu!" else "Nadir bir pet kazandın! Koleksiyonunu aç."
				end
				self.callbacks.notify(player, message)
				self.callbacks.state(player)
				self.callbacks.save(player)
			elseif result.status == "ineligible" then
				self.callbacks.notify(player, "Boss ödülü için en az 3 isabet ve %1 hasar gerekli.")
			end
		end
	end
	task.delay(3, function() if current.model.Parent then current.model:Destroy() end end)
end

function BossService:spawn(slot)
	local definition = Config.Bosses[slot.bossId]
	local model = World.createBoss(self.world.EnemyFolder, definition)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then model:Destroy() return end
	local maxHealth = math.floor(definition.MaxHealth * (if self.demo then Config.StudioBossHealthScale else 1))
	humanoid.MaxHealth, humanoid.Health, humanoid.WalkSpeed = maxHealth, maxHealth, definition.WalkSpeed
	root:SetNetworkOwner(nil)
	local current = {id = slot.bossId, occurrence = slot.occurrence, startsAt = slot.startsAt, endsAt = slot.endsAt,
		def = definition, maxHealth = maxHealth, model = model, humanoid = humanoid, root = root, origin = root.Position,
		status = "alive", participants = {}, generation = 0, meleeAt = 0, aoeAt = os.clock() + 8}
	self.current = current
	self.targets[model] = current
	self.seen[slot.bossId] = slot.occurrence
	humanoid.Died:Connect(function() self:finish(current) end)
	self.callbacks.broadcast(definition.Name .. " ortaya çıktı! Haritadaki boss alanına git.")
end

function BossService:damage(model, player, amount)
	local current = self.targets[model]
	if not current or current.status ~= "alive" or os.time() >= current.endsAt then return end
	local accepted = math.min(amount, math.max(0, current.humanoid.Health))
	if accepted <= 0 then return end
	local contribution = current.participants[player] or {damage = 0, hits = 0}
	contribution.damage += accepted
	contribution.hits += 1
	current.participants[player] = contribution
	current.humanoid:TakeDamage(accepted)
end

function BossService:update()
	if self.closed then return end
	local now = os.time()
	local slot = if self.demo then Schedule.studio(os.clock() - self.started, Config, self.epoch) else Schedule.production(now, Config)
	local current = self.current
	if current and now >= current.endsAt and current.status == "alive" then self:clear("expired") end
	if slot and self.seen[slot.bossId] ~= slot.occurrence then
		if current and current.status == "alive" then self:clear("expired") end
		self:spawn(slot)
		current = self.current
	end
	if not current or current.status ~= "alive" or current.humanoid.Health <= 0 then return end
	local root, humanoid = current.root, current.humanoid
	if not root.Parent then return end
	if (root.Position - current.origin).Magnitude > 130 then
		current.model:PivotTo(CFrame.new(current.origin))
		humanoid.Health = humanoid.MaxHealth
		current.participants = {}
		current.generation += 1
		return
	end
	local target, targetHumanoid, distance = nil, nil, 100
	for player in self.callbacks.profiles do
		local candidate, candidateHumanoid = self.callbacks.living(player)
		if candidate and self.callbacks.trusted(player, candidate) and not self.callbacks.safe(candidate.Position) then
			local candidateDistance = (candidate.Position - root.Position).Magnitude
			if candidateDistance < distance then target, targetHumanoid, distance = candidate, candidateHumanoid, candidateDistance end
		end
	end
	if not target then humanoid:MoveTo(current.origin) return end
	humanoid:MoveTo(target.Position)
	local clock = os.clock()
	if distance <= current.def.AttackRange and clock >= current.meleeAt then
		current.meleeAt = clock + current.def.AttackCooldown
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {current.model}
		local hit = workspace:Raycast(root.Position, target.Position - root.Position, params)
		if not hit or hit.Instance:IsDescendantOf(target.Parent) then targetHumanoid:TakeDamage(current.def.Damage) end
	end
	if clock >= current.aoeAt then
		current.aoeAt = clock + 8
		local center, radius, delaySeconds = target.Position, 15, 1.8
		World.createTelegraph(center, radius, delaySeconds)
		local generation = current.generation
		task.delay(delaySeconds, function()
			if self.closed or self.current ~= current or current.status ~= "alive" or generation ~= current.generation or os.time() >= current.endsAt then return end
			for player in self.callbacks.profiles do
				local playerRoot, playerHumanoid = self.callbacks.living(player)
				if playerRoot and not self.callbacks.safe(playerRoot.Position) and (playerRoot.Position - center).Magnitude <= radius then
					playerHumanoid:TakeDamage(math.floor(current.def.Damage * 1.5))
				end
			end
		end)
	end
end

function BossService:snapshot()
	local now = os.time()
	local bosses = {}
	for index, id in Config.BossOrder do
		local definition = Config.Bosses[id]
		local nextAt
		if self.demo then
			local first = self.epoch + Config.StudioFirstBossDelay + (index - 1) * Config.StudioBossInterval
			local cycle = #Config.BossOrder * Config.StudioBossInterval
			nextAt = first + math.max(0, math.floor((now - first) / cycle) + 1) * cycle
		else
			local hour = math.floor(now / 3600) * 3600
			nextAt = hour + definition.Minute * 60
			if nextAt <= now then nextAt += 3600 end
		end
		local current = self.current
		local matching = current and current.id == id
		table.insert(bosses, {id = id, status = if matching then current.status else "waiting", nextAt = nextAt,
			occurrenceAt = if matching then current.occurrence else 0,
			despawnAt = if matching then current.endsAt else 0,
			health = if matching and current.status == "alive" then current.humanoid.Health else 0,
			maxHealth = if matching then current.maxHealth else math.floor(definition.MaxHealth * (if self.demo then Config.StudioBossHealthScale else 1)), x = definition.X, z = definition.Z, regionId = definition.RegionId, petId = definition.PetId})
	end
	return {serverNow = now, studioDemo = self.demo, bosses = bosses}
end

function BossService:close()
	self.closed = true
	self:clear("expired")
end
return BossService
