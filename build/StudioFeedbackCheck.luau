assert(game.PlaceId == 140221183064352 and not game:GetService("RunService"):IsRunning())
local rs=game.ReplicatedStorage
assert(rs.Shared.FeedbackPresentation and rs.Shared.ActorMotion and rs.Shared.BlastVisual)
assert(rs.Assets.TutorialUI.PlayArea.Board.Effects.Destroy_16)
assert(rs.Assets.TutorialUI.Status.Mount)
assert(game.ServerScriptService.Server:FindFirstChild("Tutorial"))
assert(game.StarterPlayer.StarterPlayerScripts.Client:FindFirstChild("Tutorial"))
print("BOMB_FEEDBACK_SYNC_OK",game.PlaceId)
