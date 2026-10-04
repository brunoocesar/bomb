assert(game.PlaceId==140221183064352 and game:GetService("UserInputService").TouchEnabled)
local board=game.Players.LocalPlayer.PlayerGui.TutorialUI.PlayArea.Board
assert(board.PlayerShadow.Visible and board.EnemyShadow_1.Visible)
assert(board.PlayerShadow.ZIndex<board.Hero.Sprite.ZIndex)
assert(board.EnemyShadow_1.ZIndex<board.Enemy_1.ZIndex)
assert(board.PlayerShadow.AbsoluteSize.X>0 and board.PlayerShadow.AbsoluteSize.Y>0)
print("BOMB_MOBILE_SHADOWS_OK",board.PlayerShadow.AbsoluteSize,board.EnemyShadow_1.AbsoluteSize)
