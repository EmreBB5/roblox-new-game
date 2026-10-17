local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Rules = require(ReplicatedStorage.Shared.PartyRules)
local PartyService = {}
PartyService.__index = PartyService
function PartyService.new(callbacks)
	return setmetatable({callbacks = callbacks, data = Rules.new(Config), last = {}}, PartyService)
end
function PartyService:snapshot(player)
	local members = {}
	for _, userId in Rules.members(self.data, player.UserId) do
		local member = Players:GetPlayerByUserId(userId)
		if member then table.insert(members, {userId = userId, name = member.Name, displayName = member.DisplayName}) end
	end
	local invitation = self.data.invites[player.UserId]
	local invite
	if invitation and invitation.expiresAt > workspace:GetServerTimeNow() then
		local leader = Players:GetPlayerByUserId(invitation.leader)
		if leader then invite = {fromUserId = leader.UserId, fromName = leader.DisplayName, expiresAt = invitation.expiresAt} end
	end
	return {leaderId = Rules.leader(self.data, player.UserId), members = members, invite = invite, maxMembers = Config.Party.MaxMembers}
end
function PartyService:push()
	for player in self.callbacks.profiles do self.callbacks.state(player, self:snapshot(player)) end
end
function PartyService:action(player, action, targetId)
	if not self.callbacks.profiles[player] or type(action) ~= "string" then return end
	local now = workspace:GetServerTimeNow()
	if now - (self.last[player] or -math.huge) < 0.5 then return end
	self.last[player] = now
	if action ~= "leave" then
		if type(targetId) ~= "number" or targetId ~= targetId or targetId % 1 ~= 0 or targetId < 1 or targetId > 1e15 then return end
		local target = Players:GetPlayerByUserId(targetId)
		if not target or not self.callbacks.profiles[target] then return end
	elseif targetId ~= nil then return end
	local result
	if action == "invite" then result = Rules.invite(self.data, player.UserId, targetId, now, Config)
	elseif action == "accept" then result = Rules.accept(self.data, player.UserId, targetId, now, Config)
	elseif action == "decline" then result = Rules.decline(self.data, player.UserId, targetId)
	elseif action == "leave" then result = Rules.leave(self.data, player.UserId)
	elseif action == "kick" then result = Rules.kick(self.data, player.UserId, targetId)
	else return end
	local messages = {invited = "Grup daveti gönderildi.", joined = "Gruba katıldın.", left = "Gruptan ayrıldın.", declined = "Davet reddedildi.", kicked = "Oyuncu gruptan çıkarıldı."}
	messages.full = "Grup dolu: en fazla dört kişi katılabilir."
	messages.leader = "Bu işlem için grup lideri olmalısın."
	messages.member = "Oyuncu zaten bir grupta."
	messages.pending = "Oyuncunun henüz yanıtlamadığı bir daveti var."
	messages.expired = "Davetin süresi doldu. Yeni davet iste."
	self.callbacks.notify(player, messages[result.status] or "Grup işlemi yapılamadı. Daveti ve grup durumunu kontrol et.")
	local target = targetId and Players:GetPlayerByUserId(targetId)
	if result.status == "invited" and target then self.callbacks.notify(target, player.DisplayName .. " seni gruba davet ediyor. G → Grup panelini aç.") end
	if result.status == "kicked" and target then self.callbacks.notify(target, "Grup lideri seni gruptan çıkardı.") end
	self:push()
end
function PartyService:assists(attacker, position)
	local recipients = {}
	for _, id in Rules.members(self.data, attacker.UserId) do
		local member = Players:GetPlayerByUserId(id)
		if member and member ~= attacker and self.callbacks.profiles[member] then
			local root = self.callbacks.living(member)
			if root and self.callbacks.trusted(member, root) and Rules.assistEligible(true, (root.Position - position).Magnitude, Config) then table.insert(recipients, member) end
		end
	end
	return recipients
end
function PartyService:update()
	local now = workspace:GetServerTimeNow()
	local changed = false
	for id, invite in self.data.invites do
		if invite.expiresAt <= now or not Players:GetPlayerByUserId(invite.leader) then self.data.invites[id] = nil changed = true end
	end
	if changed then self:push() end
end
function PartyService:remove(player)
	Rules.leave(self.data, player.UserId)
	self.data.invites[player.UserId] = nil
	for id, invite in self.data.invites do if invite.leader == player.UserId then self.data.invites[id] = nil end end
	self.last[player] = nil
	self:push()
end
return PartyService
