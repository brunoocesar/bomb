assert(game.PlaceId==140221183064352 and game:GetService('RunService'):IsClient())
local p=game.Players.LocalPlayer
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
local ui=p.PlayerGui.TutorialUI
local c={samples={},states={},done=false}
_G.BombNativeMovement=c
local stateConnection=remotes.State.OnClientEvent:Connect(function(s) table.insert(c.states,{os.clock(),s.x,s.y,s.input[1],s.input[2]}) end)
local frameConnection=game:GetService('RunService').RenderStepped:Connect(function(dt)
 local v=ui.PlayArea.Board.Hero
 table.insert(c.samples,{os.clock(),v.Position.X.Scale*13+1,v.Position.Y.Scale*9+1,dt})
end)
remotes.Input:FireServer('pause',false)
task.delay(18,function()
 stateConnection:Disconnect();frameConnection:Disconnect();c.done=true
 local changes,backsteps=0,0
 for i=2,#c.samples do
  local a,b=c.samples[i-1],c.samples[i]
  if math.abs(b[2]-a[2])+math.abs(b[3]-a[3])>1e-5 then changes+=1 end
 end
 print('BOMB_NATIVE_MOVEMENT_OBSERVED',#c.samples,#c.states,changes)
end)
