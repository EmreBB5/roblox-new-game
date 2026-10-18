-- Runs the actual PlayerActions target methods with deterministic registry/LOS
-- inputs. This is an orchestration regression test, not Roblox raycast physics.
return function(CONFIG_SOURCE, _RULES_SOURCE, SERVICE_SOURCE, loadSource)
local Config = assert(loadSource(CONFIG_SOURCE))()
local assertions = 0
local function eq(actual, expected, label)
	assertions += 1
	assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local vectorMT = {}
local function vec(x, y, z) return setmetatable({X = x, Y = y, Z = z}, vectorMT) end
vectorMT.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vectorMT.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vectorMT.__index = function(v, key)
	if key == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
	return nil
end
local function key(position) return tostring(position.X) .. ":" .. tostring(position.Y) .. ":" .. tostring(position.Z) end
local function fixture()
	local f = {enemies = {}, bosses = {targets = {}}, elites = {targets = {}}, byPosition = {}, blocked = {}, rays = 0}
	f.root = {Position = vec(0, 3, 0)}
	f.player = {Character = {}}
	function f:model(name, distance, registry, className)
		local model = {_instance = true, Name = name, Parent = true, className = className or "Model"}
		model.IsA = function(self, class) return self.className == class end
		model.root = {Position = vec(distance, 3, 0), Parent = model}
		model.humanoid = {Health = 100, Parent = model}
		model.FindFirstChild = function(self, child) return if child == "HumanoidRootPart" then self.root else nil end
		model.FindFirstChildOfClass = function(self, class) return if class == "Humanoid" then self.humanoid else nil end
		self.byPosition[key(model.root.Position)] = model
		if registry then registry[model] = {} end
		return model
	end
	local originalTypeof = typeof
	local env = setmetatable({
		game = {GetService = function() return {Shared = {
			GameConfig = "config", Combat = "combat", Campaign = "campaign", Crafting = "crafting", Progression = "progression",
		}} end},
		script = {Parent = {World = "world"}},
		require = function(id) return if id == "config" then Config else {} end,
		typeof = function(value) return if type(value) == "table" and value._instance then "Instance" else originalTypeof(value) end,
		workspace = {Raycast = function(_, origin, direction, params)
			f.rays += 1
			local model = f.byPosition[key(origin + direction)]
			local blocked = f.blocked[model]
			if blocked then return {Instance = {IsDescendantOf = function() return false end}} end
			-- A hit on the target's own child is valid; a nil hit is also valid.
			if model and model.hitOwnChild then
				return {Instance = {IsDescendantOf = function(_, candidate) return candidate == model end}}
			end
			eq(params.FilterDescendantsInstances[1], f.player.Character, "attacker excluded from LOS")
			return nil
		end},
		RaycastParams = {new = function() return {} end}, Enum = {RaycastFilterType = {Exclude = "exclude"}},
	}, {__index = getfenv()})
	local constructor = assert(loadSource(SERVICE_SOURCE))
	setfenv(constructor, env)
	local Actions = constructor()
	f.actions = Actions.new({}, {enemies = f.enemies, bosses = f.bosses, elites = f.elites})
	return f
end

-- Selection is explicit: picking a farther valid enemy must beat a nearer mob,
-- regardless of which registry it belongs to.
local f = fixture()
local nearest = f:model("normal near", 2, f.enemies)
local boss = f:model("boss", 6, f.bosses.targets)
local elite = f:model("elite", 9, f.elites.targets)
local selected = f:model("explicit normal", 11, f.enemies)
local auto = f.actions:targets(f.player, f.root, 12, 1, nil)
eq(#auto, 1, "nil selection gives one auto target")
eq(auto[1].model, nearest, "nil selection picks nearest across registries")
for _, preferred in {selected, boss, elite} do
	local result = f.actions:targets(f.player, f.root, 12, 1, preferred)
	eq(#result, 1, "valid explicit selection accepted")
	eq(result[1].model, preferred, "explicit selection never replaced by closer mob")
end
local area = f.actions:targets(f.player, f.root, 12, 3, selected)
eq(#area, 3, "area caps total targets at three")
eq(area[1].model, selected, "area puts preferred first")
eq(area[2].model, nearest, "area adds closest remaining target")
eq(area[3].model, boss, "area adds next closest remaining target")
local seen = {}
for _, hit in area do eq(seen[hit.model], nil, "area contains no duplicate model"); seen[hit.model] = true end
-- Even if the preferred model appears in another registry during a handoff,
-- it must not consume a second area slot.
f.bosses.targets[selected] = {}
local handoff = f.actions:targets(f.player, f.root, 12, 3, selected)
eq(#handoff, 3, "preferred registry overlap preserves area cap")
eq(handoff[1].model, selected, "preferred registry overlap retains selected first")
eq(handoff[2].model, nearest, "overlap does not displace nearest additional target")
eq(handoff[3].model, boss, "overlap does not duplicate preferred in third slot")
f.bosses.targets[selected] = nil

-- Props, party members and fake client marks cannot enter the server registry.
local before = f.rays
for _, unknown in {
	f:model("prop with humanoid", 3, nil),
	f:model("party member character", 4, nil),
	f:model("unregistered enemy", 5, nil),
	f:model("part pretending to be target", 7, nil, "Part"),
	"not an Instance", 42, {},
} do
	eq(#f.actions:targets(f.player, f.root, 12, 1, unknown), 0, "unregistered/type-invalid explicit target rejected")
end
eq(f.rays, before, "unknown membership rejected before raycast")

-- Each invalid explicit target returns empty even with a valid nearby fallback.
local far = f:model("out of range selected", 13, f.enemies)
local dead = f:model("dead selected", 1, f.enemies); dead.humanoid.Health = 0
local blocked = f:model("occluded selected", 8, f.enemies); f.blocked[blocked] = true
local noRoot = f:model("missing root", 10, f.enemies); noRoot.root = nil
local noHumanoid = f:model("missing humanoid", 10.5, f.enemies); noHumanoid.humanoid = nil
for _, invalid in {far, dead, blocked, noRoot, noHumanoid} do
	eq(#f.actions:targets(f.player, f.root, 12, 1, invalid), 0, "invalid preferred has no silent fallback")
	eq(#f.actions:targets(f.player, f.root, 12, 3, invalid), 0, "invalid preferred rejects whole area cast")
end
local filtered = f.actions:targets(f.player, f.root, 12, 10, nil)
eq(#filtered, 4, "auto excludes dead, occluded, distant and incomplete models")
eq(filtered[1].model, nearest, "auto retains nearest valid target after exclusions")

-- Geometry uses the supplied caster position and full 3D distance. LOS hits on
-- a target's own geometry are accepted; opaque intervening geometry is not.
selected.hitOwnChild = true
eq(f.actions:validTarget(f.player, f.root.Position, selected, 11), selected.root, "range boundary inclusive and own-child LOS valid")
eq(f.actions:validTarget(f.player, f.root.Position, selected, 10.99), nil, "range boundary cannot be enlarged by selection")
eq(f.actions:validTarget(f.player, vec(10, 3, 0), selected, 1), selected.root, "range measured from actual supplied caster origin")
eq(f.actions:validTarget(f.player, vec(11, 20, 0), selected, 12), nil, "vertical distance counts toward attack range")
f.blocked[selected] = true
eq(f.actions:validTarget(f.player, f.root.Position, selected, 12), nil, "blocking geometry rejects otherwise valid selected target")
print("Player target orchestration mocks: " .. tostring(assertions) .. " assertions passed (no Roblox physics)")
end
