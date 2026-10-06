assert(game.PlaceId==140221183064352 and game.GameId==10769176732 and game:GetService("RunService"):IsStudio())
local Http=game:GetService("HttpService")
local Repo=require(game.ServerScriptService.Server.ProfileRepository)
local Progress=require(game.ReplicatedStorage.Shared.LobbyProgress)
local Data=require(game.ReplicatedStorage.Shared.ProfileData)
local store=game:GetService("DataStoreService"):GetDataStore("BombYourWay_Lobby_QA_v1")
local key="qa-"..Http:GenerateGUID(false)
_G.BombLobbyCloudQA={status="running",key=key}
task.spawn(function()
 local function service() return Repo.new(store,os.time,function() return Http:GenerateGUID(false) end) end
 local first=service()
 local a=first.open(key)
 if not a then
  _G.BombLobbyCloudQA.status="unavailable"
  warn("BOMB_LOBBY_CLOUD_QA_UNAVAILABLE","Isolated QA profile could not open; no player profiles accessed")
  return
 end
 local ok,err=pcall(function()
  assert(not a.localOnly and not Data.isReturning(a.data))
  a.data.visited=true; a.data.completed=true; a.data.stage=2; a.data.frogUnlocked=true
  Progress.setting(a.data,"muted",true)
  assert(Progress.claim(a.data,"supply",os.time()))
  local coins=a.data.coins
  assert(first.save(a,a.data,true),"QA save failed")
  local second=service()
  local b=second.open(key)
  assert(b and Data.isReturning(b.data),"QA reopen failed")
  assert(b.data.stage==2 and b.data.frogUnlocked and b.data.settings.muted,"QA state changed")
  assert(b.data.coins==coins and not Progress.claim(b.data,"supply",os.time()),"QA reward duplicated")
  assert(not first.save(a,a.data,false),"Old token overwritten new session")
  assert(second.save(b,b.data,true))
  print("BOMB_LOBBY_CLOUD_QA_VERIFIED",b.data.stage,b.data.coins,b.data.settings.muted)
 end)
 local cleaned=pcall(function() store:RemoveAsync(key) end)
 _G.BombLobbyCloudQA.status=ok and "passed" or "failed"
 _G.BombLobbyCloudQA.cleaned=cleaned
 if not ok then warn("BOMB_LOBBY_CLOUD_QA_FAILED",tostring(err)) end
 print("BOMB_LOBBY_CLOUD_QA_CLEANED",cleaned)
end)