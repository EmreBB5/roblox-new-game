local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local Contracts = require(game:GetService("ReplicatedStorage").Shared:WaitForChild("Contracts"))
local ContractHUD = {}
function ContractHUD.create(gui, parent, remotes, make, label, button, colors)
	local self = {state = {}}
	local request = remotes:WaitForChild("RequestRegionContract")
	local cards = {}
	local order = {"forest", "marsh", "volcanic", "frost", "desert"}
	local materialNames = {wood = "odun", iron = "demir", ember = "köz"}
	label(parent, "BÖLGE GÖREVLERİ", UDim2.fromOffset(0, 386), UDim2.new(1, -6, 0, 28), 15, colors.gold)
	label(parent, "Panodan kabul et → 5 yaratık, 3 toplama, türbe keşfi.\nKabul öncesi yaratık ve toplama sayılmaz; ödül panodan alınır.", UDim2.fromOffset(0, 415), UDim2.new(1, -8, 0, 48), 11, colors.muted)
	local function nearBoard(id)
		local world = workspace:FindFirstChild("AetheriaWorld")
		local folder = world and world:FindFirstChild("RegionalContractBoards")
		local board, position
		if folder then
			for _, model in ipairs(folder:GetChildren()) do
				if model:GetAttribute("RegionalContractId") == id or model.Name == "ContractBoard_" .. id then
					board, position = model:FindFirstChild("NoticeBoard"), model:GetAttribute("ContractPosition")
					break
				end
			end
		end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if typeof(position) ~= "Vector3" and board and board:IsA("BasePart") then position = board.Position end
		return typeof(position) == "Vector3" and root ~= nil and humanoid ~= nil and humanoid.Health > 0 and (root.Position - position).Magnitude <= 14
	end
	for index, id in ipairs(order) do
		local definition = Config.RegionalContracts[id]
		local y = 470 + (index - 1) * 194
		local card = make("Frame", {Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, -6, 0, 184), BackgroundColor3 = Color3.fromRGB(25, 43, 37), BorderSizePixel = 0}, parent)
		make("UICorner", {CornerRadius = UDim.new(0, 10)}, card)
		label(card, definition.Name, UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 24), 14, colors.gold)
		local progress = label(card, "", UDim2.fromOffset(10, 31), UDim2.new(1, -20, 0, 54), 12)
		label(card, string.format("Ödül: %d XP • %d altın\n%d %s", definition.XP, definition.Gold, definition.MaterialAmount, materialNames[definition.Material]), UDim2.fromOffset(10, 88), UDim2.new(1, -20, 0, 40), 11, colors.muted)
		local action = button(card, "PANOYA YAKLAŞ", UDim2.fromOffset(10, 134), UDim2.new(1, -20, 0, 44), function()
			if not nearBoard(id) then return end
			local state = (self.state.regionalContracts or {})[id] or {status = "available"}
			if state.status == "available" then request:FireServer("accept", id)
			elseif state.status == "active" and Contracts.ready(self.state, id, Config) then request:FireServer("claim", id) end
		end)
		cards[id] = {progress = progress, action = action, y = y}
	end
	parent.CanvasSize = UDim2.fromOffset(0, 1440)
	function self:setState(state) self.state = state end
	function self:focus(id)
		local card = cards[id]
		if not card then return end
		parent.CanvasPosition = Vector2.new(0, card.y)
		if UserInputService.GamepadEnabled then GuiService.SelectedObject = card.action end
	end
	task.spawn(function()
		while gui.Parent do
			for id, card in pairs(cards) do
				local definition = Config.RegionalContracts[id]
				local state = (self.state.regionalContracts or {})[id] or {status = "available", kills = 0, gathers = 0}
				local discovery = (self.state.waypoints or {})[definition.WaypointId] == true
				local ready = Contracts.ready(self.state, id, Config)
				local completed = state.status == "completed"
				local nearby = nearBoard(id)
				card.progress.Text = string.format("%s • Yaratık %d/%d • Toplama %d/%d\nTürbe: %s", completed and "Tamamlandı" or (state.status == "active" and "Aktif" or "Alınmadı"), state.kills or 0, definition.KillTarget, state.gathers or 0, definition.GatherTarget, discovery and "Keşfedildi ✓" or "Keşfetmen gerekiyor")
				local enabled = nearby and not completed and (state.status == "available" or ready)
				card.action.Text = completed and "TAMAMLANDI" or (not nearby and "BÖLGE PANOSUNA YAKLAŞ" or (ready and "ÖDÜLÜ AL" or (state.status == "available" and "GÖREVİ AL" or "HEDEFLERİ TAMAMLA")))
				card.action.Selectable, card.action.AutoButtonColor = enabled, enabled
				card.action.BackgroundColor3 = enabled and Color3.fromRGB(46, 85, 69) or Color3.fromRGB(38, 47, 47)
			end
			task.wait(0.25)
		end
	end)
	return self
end
return ContractHUD
