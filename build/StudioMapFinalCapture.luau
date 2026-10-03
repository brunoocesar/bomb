local ui = game.Players.LocalPlayer.PlayerGui.TutorialUI
game:GetService("RunService").RenderStepped:Connect(function()
	ui.PauseOverlay.Visible = false
end)
print("BOMB_MAP_FINAL_CAPTURE", ui.PlayArea.Board.Exit.Remaining.Text)
