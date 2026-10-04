assert(game.PlaceId==140221183064352 and game.Players.LocalPlayer)
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
local Motion=require(game.ReplicatedStorage.Shared.ActorMotion)
local latest
local connection=remotes.State.OnClientEvent:Connect(function(s) latest=s end)
local function waitFor(test)
 local deadline=os.clock()+2
 repeat task.wait() until (latest and test(latest)) or os.clock()>deadline
 assert(latest and test(latest),"input response timeout")
end
remotes.Input:FireServer("ready")
task.spawn(function()
 local ok,err=pcall(function()
  waitFor(function(s) return not s.error end)
  remotes.Input:FireServer("pause",false)
  waitFor(function(s) return not s.paused end)
  remotes.Input:FireServer("move","left")
  waitFor(function(s) return s.direction=="left" end)
  local at=os.clock()
  remotes.Input:FireServer("move","right")
  waitFor(function(s) return s.direction=="right" and s.motion~=nil end)
  print("BOMB_BLOCKED_DIRECTION_RESPONSE_MS",math.floor((os.clock()-at)*1000))
  local began=latest.motion.at
  waitFor(function(s) return s.time>=began+.05 end)
  local x=Motion.position(latest,latest.time)
  at=os.clock()
  remotes.Input:FireServer("move","left")
  waitFor(function(s) return s.direction=="left" and s.x<x end)
  print("BOMB_REVERSE_RESPONSE_MS",math.floor((os.clock()-at)*1000))
  local reversed=latest.motion.at
  local reverseStart=latest.motion.x
  waitFor(function(s) return s.time>reversed end)
  assert(Motion.position(latest,latest.time)<reverseStart,"did not travel left")
  remotes.Input:FireServer("move","stop")
  print("BOMB_QUICK_REVERSAL_OK")
 end)
 connection:Disconnect()
 if not ok then warn("BOMB_QUICK_REVERSAL_FAIL",err) end
end)

