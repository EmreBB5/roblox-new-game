-- Schedule from absolute clock slots; never advance by sleeping an interval.
local BossSchedule = {}
local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function event(bossId, start, duration)
	return {bossId = bossId, occurrence = start, startsAt = start, endsAt = start + duration}
end
function BossSchedule.production(now, config)
	if not finite(now) or now < 0 then return nil end
	local hour = math.floor(now / 3600) * 3600
	for _, id in config.BossOrder do
		local start = hour + config.Bosses[id].Minute * 60
		if now >= start and now < start + config.BossDuration then return event(id, start, config.BossDuration) end
	end
	return nil
end
function BossSchedule.next(now, config)
	if not finite(now) or now < 0 then return nil end
	local hour = math.floor(now / 3600) * 3600
	local best = nil
	for _, id in config.BossOrder do
		local start = hour + config.Bosses[id].Minute * 60
		if start <= now then start += 3600 end
		if not best or start < best.startsAt then best = event(id, start, config.BossDuration) end
	end
	return best
end
function BossSchedule.studio(elapsed, config, epoch)
	if not finite(elapsed) or elapsed < config.StudioFirstBossDelay or not finite(epoch) or epoch < 1 or epoch % 1 ~= 0 then return nil end
	local slot = math.floor((elapsed - config.StudioFirstBossDelay) / config.StudioBossInterval)
	local offset = config.StudioFirstBossDelay + slot * config.StudioBossInterval
	if elapsed >= offset + config.StudioBossDuration then return nil end
	local id = config.BossOrder[slot % #config.BossOrder + 1]
	return event(id, epoch + offset, config.StudioBossDuration)
end
function BossSchedule.studioNext(elapsed, config, epoch)
	if not finite(elapsed) or elapsed < 0 or not finite(epoch) or epoch < 1 or epoch % 1 ~= 0 then return nil end
	local slot = math.max(0, math.floor((elapsed - config.StudioFirstBossDelay) / config.StudioBossInterval) + 1)
	local offset = config.StudioFirstBossDelay + slot * config.StudioBossInterval
	return event(config.BossOrder[slot % #config.BossOrder + 1], epoch + offset, config.StudioBossDuration)
end
return BossSchedule
