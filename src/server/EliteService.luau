local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Rules = require(ReplicatedStorage.Shared.EliteRules)
local World = require(script.Parent.World)
local Service = {}
Service.__index = Service
local function now() return workspace:GetServerTimeNow() end
local function plain(position) return {x = position.X, y = position.Y, z = position.Z} end

function Service.new(world, callbacks)
	local self = setmetatable({world = world, callbacks = callbacks, targets = {}, encounters = {}, closed = false}, Service)
	for id, definition in Config.Elites do self:spawn(id, definition) end
	return self
end
function Service:changed()
	if self.callbacks.changed then self.callbacks.changed() end
end
function Service:spawn(id, definition)
	if self.closed then return end
	local model = World.createElite(self.world.EnemyFolder, definition)
	model:SetAttribute("EliteId", id)
	local humanoid, root = model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then model:Destroy() return end
	humanoid.MaxHealth, humanoid.Health, humanoid.WalkSpeed = definition.MaxHealth, definition.MaxHealth, 12
	root:SetNetworkOwner(nil)
	local current = {id = id, definition = definition, model = model, humanoid = humanoid, root = root,
		origin = root.Position, participants = {}, generation = 0, status = "alive", attackAt = now() + 3,
		telegraphEndsAt = 0, respawnAt = 0, channel = nil}
	self.encounters[id], self.targets[model] = current, current
	humanoid.Died:Connect(function() self:finish(current) end)
end
function Service:finish(current)
	if self.closed or self.encounters[current.id] ~= current or current.status ~= "alive" then return end
	current.status = "defeated"
	if current.warning and current.warning.Parent then current.warning:Destroy() end
	current.generation += 1
	current.channel, current.telegraphEndsAt = nil, 0
	current.respawnAt = now() + current.definition.Respawn
	self.targets[current.model] = nil
	self:changed()
	local recipients = {}
	for player, contribution in current.participants do
		local root = self.callbacks.living(player)
		if self.callbacks.profiles[player] and root and self.callbacks.trusted(player, root)
			and (root.Position - current.root.Position).Magnitude <= 120
			and Rules.eligible(contribution.damage, contribution.hits, current.definition.MaxHealth, Config) then
			recipients[player] = true
		end
	end
	-- First establish all personal qualifiers, then union party assistants. Full
	-- contribution always wins, and each player receives exactly one reward.
	local qualifiers = {}
	for player in recipients do table.insert(qualifiers, player) end
	for _, player in qualifiers do
		for _, assistant in self.callbacks.assists(player, current.root.Position) do
			if recipients[assistant] == nil then recipients[assistant] = false end
		end
	end
	for player, personal in recipients do
		if self.callbacks.profiles[player] then self.callbacks.reward(player, current.definition, personal) end
	end
	task.delay(3, function() if current.model.Parent then current.model:Destroy() end end)
	task.delay(current.definition.Respawn, function()
		if not self.closed and self.encounters[current.id] == current then
			self:spawn(current.id, current.definition)
			self:changed()
		end
	end)
end
function Service:damage(model, player, damage)
	if type(damage) ~= "number" or damage ~= damage or damage <= 0 or damage == math.huge then return 0 end
	local current = self.targets[model]
	if not current or current.status ~= "alive" or not model.Parent or not current.humanoid.Parent
		or not self.callbacks.profiles[player] or self.closed or self.encounters[current.id] ~= current then return 0 end
	local before = current.humanoid.Health
	local accepted = math.min(damage, math.max(0, before))
	if accepted <= 0 then return 0 end
	local contribution = current.participants[player] or {damage = 0, hits = 0}
	-- Credit before TakeDamage so a lethal hit is visible to the death callback.
	contribution.damage += accepted
	contribution.hits += 1
	current.participants[player] = contribution
	current.humanoid:TakeDamage(accepted)
	local actual = math.clamp(before - current.humanoid.Health, 0, accepted)
	contribution.damage -= accepted - actual
	if actual == 0 then contribution.hits -= 1 end
	return actual
