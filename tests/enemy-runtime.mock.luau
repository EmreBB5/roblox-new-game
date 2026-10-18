-- Appended to actual source literals by scripts/test-roblox-mocks.py.
-- Deliberately mocks orchestration only: no Roblox physics, streaming, or network.
return function(CONFIG_SOURCE, RULES_SOURCE, SERVICE_SOURCE, loadSource)
local Config = assert(loadSource(CONFIG_SOURCE))()
local Rules = assert(loadSource(RULES_SOURCE))()
local assertions = 0
local function eq(a, b, label)
	assertions += 1
	assert(a == b, label .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local vecMT = {}
local function vec(x, y, z) return setmetatable({X = x, Y = y, Z = z}, vecMT) end
vecMT.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vecMT.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vecMT.__index = function(v, key)
	if key == "Magnitude" then return math.sqrt(v.X ^ 2 + v.Y ^ 2 + v.Z ^ 2) end
	return nil
end
local function fixture(regionId)
	regionId = regionId or "marsh"
	local f = {clock = 100, queue = {}, serial = 0, models = {}, rewards = {}, profiles = {}, players = {}, assists = {}, blocked = false, safe = false, changes = 0}
	local function later(seconds, callback)
		f.serial += 1
		local job = {at = f.clock + seconds, callback = callback, serial = f.serial}
		table.insert(f.queue, job)
		return job
	end
	function f:advance(to)
		assert(to >= self.clock)
		while true do
			table.sort(self.queue, function(a, b) return a.at < b.at or (a.at == b.at and a.serial < b.serial) end)
			local job = self.queue[1]
			if not job or job.at > to then break end
			table.remove(self.queue, 1)
			self.clock = job.at
			job.callback()
		end
		self.clock = to
	end
	local function disposable()
		return {Parent = true, Destroy = function(self) self.Parent = nil end}
	end
	local worldFactory = {}
	function worldFactory.createElite(_, def)
		local model = disposable()
		local root = {Position = vec(def.X, 3, def.Z), Parent = model, SetNetworkOwner = function() end}
		local listeners = {}
		local humanoid = {Parent = model, Health = def.MaxHealth, Died = {Connect = function(_, fn) table.insert(listeners, fn) end}, MoveTo = function() end}
		function humanoid:TakeDamage(damage)
			local before = self.Health
			self.Health = math.max(0, before - damage * (self.damageFactor or 1))
			if before > 0 and self.Health == 0 then for _, fn in listeners do fn() end end
		end
		model.SetAttribute = function() end
		model.FindFirstChildOfClass = function(_, name) return if name == "Humanoid" then humanoid else nil end
		model.FindFirstChild = function(_, name) return if name == "HumanoidRootPart" then root else nil end
		model.PivotTo = function(_, cf) root.Position = cf.Position end
		table.insert(f.models, model)
		return model
	end
	worldFactory.createEnemy = function(_, position, _, id)
		return worldFactory.createElite(nil, {X = position.X, Z = position.Z, MaxHealth = Config.Regions[id].EnemyHealth})
	end
	worldFactory.createEnemyTelegraph = function() return disposable() end
	local env = setmetatable({
		game = {GetService = function() return {Shared = {GameConfig = "config", EnemyRules = "rules"}} end},
		script = {Parent = {World = "world"}},
		require = function(id) return ({config = Config, rules = Rules, world = worldFactory})[id] end,
		workspace = {GetServerTimeNow = function() return f.clock end, Raycast = function()
			return if f.blocked then {Instance = {IsDescendantOf = function() return false end}} else nil
		end},
		task = {delay = later, wait = function(seconds) f.clock += seconds end},
		RaycastParams = {new = function() return {} end}, Enum = {RaycastFilterType = {Exclude = "exclude"}},
		CFrame = {new = function(position) return {Position = position} end}, Vector3 = {zero = vec(0, 0, 0)},
	}, {__index = getfenv()})
	local loadService = assert(loadSource(SERVICE_SOURCE))
	setfenv(loadService, env)
	local Service = loadService()
	local definition = Config.Regions[regionId]
	for index = 1, 3 do
		local player = {UserId = index, trusted = true, root = {Position = vec(definition.X, 3, definition.Z), Parent = {}}}
		player.hp = {Health = 140, TakeDamage = function(self, damage) self.Health -= damage end}
		f.players[index], f.profiles[player] = player, {data = {}}
	end
	f.service = Service.new({EnemyFolder = {}, EnemySpawns = {{position = vec(definition.X, 0, definition.Z), regionId = regionId}}}, {
		profiles = f.profiles,
		
		living = function(player) if player.hp.Health > 0 then
				return player.root, player.hp
			end
			return nil end,
		trusted = function(player) return player.trusted end,
		safe = function() return f.safe end,
		assists = function(player) return f.assists[player] or {} end,
		reward = function(player, _, personal) table.insert(f.rewards, {player = player, personal = personal}) end,
	}, {})
	f.current = f.service.slots[1]
	return f
end
local f = fixture("forest")
f.service:cast(f.current, f.players[1].root, f.players[1])
eq(f.players[1].hp.Health, 130, "forest melee resolves immediately")
eq(f.players[2].hp.Health, 140, "forest melee hits only selected target")
eq(#f.queue, 0, "forest melee does not schedule delayed hit")

f = fixture("frost")
f.service:cast(f.current, f.players[1].root, f.players[1])
f:advance(100.649)
eq(f.players[1].hp.Health, 140, "frost melee waits full windup")
f:advance(100.65)
eq(f.players[1].hp.Health, 118, "frost melee resolves at windup")

for _, region in {"marsh", "volcanic", "desert"} do
	f = fixture(region)
	f.service:cast(f.current, f.players[1].root, f.players[1])
	local callback = f.queue[1].callback
	local deadline = 100 + Config.EnemyBehaviors[region].Windup
	f:advance(deadline - 0.001)
	eq(f.players[1].hp.Health, 140, region .. " cannot hit early")
	f:advance(deadline)
	eq(f.players[1].hp.Health, 140 - Config.EnemyBehaviors[region].Damage, region .. " applies configured damage")
	callback()
	eq(f.players[1].hp.Health, 140 - Config.EnemyBehaviors[region].Damage, region .. " repeated callback cannot hit again")
end

f = fixture("desert")
f.service:cast(f.current, f.players[1].root, f.players[1])
f.players[1].root.Position += vec(8, 0, 0)
f:advance(101)
eq(f.players[1].hp.Health, 140, "moving away from fixed ranged target dodges")
eq(f.players[2].hp.Health, 114, "original locked target disk remains dangerous")

for _, reason in {"deferred-death", "death", "generation", "closed", "identity", "leash"} do
	f = fixture()
	f.current.lastAttacker = f.players[1]
	f.service:cast(f.current, f.players[1].root, f.players[1])
	local warning = f.current.warning
	if reason == "deferred-death" then f.current.humanoid.Health = 0
	elseif reason == "death" then f.current.humanoid:TakeDamage(10000)
	elseif reason == "generation" then f.current.generation += 1
	elseif reason == "closed" then f.service:close()
	elseif reason == "identity" then f.service:spawn(1, f.current.entry)
	elseif reason == "leash" then
		f.current.humanoid.Health = 1
		f.current.root.Position += vec(101, 0, 0)
		f.service:update()
		eq(f.current.humanoid.Health, 150, "normal leash resets HP")
		eq(f.current.lastAttacker, nil, "normal leash clears prior contribution")
		eq((f.current.root.Position - f.current.origin).Magnitude, 0, "normal leash returns origin")
	end
	f:advance(102)
	eq(f.players[1].hp.Health, 140, reason .. " cancels old enemy cast")
	if reason == "deferred-death" or reason == "death" or reason == "closed" or reason == "leash" then
		eq(warning.Parent, nil, reason .. " destroys warning")
	end
end

for _, reason in {"LOS", "safe", "dead", "untrusted"} do
	f = fixture()
	f.service:cast(f.current, f.players[1].root, f.players[1])
	if reason == "LOS" then f.blocked = true
	elseif reason == "safe" then f.safe = true
	elseif reason == "dead" then f.players[1].hp.Health = 0
	elseif reason == "untrusted" then f.players[1].trusted = false end
	local before = f.players[1].hp.Health
	f:advance(102)
	eq(f.players[1].hp.Health, before, reason .. " enemy target excluded")
end

f = fixture()
f.current.lastAttacker = f.players[1]
f.current.humanoid:TakeDamage(10000)
eq(#f.rewards, 1, "normal enemy death rewards once")
f.service:finish(f.current)
eq(#f.rewards, 1, "normal finish replay does not reward twice")
f:advance(107.999)
eq(f.service.slots[1], f.current, "normal respawn not early")
f:advance(108)
eq(f.service.slots[1] ~= f.current, true, "normal respawn after eight seconds")
eq(#f.models, 2, "normal respawn single replacement")

f = fixture()
f.service:finish(f.current)
f.service:close()
f:advance(120)
eq(#f.models, 1, "closed normal service cannot respawn")
print("Enemy service orchestration mocks: " .. assertions .. " assertions passed (no Roblox physics)")
end
