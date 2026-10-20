local Config = require("../src/shared/GameConfig")
local Profile = require("../src/shared/Progression")
local Journey = require("../src/shared/JourneyRules")
local n = 0
local function eq(a, b, label)
	n += 1
	assert(a == b, label .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local function find(options, id)
	for _, option in options do if option.id == id then return option end end
	return nil
end
local function finished()
	local state = Profile.newProfile()
	state.level, state.questStatus = 12, "completed"
	state.expedition.stage = #Config.Expedition + 1
	for id in Config.Waypoints do state.waypoints[id] = true end
	for id in Config.ExplorationSites do state.exploration.discovered[id], state.exploration.claimed[id] = true, true end
	for _, entry in state.regionalContracts do entry.status = "completed" end
	return state
end
local world = {serverNow = 1000, bosses = {}, sites = {}}
local state = Profile.newProfile()
eq(#Journey.options({}, world, 0, 0, Config), 0, "unloaded profile gives no fake quest")
local options = Journey.options(state, world, 0, 0, Config)
eq(options[1].id, "quest:accept", "new player directed to Eldrin")
eq(options[1].x, 15, "quest giver X")
eq(options[1].z, 0, "quest giver Z")
state.questStatus = "active"
eq(Journey.options(state, world, 0, 0, Config)[1].id, "quest:hunt", "active starter quest directs to forest")
state.questStatus = "return"
eq(Journey.options(state, world, 0, 0, Config)[1].id, "quest:return", "ready starter quest directs back to keeper")
state = finished()
options = Journey.options(state, world, 0, 0, Config)
eq(find(options, "quest:accept"), nil, "completed quest does not loop into acceptance")
eq(find(options, "quest:return"), nil, "completed quest no false turn-in")
eq(options[1].id, "fallback:village", "completed profile gets safe fallback")
state.expedition.stage, state.expedition.progress = 2, Config.Expedition[2].Target
options = Journey.options(state, world, 0, 0, Config)
eq(options[1].id, "expedition:claim", "ready expedition prioritized")
eq(options[1].panel, "C", "expedition opens character panel")
eq(options[1].x, nil, "UI turn-in does not invent world destination")
state = finished()
state.regionalContracts.marsh = {status = "active", kills = 5, gathers = 3}
options = Journey.options(state, world, 0, 0, Config)
eq(options[1].id, "contract:claim:marsh", "ready contract directs to board")
eq(options[1].panel, "C", "regional journal panel mapping")
state.waypoints.marsh = nil
state.regionContractReady = {marsh = true}
options = Journey.options(state, world, 0, 0, Config)
eq(find(options, "contract:claim:marsh"), nil, "stale ready snapshot cannot override missing discovery")
eq(find(options, "contract:waypoint:marsh") ~= nil, true, "missing shrine becomes contract subgoal")
state.waypoints.marsh = true
state.regionalContracts.marsh.kills = 2
options = Journey.options(state, world, 0, 0, Config)
eq(find(options, "contract:kill:marsh") ~= nil, true, "incomplete contract kill goal")
state.regionalContracts.marsh.kills, state.regionalContracts.marsh.gathers = 5, 1
options = Journey.options(state, world, 0, 0, Config)
eq(find(options, "contract:gather:marsh") ~= nil, true, "gather subgoal after kills")
state.regionalContracts.marsh.status = "completed"
eq(find(Journey.options(state, world, 0, 0, Config), "contract:claim:marsh"), nil, "completed contract hidden")

local boss = {id = "thornwarden", status = "alive", health = 3500, maxHealth = 3500, occurrenceAt = 900, despawnAt = 1100}
world.bosses = {boss}
state = finished()
options = Journey.options(state, world, 0, 0, Config)
eq(find(options, "boss:thornwarden") ~= nil, true, "eligible live boss suggested")
eq(find(options, "boss:thornwarden").panel, "M", "boss map panel mapping")
for _, mode in {"dead", "expired", "zero", "waiting", "unknown"} do
	local changed = table.clone(boss)
	if mode == "dead" then changed.status = "defeated"
	elseif mode == "expired" then changed.despawnAt = 1000
	elseif mode == "zero" then changed.health = 0
	elseif mode == "waiting" then changed.status = "waiting"
	else changed.id = "fake" end
	world.bosses = {changed}
	eq(find(Journey.options(state, world, 0, 0, Config), "boss:thornwarden"), nil, mode .. " boss not suggested")
end
world.bosses = {{id = "ember_drake", status = "alive", health = 100, occurrenceAt = 900, despawnAt = 1100}}
state.level = 1
eq(find(Journey.options(state, world, 0, 0, Config), "boss:ember_drake"), nil, "boss requires region level")
state.level = Config.Regions.volcanic.EnemyLevel
eq(find(Journey.options(state, world, 0, 0, Config), "boss:ember_drake") ~= nil, true, "boss region level boundary")
state.questStatus, state.expedition.stage = "active", 4
eq(find(Journey.options(state, world, 0, 0, Config), "boss:ember_drake") ~= nil, true, "boss-stage expedition can recommend boss")
world.bosses = {}
state = finished()
state.expedition.stage, state.expedition.progress = 4, 0
options = Journey.options(state, world, 0, 0, Config)
eq(find(options, "expedition:boss_wait") ~= nil, true, "boss objective waits when no suitable live boss")
state.expedition.stage = 5
eq(find(Journey.options(state, world, 0, 0, Config), "expedition:stage:5") ~= nil, true, "regional expedition destination")

state = finished()
state.waypoints.forest = nil
local shrine = Config.Waypoints.forest.Position
options = Journey.options(state, world, shrine.x, shrine.z, Config)
eq(find(options, "waypoint:forest") ~= nil, true, "near unexplored waypoint suggested")
state.waypoints.forest = true
eq(find(Journey.options(state, world, shrine.x, shrine.z, Config), "waypoint:forest"), nil, "discovered waypoint hidden")
local site = Config.ExplorationSites.forest_ruins
local originalSiteX = site.X
state.exploration.discovered.forest_ruins, state.exploration.claimed.forest_ruins = nil, nil
options = Journey.options(state, world, site.X, site.Z, Config)
eq(find(options, "explore:forest_ruins") ~= nil, true, "undiscovered camp suggested")
state.exploration.discovered.forest_ruins = true
options = Journey.options(state, world, site.X, site.Z, Config)
eq(find(options, "chest:forest_ruins") ~= nil, true, "discovered personal chest suggested")
eq(find(options, "explore:forest_ruins"), nil, "discovered camp no longer discovery goal")
state.exploration.claimed.forest_ruins = true
eq(find(Journey.options(state, world, site.X, site.Z, Config), "chest:forest_ruins"), nil, "claimed personal chest hidden")
state.exploration.discovered.desert_caravan, state.exploration.claimed.desert_caravan = nil, nil
eq(find(Journey.options(state, world, 0, 0, Config), "explore:desert_caravan"), nil, "distant optional objective not spammed")

for _, coordinate in {0/0, math.huge, -math.huge, Config.MapBounds.MaxX + 1} do
	eq(#Journey.options(Profile.newProfile(), world, coordinate, 0, Config), 0, "invalid player X gives safe empty list")
end
eq(#Journey.options(Profile.newProfile(), world, 0, Config.MapBounds.MinZ - 1, Config), 0, "out of bounds Z rejected")
local malformed = Profile.newProfile()
malformed.level = 0/0
eq(#Journey.options(malformed, world, 0, 0, Config), 0, "NaN player level rejected")
malformed = Profile.newProfile()
malformed.questStatus = "admin"
eq(#Journey.options(malformed, world, 0, 0, Config), 0, "unknown quest status rejected")
local original = Profile.newProfile()
original.questStatus = "completed"
options = Journey.options(original, world, -200, -200, Config)
eq(#options <= 6, true, "options capped at six")
local again = Journey.options(original, world, -200, -200, Config)
for index, item in options do
	eq(item.id, again[index].id, "repeated identical inputs stable ordering")
	eq(type(item.title), "string", "option has user-facing title")
	eq(type(item.detail), "string", "option has user-facing detail")
	if item.x ~= nil then
		eq(item.x >= Config.MapBounds.MinX and item.x <= Config.MapBounds.MaxX and item.z >= Config.MapBounds.MinZ and item.z <= Config.MapBounds.MaxZ, true, "every destination inside map")
	end
end
if options[1] then options[1].title, options[1].x = "mutated", 1e99 end
local refreshed = Journey.options(original, world, -200, -200, Config)
eq(refreshed[1].title ~= "mutated", true, "returned options do not alias future output")
eq(original.questStatus, "completed", "input quest state not mutated")
eq(original.exploration.discovered.forest_ruins, nil, "recommendation cannot grant discovery")
eq(Config.ExplorationSites.forest_ruins.X, originalSiteX, "config not mutated")
local custom = table.clone(Config)
custom.Waypoints = table.clone(Config.Waypoints)
custom.Waypoints.forest = {Name = "Forest", RegionId = "forest", Position = {x = 100, y = 0, z = 100}}
custom.Waypoints.marsh = {Name = "Marsh", RegionId = "marsh", Position = {x = 100, y = 0, z = 100}}
local tieState = finished()
tieState.waypoints.forest, tieState.waypoints.marsh = nil, nil
local tied = Journey.options(tieState, world, 0, 0, custom)
eq(tied[1].id, "waypoint:forest", "equal-distance ties use stable ID order")
eq(tied[2].id, "waypoint:marsh", "equal-distance second ID stable")
local nearFirst = table.clone(custom)
nearFirst.Waypoints = table.clone(custom.Waypoints)
nearFirst.Waypoints.forest = {Name = "Forest", RegionId = "forest", Position = {x = 200, y = 0, z = 100}}
local nearest = Journey.options(tieState, world, 0, 0, nearFirst)
eq(nearest[1].id, "waypoint:marsh", "distance beats lexical order within same priority")
state = finished()
state.expedition.stage, state.expedition.progress = 1, 0
for _, entry in state.regionalContracts do entry.status, entry.kills, entry.gathers = "active", 0, 0 end
local crowded = Journey.options(state, world, 0, 0, Config)
eq(#crowded, 6, "more than six real goals capped exactly")
local seen = {}
for _, item in crowded do
	eq(seen[item.id], nil, "stable IDs unique within capped result")
	seen[item.id] = true
end
state = finished()
state.expedition.stage, state.expedition.progress = 2, 5
state.regionalContracts.frost = {status = "active", kills = 5, gathers = 3}
world.bosses = {boss}
state.questStatus = "return"
eq(Journey.options(state, world, 0, 0, Config)[1].id, "quest:return", "keeper turn-in wins simultaneous ready goals")
state.questStatus = "completed"
eq(Journey.options(state, world, 0, 0, Config)[1].id, "expedition:claim", "expedition turn-in wins other ready goals")
state.expedition.stage = #Config.Expedition + 1
eq(Journey.options(state, world, 0, 0, Config)[1].id, "contract:claim:frost", "board turn-in wins live boss")
state.regionalContracts.frost.status = "completed"
eq(Journey.options(state, world, 0, 0, Config)[1].id, "boss:thornwarden", "live boss wins low-priority exploration")
eq(find(Journey.options(state, world, 0, 0, Config, 1200), "boss:thornwarden"), nil, "extrapolated current time expires stale boss snapshot")
local futureBoss = table.clone(boss)
futureBoss.occurrenceAt = 1001
world.bosses = {futureBoss}
eq(find(Journey.options(state, world, 0, 0, Config), "boss:thornwarden"), nil, "future occurrence not treated as alive encounter")
world.bosses = {table.clone(boss)}
world.bosses[1].health = 0/0
eq(find(Journey.options(state, world, 0, 0, Config), "boss:thornwarden"), nil, "NaN boss health not suggested")
eq(world.bosses[1].status, "alive", "advisory cannot mutate world boss status")
local broken = table.clone(Config)
broken.MapBounds = {MinX = 10, MaxX = -10, MinZ = -5, MaxZ = 5}
eq(#Journey.options(state, world, 0, 0, broken), 0, "inverted map bounds safe empty")
eq(#Journey.options(nil, world, 0, 0, Config), 0, "non-table profile safe empty")
eq(#Journey.options(state, world, 0, 0, nil), 0, "missing config safe empty")
local pinWorld = {serverNow = 1000, bosses = {}, sites = {}}
local pinState = finished()
pinState.expedition.stage, pinState.expedition.progress = 1, 0
for _, entry in pinState.regionalContracts do entry.status, entry.kills, entry.gathers = "active", 0, 0 end
pinState.waypoints.desert = nil
local autoSix = Journey.options(pinState, pinWorld, 0, 0, Config, 1000)
eq(#autoSix, 6, "six automatic goals before pin")
eq(find(autoSix, "waypoint:desert"), nil, "distant low-priority pin not automatically listed")
local withPin = Journey.options(pinState, pinWorld, 0, 0, Config, 1000, "waypoint:desert")
eq(#withPin, 6, "pinned result still respects six cap")
for index = 1, 5 do eq(withPin[index].id, autoSix[index].id, "pin outside cap preserves first five automatic priorities") end
eq(withPin[6].id, "waypoint:desert", "valid distant pin retained as sixth choice")
local shifted = Journey.options(pinState, pinWorld, -500, -500, Config, 1000, "waypoint:desert")
eq(find(shifted, "waypoint:desert") ~= nil, true, "movement and changed distance ordering cannot discard unfinished pin")
local already = Journey.options(pinState, pinWorld, 0, 0, Config, 1000, autoSix[2].id)
for index = 1, 6 do eq(already[index].id, autoSix[index].id, "pin already within cap does not reorder priorities") end
pinState = finished()
pinState.exploration.discovered.forest_ruins, pinState.exploration.claimed.forest_ruins = nil, nil
eq(find(Journey.options(pinState, pinWorld, 0, 0, Config), "explore:forest_ruins"), nil, "distant camp hidden without pin")
eq(find(Journey.options(pinState, pinWorld, 0, 0, Config, 1000, "explore:forest_ruins"), "explore:forest_ruins") ~= nil, true, "valid camp pin bypasses optional distance")
pinState.exploration.discovered.forest_ruins = true
eq(find(Journey.options(pinState, pinWorld, 0, 0, Config, 1000, "explore:forest_ruins"), "explore:forest_ruins"), nil, "discovered objective pin expires")
eq(find(Journey.options(pinState, pinWorld, 0, 0, Config, 1000, "chest:forest_ruins"), "chest:forest_ruins") ~= nil, true, "unclaimed chest pin bypasses optional distance")
pinState.exploration.claimed.forest_ruins = true
eq(find(Journey.options(pinState, pinWorld, 0, 0, Config, 1000, "chest:forest_ruins"), "chest:forest_ruins"), nil, "completed personal chest pin expires")
pinState.waypoints.desert = true
eq(find(Journey.options(pinState, pinWorld, 0, 0, Config, 1000, "waypoint:desert"), "waypoint:desert"), nil, "discovered waypoint pin expires")
for _, badPin in {"waypoint:admin", {}, false, string.rep("x", 81)} do
	local invalid = Journey.options(pinState, pinWorld, 0, 0, Config, 1000, badPin)
	eq(#invalid, 1, "invalid pin does not create extra objectives")
	eq(invalid[1].id, "fallback:village", "invalid pin safely falls back")
end
pinWorld.bosses = {boss}
eq(find(Journey.options(pinState, pinWorld, 0, 0, Config, 1200, "boss:thornwarden"), "boss:thornwarden"), nil, "pin cannot keep expired boss alive")
pinState.exploration.discovered.forest_ruins = nil
eq(find(Journey.options(pinState, pinWorld, 0, 0, Config, 1000, "explore:forest_ruins"), "explore:forest_ruins"), nil, "claimed completion overrides malformed missing discovery even with pin")
print("Journey recommendations: " .. n .. " assertions passed")
