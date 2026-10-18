local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Combat = require(ReplicatedStorage.Shared.Combat)
local Campaign = require(ReplicatedStorage.Shared.Campaign)
local Crafting = require(ReplicatedStorage.Shared.Crafting)
local Progression = require(ReplicatedStorage.Shared.Progression)
local World = require(script.Parent.World)
local Actions = {}
Actions.__index = Actions
local function now() return workspace:GetServerTimeNow() end

function Actions.new(world, callbacks)
	return setmetatable({world = world, callbacks = callbacks, runtimes = {}, nodes = {}}, Actions)
end
function Actions:runtime(player)
	local runtime = self.runtimes[player]
	if not runtime then
		runtime = Combat.newRuntime(now())
		runtime.lastCombat = -math.huge
		runtime.lastDamage = -math.huge
		runtime.lastAction = {}
		self.runtimes[player] = runtime
	end
	return runtime
end
function Actions:combatInfo(player)
	local runtime = self.runtimes[player]
	return if runtime then runtime.lastCombat else -math.huge, if runtime then runtime.lastDamage else -math.huge
end
function Actions:gate(player, action)
	if not self.callbacks.profiles[player] then return false end
	local runtime = self:runtime(player)
	local time = now()
	if time - (runtime.lastAction[action] or -math.huge) < 0.25 then return false end
	runtime.lastAction[action] = time
	return true
end
function Actions:applyStats(player)
	local handle = self.callbacks.profiles[player]
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not handle or not humanoid or humanoid.Health <= 0 then return end
	local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	humanoid.MaxHealth = Combat.stats(handle.data, Config).maxHealth
	humanoid.Health = humanoid.MaxHealth * ratio
	World.equipWeapon(character, handle.data.classId, handle.data.equipmentTier)
end
function Actions:snapshot(player)
	local runtime = self:runtime(player)
	Combat.refresh(runtime, now(), Config)
	return runtime.resource, table.clone(runtime.cooldowns)
end
function Actions:validTarget(player, origin, model, range)
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or (root.Position - origin).Magnitude > range then return nil end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character}
	local hit = workspace:Raycast(origin, root.Position - origin, params)
	if hit and not hit.Instance:IsDescendantOf(model) then return nil end
	return root
end
function Actions:targets(player, root, range, limit, preferred)
	local candidates = {}
	local preferredRoot
	if preferred ~= nil then
		if typeof(preferred) ~= "Instance" or not preferred:IsA("Model") then return {} end
		if not (self.callbacks.enemies[preferred] or self.callbacks.bosses.targets[preferred] or self.callbacks.elites.targets[preferred]) then return {} end
		preferredRoot = self:validTarget(player, root.Position, preferred, range)
		if not preferredRoot then return {} end
	end
	for _, collection in {self.callbacks.enemies, self.callbacks.bosses.targets, self.callbacks.elites.targets} do
		for model in collection do
			if model == preferred then continue end
			local target = self:validTarget(player, root.Position, model, range)
			if target then table.insert(candidates, {model = model, root = target, distance = (target.Position - root.Position).Magnitude}) end
		end
	end
	table.sort(candidates, function(a, b) return a.distance < b.distance end)
	if preferredRoot then table.insert(candidates, 1, {model = preferred, root = preferredRoot, distance = 0}) end
	while #candidates > limit do table.remove(candidates) end
	return candidates
end
function Actions:damage(player, targets, damage)
	local hits = {}
	if type(damage) ~= "number" or damage ~= damage or damage <= 0 or damage == math.huge then return hits end
	for _, target in targets do
		local model = target.model
		local position = target.root.Position
		local actual = 0
		if self.callbacks.bosses.targets[model] then actual = self.callbacks.bosses:damage(model, player, damage)
		elseif self.callbacks.elites.targets[model] then actual = self.callbacks.elites:damage(model, player, damage)
		elseif self.callbacks.enemies[model] and model.Parent then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local info = self.callbacks.enemies[model]
				local previousAttacker = info.lastAttacker
				info.lastAttacker = player
				local before = humanoid.Health
				humanoid:TakeDamage(math.min(damage, before))
				actual = math.clamp(before - humanoid.Health, 0, math.min(damage, before))
				if actual == 0 then info.lastAttacker = previousAttacker end
			end
		end
		if type(actual) == "number" and actual == actual and actual > 0 and actual < math.huge then
			local payload = {position = position, amount = actual, kind = "damage"}
			table.insert(hits, payload)
			self.callbacks.hit(player, payload)
		end
	end
	if #hits > 0 then self:runtime(player).lastCombat = now() end
	return hits
end
function Actions:basic(player, preferred)
	if not self:gate(player, "basic") then return end
	local root = self.callbacks.living(player)
	if not root or not self.callbacks.trusted(player, root) or self.callbacks.safe(root.Position) then return end
	local runtime = self:runtime(player)
	local time = now()
	if time < (runtime.basicAt or 0) then return end
	local stats = Combat.stats(self.callbacks.profiles[player].data, Config)
	local targets = self:targets(player, root, stats.basicRange, 1, preferred)
	if #targets == 0 then return end
	runtime.basicAt = time + Config.AttackCooldown
	self:damage(player, targets, stats.basicDamage)
	self.callbacks.effect({userId = player.UserId, abilityId = "basic", classId = stats.classId, kind = if stats.classId == "mage" then "projectile" else "basic", origin = root.Position, target = targets[1].root.Position, damage = stats.basicDamage})
