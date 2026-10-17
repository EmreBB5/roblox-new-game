local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Rules = require(ReplicatedStorage.Shared.TravelRules)
local TravelService = {}
TravelService.__index = TravelService
local function position(vector) return {x = vector.X, y = vector.Y, z = vector.Z} end
function TravelService.new(world, callbacks)
	return setmetatable({world = world, callbacks = callbacks, channels = {}, last = {}}, TravelService)
end
function TravelService:snapshot(player)
	local channel = self.channels[player]
	return if channel then {destination = channel.waypointId, endsAt = channel.endsAt} else nil
end
function TravelService:gate(player)
	if not self.callbacks.profiles[player] then return false end
	local now = workspace:GetServerTimeNow()
	if now - (self.last[player] or -math.huge) < 0.5 then return false end
	self.last[player] = now
	return true
end
function TravelService:connect()
	for id, waypoint in self.world.Waypoints do
		waypoint.prompt.Triggered:Connect(function(player)
			if not self:gate(player) then return end
			local root = self.callbacks.living(player)
			if not root or not self.callbacks.trusted(player, root) or (root.Position - waypoint.position).Magnitude > math.min(16, waypoint.prompt.MaxActivationDistance + 2) then return end
			local profile = self.callbacks.profiles[player].data
			if not profile.waypoints[id] then
				profile.waypoints[id] = true
				self.callbacks.notify(player, "Yeni türbe keşfedildi!")
				self.callbacks.save(player)
			end
			self.callbacks.state(player)
			self.callbacks.open(player)
		end)
	end
end
function TravelService:request(player, id)
	if type(id) ~= "string" or #id > 32 or not self.world.Waypoints[id] or not self:gate(player) or self.channels[player] then return end
	local root = self.callbacks.living(player)
	local distance = math.huge
	local sourceId
	if root then
		for source, waypoint in self.world.Waypoints do
			local candidate = (root.Position - waypoint.position).Magnitude
			if candidate < distance then distance, sourceId = candidate, source end
		end
	end
	local lastCombat = self.callbacks.combatInfo(player)
	local result = Rules.begin(self.callbacks.profiles[player].data, id, distance, root ~= nil,
		root ~= nil and self.callbacks.trusted(player, root) == true, lastCombat, workspace:GetServerTimeNow(), Config,
		player.Character, if root then position(root.Position) else {x = 0, y = 0, z = 0}, sourceId)
	if result.status ~= "started" then self.callbacks.notify(player, "Seyahat için keşfedilmiş bir hedef seç; türbeye yaklaş ve savaş dışında 10 saniye bekle.") return end
	self.channels[player] = result.channel
	self.callbacks.state(player)
end
function TravelService:update()
	local now = workspace:GetServerTimeNow()
	for player, channel in self.channels do
		local root = self.callbacks.living(player)
		local lastCombat, lastDamage = self.callbacks.combatInfo(player)
		local status = if not self.callbacks.profiles[player] then "cancelled" else Rules.check(channel, now,
			if root then position(root.Position) else {x = 0, y = 0, z = 0}, player.Character, root ~= nil,
			root ~= nil and self.callbacks.trusted(player, root) == true, math.max(lastDamage, lastCombat), Config)
		if status == "ready" then
			local destination = self.world.Waypoints[channel.waypointId]
			self.channels[player] = nil
			player.Character:PivotTo(destination.arrival)
			root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
			self.callbacks.moved(player, root)
			local protection = Instance.new("ForceField")
			protection.Name = "TravelArrivalProtection"
			protection.Parent = player.Character
			Debris:AddItem(protection, 3)
			self.callbacks.state(player)
		elseif status == "cancelled" then
			self.channels[player] = nil
			self.callbacks.notify(player, "Seyahat iptal edildi: hareket, savaş veya karakter değişimi.")
			self.callbacks.state(player)
		end
	end
end
function TravelService:remove(player) self.channels[player], self.last[player] = nil, nil end
return TravelService
