local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Exploration = require(ReplicatedStorage.Shared.Exploration)
local Progression = require(ReplicatedStorage.Shared.Progression)
local Service = {}
Service.__index = Service
function Service.new(world, callbacks)
	return setmetatable({world = world, callbacks = callbacks, last = {}}, Service)
end
function Service:request(player, action, id)
	if (action ~= "discover" and action ~= "claim") or type(id) ~= "string" or #id > 40 or not Config.ExplorationSites[id] then return end
	local handle = self.callbacks.profiles[player]
	local site = self.world.ExplorationSites[id]
	local time = workspace:GetServerTimeNow()
	if not handle or not site or time - (self.last[player] or -math.huge) < 0.5 then return end
	local root = self.callbacks.living(player)
	local position = if action == "discover" then site.discoveryPosition else site.chestPosition
	if not root or not self.callbacks.trusted(player, root) or (root.Position - position).Magnitude > 14 then return end
	self.last[player] = time
	local result
	if action == "discover" then
		result = Exploration.discover(handle.data, id, Config)
	else
		local lastCombat, lastDamage = self.callbacks.combatInfo(player)
		if time - math.max(lastCombat, lastDamage) < 5 then
			self.callbacks.notify(player, "Sandığı açmak için savaş dışında 5 saniye bekle.")
			return
		end
		-- Recheck the actual registered guards at the end of the native prompt,
		-- never trust a public UI snapshot or a client-supplied clear flag.
		result = Exploration.claim(handle.data, id, self.callbacks.clear(id), true, Config)
	end
	if result.status == "rewarded" then
		handle.data.level, handle.data.xp = Progression.addXP(handle.data.level, handle.data.xp, result.xp or 0)
		self.callbacks.notify(player, "Keşif sandığı açıldı! XP, altın ve malzeme kazandın; pet ödülü yok.")
		self.callbacks.save(player)
	elseif result.status == "discovered" then
		self.callbacks.notify(player, "Yeni bir keşif alanı buldun! Sandık için iki muhafızı yen.")
		self.callbacks.save(player)
	else
		local messages = {known = "Bu alanı daha önce keşfettin.", claimed = "Bu kişisel sandığın ödülünü zaten aldın.",
			undiscovered = "Önce keşif işaretiyle etkileşime geç.", guarded = "Sandığı açmak için iki alan muhafızını da yen."}
		if messages[result.status] then self.callbacks.notify(player, messages[result.status]) end
	end
	self.callbacks.state(player)
	-- Discovery leaves movement/combat controls available near the guards.
	if action == "claim" and (result.status == "rewarded" or result.status == "claimed") then self.callbacks.open(player, id) end
end
function Service:connect()
	for id, site in self.world.ExplorationSites do
		site.discoveryPrompt.Triggered:Connect(function(player) self:request(player, "discover", id) end)
		site.chestPrompt.Triggered:Connect(function(player) self:request(player, "claim", id) end)
	end
end
function Service:snapshot(player)
	local handle = self.callbacks.profiles[player]
	local exploration = {discovered = {}, claimed = {}}
	local ready = {}
	if handle then
		exploration.discovered = table.clone(handle.data.exploration.discovered)
		exploration.claimed = table.clone(handle.data.exploration.claimed)
	end
	for id in Config.ExplorationSites do ready[id] = self.callbacks.clear(id) end
	return exploration, ready
end
function Service:remove(player) self.last[player] = nil end
return Service
