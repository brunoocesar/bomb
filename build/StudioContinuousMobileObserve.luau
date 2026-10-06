assert(game.PlaceId==140221183064352)
local r=game.ReplicatedStorage.Assets.TutorialRemotes
local c={input=nil,done=false}
_G.BombMobileMovement=c
local connection=r.State.OnClientEvent:Connect(function(s)
 local value=tostring(s.input[1])..','..tostring(s.input[2])
 if value~=c.input then print('BOMB_MOBILE_CONTROL',s.x,s.y,value,s.inputSequence);c.input=value end
end)
r.Input:FireServer('pause',false)
task.delay(8,function() connection:Disconnect();c.done=true;print('BOMB_MOBILE_CONTROLS_FINISHED') end)
