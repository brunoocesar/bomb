assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
local qa=_G.BombLobbyQA
assert(qa and qa.state.location=="lobby")
task.spawn(function()
 local function send(action,value)
  remotes.Input:FireServer(action,value)
  task.wait(.3)
  return qa.state
 end
 local coins=qa.state.coins
 local s=send("playPhase","first_spark")
 assert(s.location=="adventure" and s.mode=="playing" and s.stage==1,"Replay did not start")
 assert(s.completed and s.frogUnlocked and s.coins==coins,"Replay lost account progress")
 s=send("settings")
 assert(s.location=="settings" and s.paused,"Pause settings did not open")
 local time=s.time
 task.wait(.5)
 assert(qa.state.time==time,"Game moved behind settings")
 s=send("setting",{name="largeText",value=true})
 assert(s.settings.largeText,"Settings change rejected")
 s=send("closeSettings")
 assert(s.location=="adventure" and s.paused,"Settings did not preserve pause")
 s=send("lobby")
 assert(s.location=="lobby","Camp did not reopen")
 local stage,x,y=s.stage,s.x,s.y
 s=send("continue")
 assert(s.location=="adventure" and s.stage==stage and s.x==x and s.y==y,"Continue lost checkpoint position")
 s=send("lobby")
 assert(s.location=="lobby" and s.settings.largeText,"Return lost settings")
 print("BOMB_LOBBY_FLOW_VERIFIED",s.stage,s.coins,s.settings.largeText)
end)