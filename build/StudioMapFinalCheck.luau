assert(game.PlaceId == 140221183064352)
assert(game:GetService("RunService"):IsRunning())
local ui = game.Players.LocalPlayer.PlayerGui:WaitForChild("TutorialUI")
local board = ui.PlayArea.Board
assert(board.Ground.IsLoaded and board.Exit.Gate.IsLoaded)
assert(board.Exit.Remaining.AbsoluteSize == Vector2.new(18, 18))
print("BOMB_MAP_FINAL_CHECK", game.PlaceId, board.Ground.IsLoaded, board.Exit.Gate.IsLoaded, board.Exit.Remaining.AbsoluteSize)
