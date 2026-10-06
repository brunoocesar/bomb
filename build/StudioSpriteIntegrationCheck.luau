assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
local p=game.Players.LocalPlayer
local assets=game.ReplicatedStorage.Assets
local run=game:GetService("RunService")
local ui=p.PlayerGui:WaitForChild("TutorialUI")
assets.TutorialRemotes.Input:FireServer("pause",false)
local sprite=ui.PlayArea.Board.Hero.Sprite
local last, changes, samples=nil,0,0
local connection=run.RenderStepped:Connect(function()
 samples+=1
 local key=tostring(sprite.ImageRectOffset)
 if key~=last then changes+=1;last=key; print("BOMB_ARENA_IDLE_FRAME",os.clock(),key,sprite.Size) end
end)
task.delay(12,function()
 connection:Disconnect()
 print("BOMB_ARENA_IDLE_OBSERVED",samples,changes,ui.ScreenInsets,ui.PlayArea.Board.PlayerShadow.BackgroundTransparency)
 local Controller=require(p.PlayerScripts.Client.LobbyController)
 local controller=Controller.new(p,assets,{Input={FireServer=function() error("Fixture must not send input") end}})
 local state=require(game.ReplicatedStorage.Shared.ProfileData).defaults(os.time())
 state.location="lobby";state.completed=true;state.finished=true;state.frogUnlocked=true;state.visited=true
 controller.ui.Name="SpriteLobbyDiagnostic";controller.ui.DisplayOrder=101
 controller:update(state);controller.mounted=false;controller:layout()
 _G.BombSpriteLobbyFixture=controller
 for direction=1,4 do
  controller.direction=direction
  controller:render(0)
  task.wait(.2)
  print("BOMB_LOBBY_SPRITE_DIRECTION",direction,controller.ui.Stage.Hero.Size,controller.ui.Stage.Frog.Size)
 end
 print("BOMB_LOBBY_SPRITE_FIXTURE_OK",controller.ui.Stage.FrogShadow.Visible,controller.ui.Stage.Shadow.BackgroundTransparency)
end)
