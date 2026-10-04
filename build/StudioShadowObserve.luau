assert(game.PlaceId==140221183064352 and game.Players.LocalPlayer)
local ui=game.Players.LocalPlayer.PlayerGui.TutorialUI
local latest
local motionOK,mountOK=false,false
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
local Motion=require(game.ReplicatedStorage.Shared.ActorMotion)
remotes.State.OnClientEvent:Connect(function(s) latest=s end)
remotes.Input:FireServer("ready")
_G.ShadowObserver=game:GetService("RunService").RenderStepped:Connect(function()
 if _G.BombMapRoute then _G.BombMapRoute.advance=true end
 if not latest or latest.error then return end
 local board=ui.PlayArea.Board
 local move=latest.motion
 if move and not motionOK and latest.time>=move.at+move.duration*.8 and latest.time<move.at+move.duration then
  assert(move.duration==require(game.ReplicatedStorage.Shared.Tutorial).moveInterval)
  assert(board.PlayerShadow.Visible)
  assert(board.PlayerShadow.ZIndex<board.Hero.Sprite.ZIndex)
  motionOK=true
  print("BOMB_CONTINUOUS_PLAYER_OK",move.duration,latest.time-move.at)
 end
 for i,enemy in ipairs(latest.enemies) do
  if enemy.alive then assert(board["EnemyShadow_"..i].Visible) end
 end
 if latest.frog and not mountOK then
  assert(board.PlayerShadow.Visible)
  assert(math.abs(board.PlayerShadow.Size.X.Scale-.78/13)<.0001)
  mountOK=true
  print("BOMB_MOUNT_SHADOW_OK")
 end
end)
print("BOMB_SHADOW_OBSERVER_READY")
