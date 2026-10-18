local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Rules = require(ReplicatedStorage.Shared.EnemyRules)
local World = require(script.Parent.World)
local Service = {}
Service.__index = Service
local function now() return workspace:GetServerTimeNow() end
local function plain(v) return {x = v.X, y = v.Y, z = v.Z} end

function Service.new(world, callbacks, targets)
	local self = setmetatable({world = world, callbacks = callbacks, targets = targets, slots = {}, closed = false}, Service)
	for index, entry in world.EnemySpawns do self:spawn(index, entry) end
	return self
end
function Service:cancel(current)
	current.generation += 1
	current.channel = nil
	if current.warning and current.warning.Parent then current.warning:Destroy() end
	current.warning = nil
end
function Service:spawn(index, entry)
	if self.closed then return end
	local model = World.createEnemy(self.world.EnemyFolder, entry.position, index, entry.regionId)
	local humanoid, root = model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then model:Destroy() return end
	local region = Config.Regions[entry.regionId]
	local definition = Config.EnemyBehaviors[entry.regionId]
	model:SetAttribute("AetheriaEnemy", true)
	model:SetAttribute("EnemyKind", "normal")
	model:SetAttribute("EnemyBehavior", definition.Kind)
	model:SetAttribute("RegionId", entry.regionId)
	model:SetAttribute("MobId", index)
	humanoid.MaxHealth, humanoid.Health, humanoid.WalkSpeed = region.EnemyHealth, region.EnemyHealth, Config.EnemyWalkSpeed
	root:SetNetworkOwner(nil)
	local current = {index = index, entry = entry, model = model, humanoid = humanoid, root = root,
		origin = root.Position, definition = definition, status = "alive", generation = 0, channel = nil,
		attackAt = 0, lastAttacker = nil}
	self.slots[index], self.targets[model] = current, current
	humanoid.Died:Connect(function() self:finish(current) end)
end
function Service:finish(current)
	if self.closed or self.slots[current.index] ~= current or current.status ~= "alive" then return end
	current.status = "defeated"
	self:cancel(current)
	self.targets[current.model] = nil
	local player = current.lastAttacker
	if player and self.callbacks.profiles[player] then self.callbacks.reward(player, current.entry.regionId, current.root.Position) end
	task.delay(3, function() if current.model.Parent then current.model:Destroy() end end)
	task.delay(Config.EnemyRespawnSeconds, function()
		if not self.closed and self.slots[current.index] == current then self:spawn(current.index, current.entry) end
	end)
end
function Service:lineOfSight(current, root)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {current.model}
	local hit = workspace:Raycast(current.root.Position, root.Position - current.root.Position, params)
	return not hit or hit.Instance:IsDescendantOf(root.Parent)
end
function Service:resolve(current, channel, generation)
	if self.closed or self.slots[current.index] ~= current or current.status ~= "alive"
		or current.generation ~= generation or current.channel ~= channel or channel.resolved then return end
	if current.humanoid.Health <= 0 or not current.humanoid.Parent or not current.root.Parent or not current.model.Parent then self:cancel(current) return end
	if not Rules.ready(channel, now()) then
		task.delay(math.max(0.01, channel.endsAt - now()), function() self:resolve(current, channel, generation) end)
		return
	end
	channel.resolved = true
	current.channel = nil
	if current.warning and current.warning.Parent then current.warning:Destroy() end
	current.warning = nil
	for player in self.callbacks.profiles do
		local root, humanoid = self.callbacks.living(player)
		if root and not self.callbacks.safe(root.Position) and Rules.canHit(channel, now(), plain(root.Position), true,
			self.callbacks.trusted(player, root), self:lineOfSight(current, root), current.definition) then
			humanoid:TakeDamage(current.definition.Damage)
		end
	end
end
function Service:cast(current, target, targetPlayer)
	local definition = current.definition
	current.attackAt = now() + definition.Cooldown
	if definition.Windup <= 0 then
		local root, humanoid = self.callbacks.living(targetPlayer)
		if root and not self.callbacks.safe(root.Position) and self.callbacks.trusted(targetPlayer, root)
			and (root.Position - current.root.Position).Magnitude <= definition.Range and self:lineOfSight(current, root) then
			humanoid:TakeDamage(definition.Damage)
		end
		return
	end
	local center = if definition.Kind == "targeted" then target.Position else current.root.Position
	local channel = Rules.begin(now(), plain(center), definition)
	current.channel = channel
	current.warning = World.createEnemyTelegraph(center, definition, current.entry.regionId)
	current.humanoid:MoveTo(current.root.Position)
	local generation = current.generation
	task.delay(definition.Windup, function() self:resolve(current, channel, generation) end)
end
function Service:update()
	if self.closed then return end
	for _, current in self.slots do
		if current.status ~= "alive" then continue end
		if current.humanoid.Health <= 0 or not current.model.Parent or not current.root.Parent then self:cancel(current) continue end
		local definition = current.definition
		if (current.root.Position - current.origin).Magnitude > definition.Leash then
			self:cancel(current)
			current.lastAttacker = nil
			current.humanoid.Health = current.humanoid.MaxHealth
			current.model:PivotTo(CFrame.new(current.origin))
			current.root.AssemblyLinearVelocity = Vector3.zero
			current.attackAt = now() + definition.Cooldown
			continue
		end
		if current.channel then current.humanoid:MoveTo(current.root.Position) continue end
		local target, targetPlayer, distance = nil, nil, definition.AggroRange
		for player in self.callbacks.profiles do
			local root = self.callbacks.living(player)
			if root and not self.callbacks.safe(root.Position) and self.callbacks.trusted(player, root) then
				local candidate = (root.Position - current.root.Position).Magnitude
				if candidate < distance then target, targetPlayer, distance = root, player, candidate end
			end
		end
		if not target then current.humanoid:MoveTo(current.origin) continue end
		if distance <= definition.Range then
			current.humanoid:MoveTo(current.root.Position)
			if now() >= current.attackAt and self:lineOfSight(current, target) then self:cast(current, target, targetPlayer) end
		else current.humanoid:MoveTo(target.Position) end
	end
end
function Service:close()
	self.closed = true
	for _, current in self.slots do
		current.status = "defeated"
		self:cancel(current)
		if current.model.Parent then current.model:Destroy() end
	end
	table.clear(self.targets)
end
return Service
