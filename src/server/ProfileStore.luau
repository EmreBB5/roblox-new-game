local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Progression = require(ReplicatedStorage.Shared.Progression)
local ProfileStore = {}
local memory = RunService:IsStudio()
local store = if memory then nil else DataStoreService:GetDataStore("AetheriaProfiles_v1")
local SESSION = game.JobId .. ":" .. HttpService:GenerateGUID(false)
local LEASE_SECONDS = 180
local handles = {}

function ProfileStore.load(player)
	if memory then
		local handle = {data = Progression.newProfile(), status = "Studio: geçici", busy = false}
		handles[player] = handle
		return handle
	end
	local ok, result = pcall(function()
		return store:UpdateAsync("player_" .. player.UserId, function(old)
			if type(old) == "table" and old.session and old.session ~= SESSION
				and type(old.expires) == "number" and old.expires > os.time() then
				return nil
			end
			return {data = Progression.sanitize(if type(old) == "table" then old.data else nil),
				session = SESSION, expires = os.time() + LEASE_SECONDS}
		end)
	end)
	if not ok or type(result) ~= "table" or result.session ~= SESSION then return nil end
	local handle = {data = Progression.sanitize(result.data), status = "Kaydedildi", busy = false}
	handles[player] = handle
	return handle
end

function ProfileStore.save(player, release: boolean?): boolean
	local handle = handles[player]
	if not handle then return false end
	while handle.busy do task.wait(0.05) end
	if handles[player] ~= handle then return false end
	if memory then
		if release then handles[player] = nil end
		return true
	end
	handle.busy = true
	local copy = table.clone(handle.data)
	local writeId = HttpService:GenerateGUID(false)
	local ok, result = pcall(function()
		return store:UpdateAsync("player_" .. player.UserId, function(old)
			if type(old) ~= "table" or old.session ~= SESSION then return nil end
			return {data = copy, writeId = writeId, session = if release then nil else SESSION,
				expires = if release then 0 else os.time() + LEASE_SECONDS}
		end)
	end)
	handle.busy = false
	local saved = ok and type(result) == "table" and result.writeId == writeId
	handle.status = if saved then "Kaydedildi" else "Kayıt hatası"
	if release then handles[player] = nil end
	return saved
end

return ProfileStore
