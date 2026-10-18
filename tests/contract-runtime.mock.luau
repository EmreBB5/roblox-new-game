-- Actual contract service orchestration with a simulated player and board.
return function(CONFIG_SOURCE, RULES_SOURCE, SERVICE_SOURCE, loadSource, PROGRESSION_SOURCE)
local Config = assert(loadSource(CONFIG_SOURCE))()
local Contracts = assert(loadSource(RULES_SOURCE))()
local Progression = assert(loadSource(PROGRESSION_SOURCE))()
local assertions = 0
local function eq(actual, expected, message)
	assertions += 1
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local vector = {}
local function point(x, y, z) return setmetatable({X = x, Y = y, Z = z}, vector) end
vector.__sub = function(a, b) return point(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vector.__index = function(v, key) return if key == "Magnitude" then math.sqrt(v.X ^ 2 + v.Y ^ 2 + v.Z ^ 2) else nil end
local function fixture()
	local f = {clock = 100, alive = true, trusted = true, saved = 0, notified = 0, states = 0, opened = 0}
	f.player, f.root = {}, {Position = point(0, 3, 0)}
	f.profile = Progression.newProfile()
	f.profiles = {[f.player] = {data = f.profile}}
	local prompts = {}
	local world = {ContractBoards = {}}
	for id in Config.RegionalContracts do
		local signal = {Connect = function(self, callback) self.callback = callback end}
		world.ContractBoards[id] = {position = point(0, 3, 0), prompt = {Triggered = signal}}
		prompts[id] = signal
	end
	local env = setmetatable({
		game = {GetService = function() return {Shared = {GameConfig = "config", Contracts = "contracts", Progression = "progression"}} end},
		require = function(id) return ({config = Config, contracts = Contracts, progression = Progression})[id] end,
		workspace = {GetServerTimeNow = function() return f.clock end},
	}, {__index = getfenv()})
	local chunk = assert(loadSource(SERVICE_SOURCE))
	setfenv(chunk, env)
	f.service = chunk().new(world, {
		profiles = f.profiles,
		living = function() return if f.alive then f.root else nil end,
		trusted = function() return f.trusted end,
		notify = function() f.notified += 1 end,
		save = function() f.saved += 1 end,
		state = function() f.states += 1 end,
		open = function(_, id)
			f.opened += 1
			f.focus = id
		end,
	})
	f.service:connect()
	f.prompts = prompts
	return f
end

local f = fixture()
f.service:recordKill(f.player, "forest")
f.service:recordGather(f.player, "forest")
eq(f.profile.regionalContracts.forest.kills, 0, "preaccept kill gives no progress")
eq(f.profile.regionalContracts.forest.gathers, 0, "preaccept gather gives no progress")
for _, reason in {"far", "dead", "untrusted", "unloaded"} do
	f = fixture()
	if reason == "far" then f.root.Position = point(14.01, 3, 0)
	elseif reason == "dead" then f.alive = false
	elseif reason == "untrusted" then f.trusted = false
	else f.profiles[f.player] = nil end
	f.service:request(f.player, "accept", "forest")
	eq(f.profile.regionalContracts.forest.status, "available", reason .. " cannot accept")
	eq(f.saved, 0, reason .. " cannot save a mutation")
end
f = fixture()
f.service:request(f.player, "admin", "forest")
f.service:request(f.player, "accept", "unknown")
f.service:request(f.player, "accept", {})
eq(f.states, 0, "invalid actions and ids cannot mutate or publish")
f.root.Position = point(14, 3, 0)
f.prompts.forest.callback(f.player)
eq(f.profile.regionalContracts.forest.status, "active", "native prompt accepts at exact boundary")
eq(f.saved, 1, "accept persisted once")
eq(f.focus, "forest", "native prompt opens matching journal card")
for _ = 1, 5 do f.service:recordKill(f.player, "forest") end
for _ = 1, 3 do f.service:recordGather(f.player, "forest") end
local entries, ready = f.service:snapshot(f.player)
eq(ready.forest, false, "undiscovered waypoint keeps contract incomplete")
entries.forest.kills = 0
eq(f.profile.regionalContracts.forest.kills, 5, "snapshot does not alias live progress")
f.clock = 101
f.service:request(f.player, "claim", "forest")
eq(f.profile.gold, 0, "incomplete claim gives no currency")
eq(f.saved, 1, "incomplete claim not persisted as reward")
f.profile.waypoints.forest = true
local _, unlocked = f.service:snapshot(f.player)
eq(unlocked.forest, true, "discovery immediately derives readiness")
f.service:request(f.player, "claim", "forest")
eq(f.profile.gold, 0, "same-tick claim throttled")
f.clock = 102
f.root.Position = point(14.01, 3, 0)
f.service:request(f.player, "claim", "forest")
eq(f.profile.gold, 0, "ready contract still requires board proximity")
f.root.Position = point(0, 3, 0)
local expectedLevel, expectedXP = Progression.addXP(1, 0, Config.RegionalContracts.forest.XP)
f.service:request(f.player, "claim", "forest")
eq(f.profile.regionalContracts.forest.status, "completed", "valid claim completes")
eq(f.profile.gold, Config.RegionalContracts.forest.Gold, "personal gold exact")
eq(f.profile.materials.wood, 3, "personal material reward exact")
eq(f.profile.level, expectedLevel, "reward XP applied through progression")
eq(f.profile.xp, expectedXP, "reward XP remainder exact")
eq(f.saved, 2, "only accept and valid reward saved")
f.clock = 103
f.prompts.forest.callback(f.player)
eq(f.profile.gold, Config.RegionalContracts.forest.Gold, "repeated native prompt cannot repeat reward")
eq(f.saved, 2, "completed contract not saved as new reward")
f.service:recordKill(f.player, "forest")
f.service:recordGather(f.player, "forest")
eq(f.profile.regionalContracts.forest.kills, 5, "completed kill counter stable")
eq(f.profile.regionalContracts.forest.gathers, 3, "completed gather counter stable")
eq(f.profile.regionalContracts.marsh.status, "available", "different region remains independent")
eq(next(f.profile.petXP), nil, "contract does not grant pet XP")
f.service:remove(f.player)
eq(f.service.last[f.player], nil, "leaving player throttle cleaned")
f = fixture()
f.profile.gold, f.profile.materials.wood = 999999998, 99999999
f.service:request(f.player, "accept", "forest")
for _ = 1, 5 do f.service:recordKill(f.player, "forest") end
for _ = 1, 3 do f.service:recordGather(f.player, "forest") end
f.profile.waypoints.forest = true
f.clock = 101
f.service:request(f.player, "claim", "forest")
eq(f.profile.gold, 999999999, "high currency never reduced")
eq(f.profile.materials.wood, 100000000, "material cap preserved")
print("Regional contract service orchestration mocks: " .. assertions .. " assertions passed (no Roblox physics)")
end
