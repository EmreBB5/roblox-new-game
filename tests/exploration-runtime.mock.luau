-- Actual exploration service orchestration with simulated players and prompts.
return function(CONFIG_SOURCE, RULES_SOURCE, SERVICE_SOURCE, loadSource, PROGRESSION_SOURCE)
local Config = assert(loadSource(CONFIG_SOURCE))()
local Exploration = assert(loadSource(RULES_SOURCE))()
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
	local f = {clock = 100, alive = true, trusted = true, saved = 0, notified = 0, states = 0, opened = 0, cleared = false, lastCombat = -math.huge, lastDamage = -math.huge}
	f.player, f.root = {}, {Position = point(0, 3, 24)}
	f.profile = Progression.newProfile()
	f.profiles = {[f.player] = {data = f.profile}}
	local prompts = {}
	local world = {ExplorationSites = {}}
	for id in Config.ExplorationSites do
		local discovery = {Connect = function(self, callback) self.callback = callback end}
		local chest = {Connect = function(self, callback) self.callback = callback end}
		world.ExplorationSites[id] = {discoveryPosition = point(0, 3, 24), chestPosition = point(0, 3, -12),
			discoveryPrompt = {Triggered = discovery}, chestPrompt = {Triggered = chest}}
		prompts[id] = {discovery = discovery, chest = chest}
	end
	local env = setmetatable({
		game = {GetService = function() return {Shared = {GameConfig = "config", Exploration = "exploration", Progression = "progression"}} end},
		require = function(id) return ({config = Config, exploration = Exploration, progression = Progression})[id] end,
		workspace = {GetServerTimeNow = function() return f.clock end},
	}, {__index = getfenv()})
	local chunk = assert(loadSource(SERVICE_SOURCE))
	setfenv(chunk, env)
	f.service = chunk().new(world, {
		profiles = f.profiles,
		clear = function() return f.cleared end,
		combatInfo = function() return f.lastCombat, f.lastDamage end,
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
for _, reason in {"far", "dead", "untrusted", "unloaded"} do
	f = fixture()
	if reason == "far" then f.root.Position = point(14.01, 3, 24)
	elseif reason == "dead" then f.alive = false
	elseif reason == "untrusted" then f.trusted = false
	else f.profiles[f.player] = nil end
	f.service:request(f.player, "discover", "forest_ruins")
	eq(f.profile.exploration.discovered.forest_ruins, nil, reason .. " cannot discover")
	eq(f.saved, 0, reason .. " cannot persist mutation")
end
f = fixture()
f.service:request(f.player, "admin", "forest_ruins")
f.service:request(f.player, "discover", {})
f.service:request(f.player, "discover", "admin")
eq(f.states, 0, "invalid action/id no mutation or state broadcast")
f.root.Position = point(14, 3, 24)
f.lastCombat = 100
f.prompts.forest_ruins.discovery.callback(f.player)
eq(f.profile.exploration.discovered.forest_ruins, true, "discovery allowed during combat at exact boundary")
eq(f.saved, 1, "discovery saved once")
eq(f.opened, 0, "discovery keeps movement and combat controls available")
f.clock = 101
f.prompts.forest_ruins.discovery.callback(f.player)
eq(f.saved, 1, "known discovery not saved as a new reward")
f.root.Position = point(0, 3, -12)
f.clock = 102
f.cleared = true
f.service:request(f.player, "claim", "forest_ruins")
eq(f.profile.exploration.claimed.forest_ruins, nil, "recent outgoing combat blocks chest")
eq(f.profile.gold, 0, "combat blocked chest grants no gold")
f.clock, f.lastCombat, f.lastDamage = 106, 90, 102
f.service:request(f.player, "claim", "forest_ruins")
eq(f.profile.exploration.claimed.forest_ruins, nil, "recent incoming damage blocks chest")
f.clock = 107
f.root.Position = point(14.01, 3, -12)
f.service:request(f.player, "claim", "forest_ruins")
eq(f.profile.gold, 0, "cleared chest still requires exact source proximity")
f.root.Position = point(14, 3, -12)
f.cleared = false
local _, ready = f.service:snapshot(f.player)
eq(ready.forest_ruins, false, "registered guard state controls snapshot")
f.service:request(f.player, "claim", "forest_ruins")
eq(f.profile.gold, 0, "uncleared guard state rejects reward")
f.clock, f.cleared = 108, true
local discovery, unlocked = f.service:snapshot(f.player)
eq(unlocked.forest_ruins, true, "clear snapshot updates live")
discovery.discovered.forest_ruins = false
eq(f.profile.exploration.discovered.forest_ruins, true, "public discovery snapshot isolated")
-- A guard may respawn after the UI snapshot; request must recheck server state.
f.cleared = false
f.service:request(f.player, "claim", "forest_ruins")
eq(f.profile.exploration.claimed.forest_ruins, nil, "stale clear snapshot cannot bypass respawned guard")
f.clock, f.cleared = 109, true
local level, xp = Progression.addXP(1, 0, Config.ExplorationSites.forest_ruins.XP)
f.prompts.forest_ruins.chest.callback(f.player)
eq(f.profile.exploration.claimed.forest_ruins, true, "native chest prompt commits personal claim")
eq(f.profile.gold, 20, "chest gold exact")
eq(f.profile.materials.wood, 3, "chest material exact")
eq(f.profile.level, level, "chest player level updated")
eq(f.profile.xp, xp, "chest player XP updated")
eq(f.saved, 2, "only discovery and chest reward persisted")
eq(f.focus, "forest_ruins", "successful chest opens matching exploration journal")
eq(next(f.profile.petXP), nil, "chest no pet training")
f.service:request(f.player, "claim", "forest_ruins")
eq(f.saved, 2, "same-tick duplicate throttled")
f.clock = 110
f.prompts.forest_ruins.chest.callback(f.player)
eq(f.saved, 2, "later replay no extra save or reward")
eq(f.profile.gold, 20, "later replay no extra currency")
local snapshot = f.service:snapshot(f.player)
snapshot.claimed.forest_ruins = false
eq(f.profile.exploration.claimed.forest_ruins, true, "public claim snapshot isolated")
local second = {}
f.profiles[second] = {data = Progression.newProfile()}
f.profiles[second].data.exploration.discovered.forest_ruins = true
f.service:request(second, "claim", "forest_ruins")
eq(f.profiles[second].data.gold, 20, "second player receives own claim from same global clear")
eq(f.profile.gold, 20, "second claim cannot alter first player reward")
f.service:remove(f.player)
eq(f.service.last[f.player], nil, "removed player throttle cleared")

f = fixture()
f.profile.exploration.discovered.forest_ruins = true
f.root.Position, f.cleared = point(0, 3, -12), true
f.profile.gold, f.profile.materials.wood = 999999998, 99999999
f.service:request(f.player, "claim", "forest_ruins")
eq(f.profile.gold, 999999999, "high chest currency never reduced")
eq(f.profile.materials.wood, 100000000, "chest material cap")
f = fixture()
f.root.Position, f.cleared = point(0, 3, -12), true
f.service:request(f.player, "claim", "forest_ruins")
eq(f.profile.exploration.claimed.forest_ruins, nil, "clear alone does not bypass personal discovery")
eq(f.saved, 0, "undiscovered chest not persisted as reward")
print("Exploration service orchestration mocks: " .. assertions .. " assertions passed (no Roblox physics)")
end
