assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
local p=game.Players.LocalPlayer
if _G.BombLobbyPreviewQA then _G.BombLobbyPreviewQA:destroy() end
local module=p.PlayerScripts.Client.LobbyController:Clone()
module.Name="LobbyControllerPreviewDiagnostic"
module.Parent=p.PlayerScripts.Client
local Controller=require(module)
local controller=Controller.new(p,game.ReplicatedStorage.Assets,game.ReplicatedStorage.Assets.TutorialRemotes)
_G.BombLobbyPreviewQA=controller
controller.ui.Name="LobbyPreviewDiagnostic"
controller.ui.DisplayOrder=26
local state=require(game.ReplicatedStorage.Shared.ProfileData).defaults(os.time())
state.location="lobby"; state.completed=true; state.finished=true; state.frogUnlocked=true; state.visited=true
controller:update(state)
controller:open("Adventure")
controller:layout()
controller.ui.Panel.Content.CanvasPosition=Vector2.new(0,90)
task.wait(.2)
local c=controller.ui.Panel.Content.Adventure
assert(c:FindFirstChild("TrailPath"),"Trail connection absent in synced assets")
local path=c.TrailPath
assert(path.AbsoluteSize.X>0 and path.AbsoluteSize.Y==8)
for i=1,4 do
 local node=c["Trail_"..i]
 local x=node.AbsolutePosition.X+node.AbsoluteSize.X/2
 assert(x>=path.AbsolutePosition.X-.1 and x<=path.AbsolutePosition.X+path.AbsoluteSize.X+.1,"Path misses node")
end
print("BOMB_LOBBY_TRAIL_PATH_VERIFIED",path.AbsoluteSize)
module:Destroy()