end
function Service:cast(current, target)
	local definition = current.definition
	local center = if definition.Kind == "targeted" then target.Position else current.root.Position
	local channel = Rules.begin(now(), plain(center), definition)
	current.channel, current.telegraphEndsAt = channel, channel.endsAt
	local generation = current.generation
	current.warning = World.createEliteTelegraph(center, nil, definition)
	self:changed()
	task.delay(definition.Windup, function()
		if not Rules.ready(channel, now()) then task.wait(math.max(0.01, channel.endsAt - now())) end
		if self.closed or self.encounters[current.id] ~= current or current.status ~= "alive"
			or current.generation ~= generation or current.channel ~= channel or channel.resolved then return end
		if current.humanoid.Health <= 0 or not current.humanoid.Parent or not current.root.Parent or not current.model.Parent then
			-- Died can be deferred after Health reaches zero. Cancel this cast
			-- immediately rather than waiting for the encounter's death handler.
			channel.resolved = true
			current.channel, current.telegraphEndsAt = nil, 0
			if current.warning and current.warning.Parent then current.warning:Destroy() end
			current.warning = nil
			self:changed()
			return
		end
		-- The callback owns this cast; mark it resolved once before iterating all
		-- targets. Rules.canHit remains pure so frost can hit multiple players.
		channel.resolved = true
		if current.warning and current.warning.Parent then current.warning:Destroy() end
		current.warning = nil
		current.channel, current.telegraphEndsAt = nil, 0
		self:changed()
		for player in self.callbacks.profiles do
			local root, humanoid = self.callbacks.living(player)
			if root and not self.callbacks.safe(root.Position) then
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = {current.model}
				local hit = workspace:Raycast(current.root.Position, root.Position - current.root.Position, params)
				local lineOfSight = not hit or hit.Instance:IsDescendantOf(root.Parent)
				if Rules.canHit(channel, now(), plain(root.Position), true, self.callbacks.trusted(player, root), lineOfSight, definition) then
					humanoid:TakeDamage(definition.Damage)
				end
			end
		end
	end)
end
function Service:update()
	if self.closed then return end
	for _, current in self.encounters do
		if current.status ~= "alive" or not current.root.Parent or current.humanoid.Health <= 0 then continue end
		if (current.root.Position - current.origin).Magnitude > 130 then
			current.generation += 1
			if current.warning and current.warning.Parent then current.warning:Destroy() end
			current.warning = nil
			current.channel, current.telegraphEndsAt = nil, 0
			current.participants = {}
			current.humanoid.Health = current.definition.MaxHealth
			current.model:PivotTo(CFrame.new(current.origin))
			current.root.AssemblyLinearVelocity = Vector3.zero
			current.attackAt = now() + 3
			self:changed()
			continue
		end
		if current.channel then current.humanoid:MoveTo(current.root.Position) continue end
		local target, distance = nil, 85
		for player in self.callbacks.profiles do
			local root = self.callbacks.living(player)
			if root and not self.callbacks.safe(root.Position) and self.callbacks.trusted(player, root) then
				local candidate = (root.Position - current.root.Position).Magnitude
				if candidate < distance then target, distance = root, candidate end
			end
		end
		if target then
			current.humanoid:MoveTo(target.Position)
			if now() >= current.attackAt and (current.definition.Kind == "targeted" or distance <= current.definition.Radius + 4) then
				current.attackAt = now() + current.definition.Cooldown
				self:cast(current, target)
			end
		else current.humanoid:MoveTo(current.origin) end
	end
end
function Service:snapshot()
	local entries = {}
	for id, current in self.encounters do
		local definition = current.definition
		table.insert(entries, {id = id, status = current.status, health = if current.status == "alive" then current.humanoid.Health else 0,
			maxHealth = definition.MaxHealth, x = definition.X, z = definition.Z, regionId = definition.RegionId,
			attackKind = definition.Kind, telegraphEndsAt = current.telegraphEndsAt, respawnAt = current.respawnAt})
	end
	table.sort(entries, function(a, b) return a.id < b.id end)
	return entries
end
function Service:close()
	self.closed = true
	for _, current in self.encounters do
		current.generation += 1
		current.status = "defeated"
		if current.warning and current.warning.Parent then current.warning:Destroy() end
		current.channel, current.telegraphEndsAt = nil, 0
		if current.model.Parent then current.model:Destroy() end
	end
	table.clear(self.targets)
	self:changed()
end
return Service