end
function Actions:ability(player, slot, preferred)
	if (slot ~= "primary" and slot ~= "secondary") or not self:gate(player, "ability") then return end
	if preferred ~= nil and (typeof(preferred) ~= "Instance" or not preferred:IsA("Model")) then return end
	local root, humanoid = self.callbacks.living(player)
	if not root or not self.callbacks.trusted(player, root) then return end
	local profile = self.callbacks.profiles[player].data
	local definition = Config.Abilities[profile.classId][slot]
	local healing = definition.Kind == "heal"
	if not healing and self.callbacks.safe(root.Position) then return end
	local targets = if healing then {} else self:targets(player, root, definition.Range or definition.Radius, if definition.Kind == "area" then 3 else 1, preferred)
	local valid = if healing then humanoid.Health < humanoid.MaxHealth else #targets > 0
	local runtime = self:runtime(player)
	local result = Combat.use(profile, runtime, slot, now(), valid, Config)
	if result.status ~= "used" then
		local messages = {target = "Geçerli hedef yok.", cooldown = "Yetenek henüz hazır değil.", resource = "Yeterli enerji yok."}
		if messages[result.status] then self.callbacks.notify(player, messages[result.status]) end
		return
	end
	local damage, healed
	if healing then
		local before = humanoid.Health
		humanoid.Health = math.min(humanoid.MaxHealth, before + definition.Heal)
		healed = humanoid.Health - before
	else
		damage = math.floor(Combat.stats(profile, Config).basicDamage * definition.Multiplier)
		self:damage(player, targets, damage)
	end
	self.callbacks.effect({userId = player.UserId, abilityId = profile.classId .. "_" .. slot, classId = profile.classId, kind = definition.Kind,
		origin = root.Position, target = if targets[1] then targets[1].root.Position else nil, radius = definition.Radius, damage = damage})
	self.callbacks.state(player)
	if healed and healed == healed and healed > 0 and healed < math.huge then
		self.callbacks.hit(player, {position = root.Position, amount = healed, kind = "heal"})
	end
end
function Actions:selectClass(player, classId)
	if type(classId) ~= "string" or #classId > 16 or not Config.Classes[classId] or not self:gate(player, "class") then return end
	local root = self.callbacks.living(player)
	if not root or not self.callbacks.trusted(player, root) or not self.callbacks.safe(root.Position) then return end
	if now() - self:runtime(player).lastCombat < 10 then self.callbacks.notify(player, "Sınıf değiştirmek için savaş dışında 10 saniye bekle.") return end
	self.callbacks.profiles[player].data.classId = classId
	-- Resource and both cooldown timestamps deliberately survive the switch.
	self:applyStats(player)
	self.callbacks.state(player)
end
function Actions:craft(player)
	if not self:gate(player, "craft") then return end
	local root = self.callbacks.living(player)
	if not root or not self.callbacks.trusted(player, root) or (root.Position - self.world.Blacksmith:GetPivot().Position).Magnitude > 15 then return end
	local result = Crafting.craft(self.callbacks.profiles[player].data, Config)
	if result.status == "crafted" then
		self:applyStats(player)
		self.callbacks.notify(player, "Ekipmanın geliştirildi!")
		self.callbacks.state(player)
		self.callbacks.save(player)
	else self.callbacks.notify(player, "Geliştirme için malzeme/altın gerekebilir veya son seviyedesin.") end
end
function Actions:claim(player)
	if not self:gate(player, "claim") then return end
	local profile = self.callbacks.profiles[player].data
	local result = Campaign.claim(profile, Config)
	if result.status ~= "rewarded" then return end
	profile.level, profile.xp = Progression.addXP(profile.level, profile.xp, result.xp or 0)
	self.callbacks.notify(player, "Sefer aşaması tamamlandı! Ödüllerin verildi.")
	self.callbacks.state(player)
	self.callbacks.save(player)
end
function Actions:connectGathering()
	self.world.ForgePrompt.Triggered:Connect(function(player) self:craft(player) end)
	for _, node in self.world.ResourceNodes do
		node.prompt.Triggered:Connect(function(player)
			if not self:gate(player, "gather") then return end
			local root = self.callbacks.living(player)
			if not root or not self.callbacks.trusted(player, root) or (root.Position - node.position).Magnitude > node.prompt.MaxActivationDistance + 2 then return end
			local cooldowns = self.nodes[player] or {}
			self.nodes[player] = cooldowns
			if now() < (cooldowns[node.id] or 0) then self.callbacks.notify(player, "Bu kaynağın yenilenmesini bekle (30 saniye).") return end
			local profile = self.callbacks.profiles[player].data
			if profile.materials[node.kind] == nil then return end
			cooldowns[node.id] = now() + 30
			profile.materials[node.kind] = math.min(100000000, profile.materials[node.kind] + node.amount)
			if self.callbacks.gathered then self.callbacks.gathered(player, node.regionId or node.id:match("^(%a+)_")) end
			self.callbacks.state(player)
		end)
	end
end
function Actions:characterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or player.Character ~= character or not player.Parent then return end
	self:applyStats(player)
	local previous = humanoid.Health
	local runtime = self:runtime(player)
	if runtime.healthConnection then runtime.healthConnection:Disconnect() end
	runtime.healthConnection = humanoid.HealthChanged:Connect(function(health)
		if player.Character ~= character or not player.Parent then return end
		if health < previous then runtime.lastCombat, runtime.lastDamage = now(), now() end
		previous = health
	end)
end
function Actions:remove(player)
	local runtime = self.runtimes[player]
	if runtime and runtime.healthConnection then runtime.healthConnection:Disconnect() end
	self.runtimes[player], self.nodes[player] = nil, nil
end
return Actions
