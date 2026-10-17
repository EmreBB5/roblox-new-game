-- A local roster and invitation view; membership is always server-owned.
local Players = game:GetService("Players")
local PartyHUD = {}
function PartyHUD.create(gui, parent, remotes, make, label, button, colors, badge)
	local self = { state = { members = {} } }
	local action = remotes:WaitForChild("PartyAction")
	local status = label(parent, "GRUP • Tek başınasın", UDim2.fromOffset(0, 0), UDim2.new(1, -125, 0, 32), 15, colors.gold)
	local leave = button(parent, "AYRIL", UDim2.new(1, -115, 0, 0), UDim2.fromOffset(115, 44), function() action:FireServer("leave") end)
	local invitation = label(parent, "Bekleyen davet yok.", UDim2.fromOffset(0, 50), UDim2.new(1, 0, 0, 44), 12, colors.muted)
	local accept = button(parent, "KABUL", UDim2.fromOffset(0, 103), UDim2.new(0.5, -4, 0, 44), function()
		local invite = self.state.invite
		if invite and invite.expiresAt > workspace:GetServerTimeNow() then action:FireServer("accept", invite.fromUserId) end
	end)
	local decline = button(parent, "REDDET", UDim2.new(0.5, 4, 0, 103), UDim2.new(0.5, -4, 0, 44), function()
		if self.state.invite then action:FireServer("decline", self.state.invite.fromUserId) end
	end)
	label(parent, "En fazla 4 kişi • Davet için oyuncunun onayı gerekir.", UDim2.fromOffset(0, 153), UDim2.new(1, 0, 0, 38), 11, colors.muted)
	local scroll = make("Frame", { Position = UDim2.fromOffset(0, 200), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, parent)
	local function zindex(object)
		object.ZIndex = 7
		for _, child in ipairs(object:GetDescendants()) do if child:IsA("GuiObject") then child.ZIndex = 7 end end
	end
	local function rebuild()
		for _, item in ipairs(scroll:GetChildren()) do item:Destroy() end
		local state, y = self.state, 0
		local members = state.members or {}
		local ownId = Players.LocalPlayer.UserId
		local leader = state.leaderId
		leave.Visible = leader ~= nil and leader ~= 0
		status.Text = leave.Visible and string.format("GRUBUN • %d / %d kişi", #members, state.maxMembers or 4) or "GRUP • Tek başınasın"
		local ids = {}
		for _, member in ipairs(members) do
			ids[member.userId] = true
			local text = (member.userId == leader and "★ " or "") .. (member.displayName or member.name) .. "  @" .. member.name
			local name = label(scroll, text, UDim2.fromOffset(0, y), UDim2.new(1, -108, 0, 44), 13)
			zindex(name)
			if leader == ownId and member.userId ~= ownId then
				local kick = button(scroll, "ÇIKAR", UDim2.new(1, -102, 0, y), UDim2.fromOffset(94, 44), function() action:FireServer("kick", member.userId) end)
				zindex(kick)
			end
			y += 48
		end
		local title = label(scroll, "ÇEVRİMİÇİ OYUNCULAR", UDim2.fromOffset(0, y), UDim2.new(1, 0, 0, 30), 12, colors.gold)
		zindex(title)
		y += 32
		local count = 0
		for _, candidate in ipairs(Players:GetPlayers()) do
			if candidate ~= Players.LocalPlayer and not ids[candidate.UserId] then
				count += 1
				local name = label(scroll, candidate.DisplayName .. "  @" .. candidate.Name, UDim2.fromOffset(0, y), UDim2.new(1, -108, 0, 44), 13)
				zindex(name)
				if not leader or leader == ownId or leader == 0 then
					local invite = button(scroll, "DAVET ET", UDim2.new(1, -102, 0, y), UDim2.fromOffset(94, 44), function() action:FireServer("invite", candidate.UserId) end)
					zindex(invite)
				end
				y += 48
			end
		end
		if count == 0 then
			local empty = label(scroll, "Bu sunucuda davet edebileceğin başka oyuncu yok.", UDim2.fromOffset(0, y), UDim2.new(1, -10, 0, 44), 12, colors.muted)
			zindex(empty)
			y += 48
		end
		scroll.Size = UDim2.new(1, 0, 0, y + 8)
		parent.CanvasSize = UDim2.fromOffset(0, y + 208)
	end
	remotes:WaitForChild("PartyState").OnClientEvent:Connect(function(state)
		if type(state) ~= "table" then return end
		self.state = state
		rebuild()
	end)
	Players.PlayerAdded:Connect(function() rebuild() end)
	Players.PlayerRemoving:Connect(function() task.defer(rebuild) end)
	task.spawn(function()
		while gui.Parent do
			local invite = self.state.invite
			local remaining = invite and math.max(0, math.ceil(invite.expiresAt - workspace:GetServerTimeNow())) or 0
			local valid = remaining > 0
			invitation.Text = valid and string.format("%s seni davet ediyor.\nKalan süre: %d sn", invite.fromName, remaining) or "Bekleyen davet yok."
			accept.Visible, decline.Visible = valid, valid
			badge(valid)
			task.wait(0.25)
		end
	end)
	rebuild()
	return self
end
return PartyHUD
