local r=game.ReplicatedStorage.Assets.TutorialRemotes
local c
c=r.State.OnClientEvent:Connect(function(s) print('BOMB_PHASE1_OBSERVE',s.x,s.y,s.stage,s.mode,s.deaths,s.energy,s.input[1],s.input[2]); c:Disconnect() end)
r.Input:FireServer('ready')
local t=_G.BombPhaseOneQA
print('BOMB_PHASE1_QA_STATUS',t.running,t.actions,t.stage,t.mode,t.deaths,t.error)
