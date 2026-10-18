local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Contracts = require(ReplicatedStorage.Shared.Contracts)
local Progression = require(ReplicatedStorage.Shared.Progression)
local Service = {}
Service.__index = Service
function Service.new(world, callbacks)
	return setmetatable({world = world, callbacks = callbacks, last = {}}, Service)
end
function Service:near(player, id)
	local root = self.callbacks.living(player)
	local board = self.world.ContractBoards[id]
	return root and board and self.callbacks.trusted(player, root) and (root.Position - board.position).Magnitude <= 14
end
function Service:request(player, action, id)
	if type(id) ~= "string" or #id > 32 or not Config.RegionalContracts[id]
		or (action ~= "accept" and action ~= "claim" and action ~= "interact") then return end
	local handle = self.callbacks.profiles[player]
	local time = workspace:GetServerTimeNow()
	if not handle or time - (self.last[player] or -math.huge) < 0.5 or not self:near(player, id) then return end
	self.last[player] = time
	local result
	if action == "accept" then result = Contracts.accept(handle.data, id, Config)
	elseif action == "claim" then result = Contracts.claim(handle.data, id, Config)
	else result = Contracts.interact(handle.data, id, Config) end
	if result.status == "rewarded" then
		handle.data.level, handle.data.xp = Progression.addXP(handle.data.level, handle.data.xp, result.xp or 0)
		self.callbacks.notify(player, "Bölge sözleşmesi tamamlandı! XP, altın ve malzeme kazandın.")
		self.callbacks.save(player)
	elseif result.status == "accepted" then
		self.callbacks.notify(player, "Sözleşme alındı: 5 yaratık yen, 3 kaynak topla ve bölge türbesini keşfet.")
		self.callbacks.save(player)
	elseif result.status == "completed" then self.callbacks.notify(player, "Bu bölgenin sözleşmesi zaten tamamlandı.")
	else self.callbacks.notify(player, "Sözleşme günlüğünde kalan hedeflerini incele.") end
	self.callbacks.state(player)
	self.callbacks.open(player, id)
end
function Service:connect()
	for id, board in self.world.ContractBoards do
		board.prompt.Triggered:Connect(function(player) self:request(player, "interact", id) end)
	end
end
function Service:recordKill(player, regionId)
	local handle = self.callbacks.profiles[player]
	if handle then Contracts.recordKill(handle.data, regionId, Config) end
end
function Service:recordGather(player, regionId)
	local handle = self.callbacks.profiles[player]
	if handle then Contracts.recordGather(handle.data, regionId, Config) end
end
function Service:snapshot(player)
	local handle = self.callbacks.profiles[player]
	local entries, ready = {}, {}
	if handle then
		for id, entry in handle.data.regionalContracts do entries[id] = table.clone(entry) end
		for id in Config.RegionalContracts do ready[id] = Contracts.ready(handle.data, id, Config) end
	end
	return entries, ready
end
function Service:remove(player) self.last[player] = nil end
return Service
