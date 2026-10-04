assert(game.PlaceId==140221183064352 and game.Players.LocalPlayer)
local ui=game.Players.LocalPlayer.PlayerGui.TutorialUI
local seen=false
_G.FeedbackObserver=game:GetService("RunService").RenderStepped:Connect(function()
 if seen then return end
 for _,effect in ipairs(ui.PlayArea.Board.Effects:GetChildren()) do
  if effect.Visible and effect.Piece_1.ImageTransparency>0 then
   seen=true
   print("BOMB_FEEDBACK_ANIMATED",effect.Piece_1.Rotation,effect.Piece_1.ImageTransparency,ui.Header.Stats.Text)
  end
 end
end)
print("BOMB_FEEDBACK_HUD",ui.Status.Mount.Text,ui.Status.Coins.Text,ui:GetAttribute("ArenaDebug"))
