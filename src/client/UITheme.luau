-- Shared visual treatment only: no layout changes or gameplay state.
local Theme = {}
Theme.colors = {
	panel = Color3.fromRGB(12, 24, 43), text = Color3.fromRGB(236, 242, 241), muted = Color3.fromRGB(157, 185, 199),
	gold = Color3.fromRGB(224, 190, 123), health = Color3.fromRGB(82, 221, 181), xp = Color3.fromRGB(103, 169, 255),
	teal = Color3.fromRGB(83, 220, 215), button = Color3.fromRGB(29, 67, 85),
}
function Theme.gradient(parent, top, bottom, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(top, bottom)
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end
function Theme.panel(frame)
	Theme.gradient(frame, Color3.fromRGB(245, 255, 255), Color3.fromRGB(125, 157, 199))
	local edge = Instance.new("Frame")
	edge.Name = "TealInlay"
	edge.BorderSizePixel = 0
	edge.BackgroundColor3 = Theme.colors.teal
	edge.BackgroundTransparency = 0.25
	edge.Position, edge.Size = UDim2.fromOffset(12, 0), UDim2.new(1, -24, 0, 1)
	edge.Active = false
	edge.Parent = frame
	local fade = Theme.gradient(edge, Theme.colors.gold, Theme.colors.teal, 0)
	fade.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1)})
end
function Theme.button(button)
	Theme.gradient(button, Color3.fromRGB(255, 255, 255), Color3.fromRGB(144, 191, 215))
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color, stroke.Transparency = Theme.colors.teal, 0.65
	stroke.Parent = button
	button.MouseEnter:Connect(function() stroke.Transparency = 0.15 end)
	button.MouseLeave:Connect(function() stroke.Transparency = 0.65 end)
	button.SelectionGained:Connect(function() stroke.Transparency = 0.1 end)
	button.SelectionLost:Connect(function() stroke.Transparency = 0.65 end)
end
return Theme
