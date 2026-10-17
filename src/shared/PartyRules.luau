-- User IDs only; runtime state is intentionally not persisted in player profiles.
local PartyRules = {}
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
local function user(id) return finite(id) and id > 0 and id % 1 == 0 end
function PartyRules.new()
	return {parties = {}, membership = {}, invites = {}, nextId = 0}
end
function PartyRules.members(state, member)
	local party = state.parties[state.membership[member]]
	return if party then table.clone(party.members) else {}
end
function PartyRules.leader(state, member)
	local party = state.parties[state.membership[member]]
	return if party then party.leader else nil
end
function PartyRules.invite(state, leader, target, now, config)
	if not user(leader) or not user(target) or leader == target or not finite(now) or now < 0 then return {status = "invalid"} end
	local party = state.parties[state.membership[leader]]
	if party and party.leader ~= leader then return {status = "leader"} end
	if state.membership[target] then return {status = "member"} end
	if party and #party.members >= config.Party.MaxMembers then return {status = "full"} end
	local pending = state.invites[target]
	if pending and pending.expiresAt > now then return {status = "pending"} end
	state.invites[target] = {leader = leader, expiresAt = now + config.Party.InviteDuration}
	return {status = "invited"}
end
function PartyRules.accept(state, target, leader, now, config)
	if not user(target) or not user(leader) or not finite(now) or now < 0 then return {status = "invalid"} end
	local invite = state.invites[target]
	if not invite or invite.leader ~= leader then return {status = "invite"} end
	if now >= invite.expiresAt then
		state.invites[target] = nil
		return {status = "expired"}
	end
	if state.membership[target] then return {status = "member"} end
	local party = state.parties[state.membership[leader]]
	if party and party.leader ~= leader then return {status = "leader"} end
	if party and #party.members >= config.Party.MaxMembers then return {status = "full"} end
	if not party then
		state.nextId += 1
		party = {leader = leader, members = {leader}}
		state.parties[state.nextId] = party
		state.membership[leader] = state.nextId
		state.invites[leader] = nil
	end
	table.insert(party.members, target)
	state.membership[target] = state.membership[leader]
	state.invites[target] = nil
	-- Joining another group invalidates invitations this player sent while solo.
	for id, pending in state.invites do if pending.leader == target then state.invites[id] = nil end end
	return {status = "joined"}
end
function PartyRules.decline(state, target, leader)
	local invite = state.invites[target]
	if not invite or (leader ~= nil and invite.leader ~= leader) then return {status = "invite"} end
	state.invites[target] = nil
	return {status = "declined"}
end
local function remove(state, member)
	local id = state.membership[member]
	local party = state.parties[id]
	state.invites[member] = nil
	for target, invite in state.invites do if invite.leader == member then state.invites[target] = nil end end
	if not party then return false end
	state.membership[member] = nil
	for index, value in party.members do
		if value == member then
			table.remove(party.members, index)
			break
		end
	end
	if #party.members == 0 then state.parties[id] = nil
	elseif party.leader == member then party.leader = party.members[1] end
	return true
end
function PartyRules.leave(state, member)
	return {status = if remove(state, member) then "left" else "member"}
end
function PartyRules.kick(state, leader, target)
	local party = state.parties[state.membership[leader]]
	if not party or party.leader ~= leader or target == leader or state.membership[target] ~= state.membership[leader] then return {status = "leader"} end
	remove(state, target)
	return {status = "kicked"}
end
function PartyRules.assistEligible(alive, distance, config)
	return alive == true and finite(distance) and distance >= 0 and distance <= config.Party.RewardRadius
end
function PartyRules.rewardXP(baseXP, assist, config)
	if not finite(baseXP) or baseXP < 0 then return 0 end
	return math.max(1, math.floor(baseXP * (if assist then config.Party.AssistXPFactor else 1)))
end
return PartyRules
