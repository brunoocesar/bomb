assert(game.PlaceId==140221183064352)
local player=game.Players.LocalPlayer
local ui=player.PlayerGui:FindFirstChild("TutorialUI")
assert(ui)
ui:SetAttribute("ArenaDebug",true)
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
_G.BombStoneContact=nil
local connection=remotes.State.OnClientEvent:Connect(function(s) _G.BombStoneContact=s end)
task.spawn(function()
 remotes.Input:FireServer("pause",false)
 remotes.Input:FireServer("move","down")
 task.wait(.49)
 remotes.Input:FireServer("move","right")
 task.wait(.8)
 remotes.Input:FireServer("move","stop")
 task.wait(.15)
 local s=_G.BombStoneContact
 local x,y=require(game.ReplicatedStorage.Shared.ActorMotion).position(s,s.time)
 print("BOMB_STONE_CONTACT_RUNTIME",x,y,s.tiles["5:4"],ui.AbsoluteSize)
 connection:Disconnect()
end)