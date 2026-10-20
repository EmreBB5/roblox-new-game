-- Advisory navigation only: no rewards, actions, Roblox objects or mutation.
local Journey = {}
local REGIONS = {"forest", "marsh", "volcanic", "frost", "desert"}
local WAYPOINTS = {"village", "forest", "marsh", "volcanic", "frost", "desert"}
local BOSSES = {"thornwarden", "tide_sentinel", "ember_drake"}
local SITES = {"forest_ruins", "marsh_outpost", "volcanic_archive", "frost_watch", "desert_caravan"}
local REGION_SET = {forest = true, marsh = true, volcanic = true, frost = true, desert = true}
local function object(value) return if type(value) == "table" then value else {} end
local function finite(value) return type(value) == "number" and value == value and math.abs(value) < math.huge end
local function integer(value) return finite(value) and value >= 0 and value % 1 == 0 end
local function name(value, fallback) return if type(value) == "string" and #value > 0 and #value < 100 then value else fallback end

function Journey.options(state, world, x, z, config, now, pinnedId)
	if type(state) ~= "table" or type(config) ~= "table" then return {} end
	local bounds = object(config.MapBounds)
	if not finite(bounds.MinX) or not finite(bounds.MaxX) or not finite(bounds.MinZ) or not finite(bounds.MaxZ)
		or bounds.MinX > bounds.MaxX or bounds.MinZ > bounds.MaxZ then return {} end
	local function position(px, pz)
		return finite(px) and finite(pz) and px >= bounds.MinX and px <= bounds.MaxX and pz >= bounds.MinZ and pz <= bounds.MaxZ
	end
	if not position(x, z) or not integer(state.level) or state.level < 1 or state.level > 10000
		or (state.questStatus ~= "available" and state.questStatus ~= "active" and state.questStatus ~= "return" and state.questStatus ~= "completed") then return {} end
	world = object(world)
	local currentTime = if now ~= nil then now else world.serverNow
	local pin = if type(pinnedId) == "string" and #pinnedId <= 80 then pinnedId else nil
	local regions, waypoints = object(config.Regions), object(config.Waypoints)
	local owned = object(state.waypoints)
	local list, seen = {}, {}
	local function add(priority, id, kind, title, detail, px, pz, regionId, panel)
		if seen[id] or (regionId ~= nil and regionId ~= "village" and not REGION_SET[regionId]) then return end
		if px ~= nil or pz ~= nil then if not position(px, pz) then return end
		elseif kind ~= "claim" and kind ~= "boss_wait" then return end
		seen[id] = true
		local suggestion = {id = id, kind = kind, title = title, detail = detail, x = px, z = pz, regionId = regionId, panel = panel}
		table.insert(list, {value = suggestion, priority = priority, distance = if px ~= nil then (px - x) ^ 2 + (pz - z) ^ 2 else 0})
	end
	local function waypoint(id)
		local definition = object(waypoints[id])
		local p = object(definition.Position)
		if position(p.x, p.z) then return p.x, p.z end
		return nil, nil
	end
	local expedition = object(state.expedition)
	local stageIndex = if integer(expedition.stage) and expedition.stage >= 1 then expedition.stage else nil
	local stage = if stageIndex then object(object(config.Expedition)[stageIndex]) else {}
	local stageValid = integer(stage.Target) and stage.Target > 0 and integer(expedition.progress)
	if state.questStatus == "available" then
		add(10, "quest:accept", "quest", "Eldrin ile konuş", "Köyde E ile ilk görevini al.", 15, 0, "village")
	elseif state.questStatus == "return" then
		add(10, "quest:return", "quest", "Eldrin'e geri dön", "Köyde E ile görev ödülünü al.", 15, 0, "village")
	end
	if stageValid and expedition.progress >= stage.Target then
		add(20, "expedition:claim", "claim", "Sefer ödülün hazır", "C ile sefer ödülünü al.", nil, nil, nil, "C")
	end

	-- Derive readiness from actual counters and discovered waypoints rather than
	-- trusting a potentially stale regionContractReady convenience map.
	local contracts, definitions = object(state.regionalContracts), object(config.RegionalContracts)
	for _, id in REGIONS do
		local contract, definition = object(contracts[id]), object(definitions[id])
		local valid = contract.status == "active" and integer(contract.kills) and integer(contract.gathers)
			and integer(definition.KillTarget) and definition.KillTarget > 0
			and integer(definition.GatherTarget) and definition.GatherTarget > 0
			and definition.WaypointId == id
		if not valid then continue end
		local wx, wz = waypoint(id)
		local region = object(regions[id])
		local regionName = name(region.Name, id)
		if contract.kills >= definition.KillTarget and contract.gathers >= definition.GatherTarget and owned[id] == true then
			if wx then add(30, "contract:claim:" .. id, "contract", "Bölge ödülünü teslim al", regionName .. " · Panoda E.", wx + 18, wz + 10, id, "C") end
		elseif contract.kills < definition.KillTarget then
			add(50, "contract:kill:" .. id, "hunt", "Bölge düşmanlarını yen", regionName .. " · " .. tostring(definition.KillTarget - contract.kills) .. " düşman kaldı.", region.X, region.Z, id, "C")
		elseif contract.gathers < definition.GatherTarget then
			-- Region centre is a general destination, never a fabricated farm node.
			add(50, "contract:gather:" .. id, "gather", "Bölgede kaynak topla", regionName .. " · " .. tostring(definition.GatherTarget - contract.gathers) .. " toplama kaldı.", region.X, region.Z, id, "C")
		elseif wx then
			add(50, "contract:waypoint:" .. id, "waypoint", "Bölge türbesini keşfet", regionName .. " · Türbede E.", wx, wz, id, "C")
		end
	end

	local bossDefinitions = object(config.Bosses)
	local worldBosses = object(world.bosses)
	if stageIndex == 4 or state.questStatus == "completed" then
		for _, id in BOSSES do
			local definition = object(bossDefinitions[id])
			local region = object(regions[definition.RegionId])
			if not REGION_SET[definition.RegionId] or not integer(region.EnemyLevel) or region.EnemyLevel < 1 or state.level < region.EnemyLevel then continue end
			local activeBoss = false
			for _, boss in worldBosses do
				if type(boss) == "table" and boss.id == id and boss.status == "alive" and finite(boss.health) and boss.health > 0
					and finite(currentTime) and currentTime > 0 and finite(boss.occurrenceAt) and boss.occurrenceAt > 0
					and boss.occurrenceAt <= currentTime and finite(boss.despawnAt) and boss.despawnAt > currentTime then
					activeBoss = true
					break
				end
			end
			if activeBoss then
				add(40, "boss:" .. id, "boss", name(definition.Name, "Dünya bossu") .. " etkin", "Arenaya git; saldırı işaretlerinden kaç.", definition.X, definition.Z, definition.RegionId, "M")
			end
		end
	end
	if state.questStatus == "active" and integer(state.questKills) and integer(config.QuestTarget) and config.QuestTarget > 0 then
		local forest = object(regions.forest)
		add(45, "quest:hunt", "hunt", "Orman yaratıklarını yen", tostring(math.max(0, config.QuestTarget - state.questKills)) .. " hedef kaldı; sonra Eldrin'e dön.", forest.X, forest.Z, "forest")
	end
	if stageValid and expedition.progress < stage.Target then
		local id = stage.RegionId
		if REGION_SET[id] then
			local region = object(regions[id])
			add(60, "expedition:stage:" .. tostring(stageIndex), "expedition", name(stage.Name, "Sefer hedefine git"), tostring(stage.Target - expedition.progress) .. " düşman kaldı.", region.X, region.Z, id, "C")
		elseif stageIndex == 4 then
			add(65, "expedition:boss_wait", "boss_wait", "Dünya bossu takvimini incele", "M ile bir sonraki bossu takip et.", nil, nil, nil, "M")
		end
	end

	local function nearby(px, pz) return position(px, pz) and (px - x) ^ 2 + (pz - z) ^ 2 <= 350 ^ 2 end
	for _, id in WAYPOINTS do
		local wx, wz = waypoint(id)
		if owned[id] ~= true and wx and (nearby(wx, wz) or pin == "waypoint:" .. id) then
			add(70, "waypoint:" .. id, "waypoint", "Yakındaki türbeyi keşfet", name(object(waypoints[id]).Name, "Türbe") .. " · E ile kaydet.", wx, wz, id, "M")
		end
	end
	local exploration = object(state.exploration)
	local discovered, claimed = object(exploration.discovered), object(exploration.claimed)
	for _, id in SITES do
		local site = object(object(config.ExplorationSites)[id])
		if not REGION_SET[site.RegionId] or not position(site.X, site.Z) or claimed[id] == true then continue end
		if discovered[id] ~= true then
			if nearby(site.X, site.Z + 24) or pin == "explore:" .. id then add(70, "explore:" .. id, "explore", name(site.Name, "Keşif alanı"), "Keşif taşında E ile alanı keşfet.", site.X, site.Z + 24, site.RegionId, "M") end
		elseif claimed[id] ~= true and (nearby(site.X, site.Z - 12) or pin == "chest:" .. id) then
			local clear = false
			for _, status in object(world.sites) do
				if type(status) == "table" and status.id == id and status.clear == true and status.guardsAlive == 0 and status.guardCount == site.Guards then
					clear = true
					break
				end
			end
			add(70, "chest:" .. id, "chest", "Kişisel keşif sandığın", if clear then "5 sn savaş dışında kal; sandıkta E." else "İki muhafızı yen; sandıkta E ile aç.", site.X, site.Z - 12, site.RegionId, "M")
		end
	end
	if #list == 0 then
		local wx, wz = waypoint("village")
		if wx then add(100, "fallback:village", "rest", "Köye dön ve hazırlan", "Türbelerle yolculuk yapabilir, dünyayı keşfedebilirsin.", wx, wz, "village", "M") end
	end
	table.sort(list, function(a, b)
		if a.priority ~= b.priority then return a.priority < b.priority end
		if a.distance ~= b.distance then return a.distance < b.distance end
		return a.value.id < b.value.id
	end)
	local result = {}
	for index = 1, math.min(6, #list) do result[index] = list[index].value end
	-- Preserve the five leading recommendations. A still-valid manual target
	-- may occupy the sixth slot even when it no longer ranks among the nearest.
	if pin and #list > 6 then
		local found = false
		for _, suggestion in result do
			if suggestion.id == pin then
				found = true
				break
			end
		end
		if not found then
			for index = 7, #list do
				if list[index].value.id == pin then
					result[6] = list[index].value
					break
				end
			end
		end
	end
	return result
end
return Journey
