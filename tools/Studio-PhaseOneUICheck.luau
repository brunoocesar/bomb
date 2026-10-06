assert(game.PlaceId == 140221183064352, "Wrong project")
local player = game.Players.LocalPlayer
assert(player, "Use the Studio client")
local ui = player.PlayerGui:FindFirstChild("PhaseOneUI")
assert(ui and ui.ScreenInsets == Enum.ScreenInsets.DeviceSafeInsets, "Phase UI must use device safe insets")
local board = ui.PlayArea.Board
local origin, size = ui.AbsolutePosition, ui.AbsoluteSize
local function inside(view)
	local p, s = view.AbsolutePosition, view.AbsoluteSize
	assert(p.X >= origin.X - 1 and p.Y >= origin.Y - 1, view.Name .. " begins outside safe GUI")
	assert(p.X + s.X <= origin.X + size.X + 1 and p.Y + s.Y <= origin.Y + size.Y + 1, view.Name .. " ends outside safe GUI")
end
inside(board)
assert(math.abs(board.AbsoluteSize.X / 15 - board.AbsoluteSize.Y / 13) < .1, "Cells must remain square")
for _, name in ipairs({ "Up", "Right", "Down", "Left", "Bomb" }) do
	local view = ui.Controls[name]
	inside(view)
	assert(view.AbsoluteSize.X >= 44 and view.AbsoluteSize.Y >= 44, name .. " touch target is too small")
end
inside(ui.Header.Pause)
inside(ui.Hint)
print("BOMB_PHASE1_UI_VERIFIED", size, board.AbsoluteSize, game:GetService("UserInputService").TouchEnabled, ui.ScreenInsets)
