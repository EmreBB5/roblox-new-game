-- Pure combat rules; server supplies trusted time and validates target geometry.
local Combat = {}
local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function Combat.stats(profile, config)
	local classId = if config.Classes[profile.classId] then profile.classId else "warrior"
	local class = config.Classes[classId]
	local equipment = config.Equipment[profile.equipmentTier]
	local pet = if type(profile.equippedPet) == "string" and profile.pets[profile.equippedPet] == true then config.Pets[profile.equippedPet] else nil
	local petBonus = if pet then pet.DamageBonus else 0
	if pet then
		local xp = if type(profile.petXP) == "table" then profile.petXP[profile.equippedPet] else 0
		xp = if finite(xp) then math.clamp(xp, 0, config.PetProgression.MaxXP) else 0
		for _, threshold in config.PetProgression.BonusThresholds do if xp >= threshold then petBonus += 1 end end
	end
	local level = if finite(profile.level) then math.clamp(math.floor(profile.level), 1, 10000) else 1
	return {classId = classId, maxHealth = class.MaxHealth + (if equipment then equipment.HealthBonus else 0),
		basicRange = class.BasicRange, basicDamage = class.BasicDamage + math.min(30, level - 1) * 2
			+ (if equipment then equipment.DamageBonus else 0) + petBonus}
end
function Combat.newRuntime(now)
	assert(finite(now) and now >= 0, "finite nonnegative server time required")
	return {resource = 100, updatedAt = now, cooldowns = {primary = 0, secondary = 0}}
end
local function valid(runtime, now)
	return finite(now) and now >= 0 and finite(runtime.updatedAt) and runtime.updatedAt >= 0 and now >= runtime.updatedAt
		and finite(runtime.resource) and runtime.resource >= 0 and runtime.resource <= 100
		and type(runtime.cooldowns) == "table" and finite(runtime.cooldowns.primary) and runtime.cooldowns.primary >= 0 and finite(runtime.cooldowns.secondary) and runtime.cooldowns.secondary >= 0
end
function Combat.refresh(runtime, now, config)
	if not valid(runtime, now) then return false end
	runtime.resource = math.min(config.ResourceMax, runtime.resource + (now - runtime.updatedAt) * config.ResourceRegen)
	runtime.updatedAt = now
	return true
end
function Combat.use(profile, runtime, slot, now, targetValid, config)
	if type(slot) ~= "string" or not config.Abilities[profile.classId] or not config.Abilities[profile.classId][slot]
		or not valid(runtime, now) then return {status = "invalid"} end
	if targetValid ~= true then return {status = "target"} end
	local ability = config.Abilities[profile.classId][slot]
	Combat.refresh(runtime, now, config)
	if now < runtime.cooldowns[slot] then return {status = "cooldown"} end
	if runtime.resource < ability.Cost then return {status = "resource"} end
	runtime.resource -= ability.Cost
	runtime.cooldowns[slot] = now + ability.Cooldown
	return {status = "used", ability = ability}
end
return Combat
