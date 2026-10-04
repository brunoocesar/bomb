assert(game.PlaceId==140221183064352 and game.Players.LocalPlayer)
local ui=game.Players.LocalPlayer.PlayerGui.TutorialUI
local stats=ui.Header.Stats
assert(stats.TextBounds.X<=stats.AbsoluteSize.X+1 and stats.TextBounds.Y<=stats.AbsoluteSize.Y+1,"HUD text overflow")
local board=ui.PlayArea.Board
assert(math.abs(board.AbsoluteSize.X/13-board.AbsoluteSize.Y/9)<1,"non-square cells")
assert(ui.Controls.Bomb.AbsoluteSize.X>=44)
print("BOMB_MOBILE_HUD_OK",game:GetService("UserInputService").TouchEnabled,ui.AbsoluteSize,stats.Text,stats.TextBounds,stats.AbsoluteSize)
