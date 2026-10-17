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
local function fixture(withChanged)
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
	worldFactory.createEliteTelegraph = function() return disposable() end
	local env = setmetatable({
		game = {GetService = function() return {Shared = {GameConfig = "config", EliteRules = "rules"}} end},
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
	local definition = Config.Elites.frost_warden
	for index = 1, 3 do
		local player = {UserId = index, trusted = true, root = {Position = vec(definition.X, 3, definition.Z), Parent = {}}}
		player.hp = {Health = 140, TakeDamage = function(self, damage) self.Health -= damage end}
		f.players[index], f.profiles[player] = player, {data = {}}
	end
	f.service = Service.new({EnemyFolder = {}}, {
		profiles = f.profiles,
		changed = if withChanged ~= false then function() f.changes += 1 end else nil,
		living = function(player) if player.hp.Health > 0 then
				return player.root, player.hp
			end
			return nil end,
		trusted = function(player) return player.trusted end,
		safe = function() return f.safe end,
		assists = function(player) return f.assists[player] or {} end,
		reward = function(player, _, personal) table.insert(f.rewards, {player = player, personal = personal}) end,
	})
	f.current = f.service.encounters.frost_warden
	return f
end

local f = fixture()
f.service:cast(f.current, f.players[1].root)
local warning = f.current.warning
local callback = f.queue[1].callback
f:advance(101.49)
eq(f.players[1].hp.Health, 140, "cast cannot hit before windup")
f:advance(101.5)
for _, player in f.players do eq(player.hp.Health, 112, "one AoE hits each valid player") end
eq(warning.Parent, nil, "resolved warning destroyed")
eq(f.current.channel, nil, "resolved channel cleared")
callback()
for _, player in f.players do eq(player.hp.Health, 112, "duplicate callback cannot hit twice") end

for _, reason in {"generation", "identity", "closed", "death", "leash"} do
	f = fixture()
	f.service:cast(f.current, f.players[1].root)
	local castWarning = f.current.warning
	if reason == "generation" then f.current.generation += 1
	elseif reason == "identity" then f.service:spawn("frost_warden", Config.Elites.frost_warden)
	elseif reason == "closed" then f.service:close()
	elseif reason == "death" then f.current.humanoid:TakeDamage(900)
	elseif reason == "leash" then
		f.current.participants[f.players[1]] = {damage = 40, hits = 2}
		f.current.humanoid.Health = 450
		f.current.root.Position += vec(131, 0, 0)
		f.service:update()
		eq(f.current.humanoid.Health, 900, "leash resets health")
		eq(next(f.current.participants), nil, "leash resets contributions")
		eq((f.current.root.Position - f.current.origin).Magnitude, 0, "leash returns origin")
	end
	f:advance(102)
	eq(f.players[1].hp.Health, 140, reason .. " cancels stale delayed damage")
	if reason == "closed" or reason == "death" or reason == "leash" then eq(castWarning.Parent, nil, reason .. " cleans warning") end
end

f = fixture()
f.service:cast(f.current, f.players[1].root)
f.current.humanoid.Health = 0 -- Died deliberately deferred; status remains alive.
eq(f.current.status, "alive", "deferred death callback leaves prior status")
f:advance(102)
eq(f.players[1].hp.Health, 140, "zero-HP elite cannot land deferred cast")

for _, reason in {"LOS", "safe", "dead", "untrusted", "outside"} do
	f = fixture()
	f.service:cast(f.current, f.players[1].root)
	if reason == "LOS" then f.blocked = true
	elseif reason == "safe" then f.safe = true
	elseif reason == "dead" then f.players[1].hp.Health = 0
	elseif reason == "untrusted" then f.players[1].trusted = false
	elseif reason == "outside" then f.players[1].root.Position += vec(15, 0, 0) end
	local expected = f.players[1].hp.Health
	f:advance(102)
	eq(f.players[1].hp.Health, expected, reason .. " excludes delayed target")
end

f = fixture()
local first, second, assist = f.players[1], f.players[2], f.players[3]
f.current.participants[first] = {damage = 20, hits = 2}
f.current.participants[second] = {damage = 20, hits = 2}
f.assists[first], f.assists[second] = {second, assist, assist}, {first, assist}
f.service:finish(f.current)
eq(#f.rewards, 3, "union rewards each qualifying or assisted member once")
local modes = {}
for _, reward in f.rewards do modes[reward.player] = reward.personal end
eq(modes[first], true, "first qualifier receives full reward")
eq(modes[second], true, "full participation overrides party assistance")
eq(modes[assist], false, "shared assistant receives only assist reward")
f.service:finish(f.current)
eq(#f.rewards, 3, "finish replay no extra rewards")
local deadModel = f.current.model
f:advance(102.99)
eq(deadModel.Parent ~= nil, true, "corpse not removed early")
f:advance(103)
eq(deadModel.Parent, nil, "corpse removed after three seconds")
f:advance(189.99)
eq(f.service.encounters.frost_warden, f.current, "respawn not before 90 seconds")
f:advance(190)
eq(f.service.encounters.frost_warden ~= f.current, true, "respawn after 90 seconds")
eq(#f.models, 3, "one replacement spawned")

f = fixture()
f.current.participants[f.players[1]] = {damage = 20, hits = 2}
f.service:finish(f.current)
f.service:close()
f:advance(200)
eq(#f.models, 2, "closed service cannot respawn")

f = fixture()
local model, player = f.current.model, f.players[1]
f.service:damage(model, player, -4)
eq(f.current.participants[player], nil, "negative damage not counted")
f.service:damage(model, player, 899)
eq(f.current.participants[player].damage, 899, "accepted contribution recorded")
eq(f.current.participants[player].hits, 1, "one accepted hit recorded")
f.service:damage(model, player, 10000)
eq(f.current.participants[player].damage, 900, "overkill contribution clamped to remaining HP")
eq(f.current.participants[player].hits, 2, "overkill adds only one accepted hit")
eq(#f.rewards, 1, "two accepted hits grant personal reward")
f.service:damage(model, player, 10000)
eq(f.current.participants[player].hits, 2, "damage after death not counted")
eq(#f.rewards, 1, "dead encounter cannot duplicate reward")
f = fixture()
local protected, protectedPlayer = f.current, f.players[1]
protected.humanoid.damageFactor = 0
eq(f.service:damage(protected.model, protectedPlayer, 30), 0, "shielded target reports zero accepted damage")
eq(protected.participants[protectedPlayer].damage, 0, "shielded damage contribution rolled back")
eq(protected.participants[protectedPlayer].hits, 0, "shielded hit not credited")
protected.humanoid.damageFactor = 0.5
eq(f.service:damage(protected.model, protectedPlayer, 30), 15, "actual HP delta returned")
eq(protected.participants[protectedPlayer].damage, 15, "partial accepted damage contribution")
eq(protected.participants[protectedPlayer].hits, 1, "partially accepted hit counted once")
eq(f.service:damage(protected.model, protectedPlayer, 0/0), 0, "NaN damage rejected")
eq(f.service:damage(protected.model, protectedPlayer, math.huge), 0, "infinite damage rejected")
f.service:close()
eq(f.service:damage(protected.model, protectedPlayer, 30), 0, "closed service damage rejected")

f = fixture()
f.service:finish(f.current)
f.service:spawn("frost_warden", Config.Elites.frost_warden)
local replacement = f.service.encounters.frost_warden
f:advance(200)
eq(f.service.encounters.frost_warden, replacement, "stale respawn cannot replace newer encounter")
eq(#f.models, 3, "stale respawn adds no extra model")
f = fixture()
local updates = f.changes
f.service:cast(f.current, f.players[1].root)
eq(f.changes, updates + 1, "cast start broadcasts telegraph immediately")
f:advance(102)
eq(f.changes, updates + 2, "cast completion broadcasts cleared telegraph")
updates = f.changes
f.service:finish(f.current)
eq(f.changes, updates + 1, "finish broadcasts defeated state immediately")
f:advance(191.99)
eq(f.changes, updates + 1, "respawn broadcast not early")
f:advance(192)
eq(f.changes, updates + 2, "respawn broadcasts new encounter")

f = fixture()
f.service:cast(f.current, f.players[1].root)
updates = f.changes
f.current.root.Position += vec(131, 0, 0)
f.service:update()
eq(f.changes, updates + 1, "leash broadcasts reset and cancelled warning")
f:advance(102)
eq(f.changes, updates + 1, "cancelled stale callback emits no extra update")

f = fixture()
f.service:cast(f.current, f.players[1].root)
updates = f.changes
f.current.humanoid.Health = 0
f:advance(102)
eq(f.changes, updates + 1, "deferred death cancellation broadcasts cleared warning")
eq(f.current.warning, nil, "deferred death removes pending warning handle")
eq(f.current.channel, nil, "deferred death clears pending channel")

f = fixture(false)
f.service:cast(f.current, f.players[1].root)
f:advance(102)
eq(f.players[1].hp.Health, 112, "changed callback remains optional")
print("Elite service orchestration mocks: " .. assertions .. " assertions passed (no Roblox physics)")

end
