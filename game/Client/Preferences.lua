local Preferences = {}

function Preferences.controls(ui, settings)
	if not settings then
		return
	end
	local controls = ui.Controls
	local width = controls.AbsoluteSize.X
	if settings.leftHanded then
		for _, name in ipairs({ "Up", "Down", "Left", "Right", "Bomb" }) do
			local button = controls[name]
			button.Position =
				UDim2.fromOffset(width - button.Position.X.Offset - button.Size.X.Offset, button.Position.Y.Offset)
		end
		-- Mirror the group, preserving the directional arrangement inside it.
		controls.Left.Position, controls.Right.Position = controls.Right.Position, controls.Left.Position
	end
	for _, button in ipairs(controls:GetChildren()) do
		if button:IsA("GuiButton") then
			button.BackgroundTransparency = 1 - settings.controlsOpacity
			button.TextTransparency = (1 - settings.controlsOpacity) * 0.35
		end
	end
end

function Preferences.text(root, large)
	for _, view in ipairs(root:GetDescendants()) do
		if view:IsA("TextLabel") or view:IsA("TextButton") then
			local base = view:GetAttribute("BaseTextSize")
			if not base then
				base = view.TextSize
				view:SetAttribute("BaseTextSize", base)
			end
			if not view.TextScaled then
				view.TextSize = base + (large and 2 or 0)
			end
		end
	end
end

return Preferences
