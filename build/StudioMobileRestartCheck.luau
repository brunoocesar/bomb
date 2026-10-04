assert(game.PlaceId==140221183064352 and game.Players.LocalPlayer)
local ui=game.Players.LocalPlayer.PlayerGui.TutorialUI
assert(not ui.Death.Visible,"stage did not restart")
for _,view in ipairs(ui.PlayArea.Board.Effects:GetChildren()) do assert(not view.Visible,"stale debris after restart") end
print("BOMB_MOBILE_RESTART_CLEAN")
