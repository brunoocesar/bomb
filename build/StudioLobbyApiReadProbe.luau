assert(game.PlaceId==140221183064352 and game.GameId==10769176732 and game:GetService("RunService"):IsStudio())
task.spawn(function()
 local ok,result=pcall(function()
  return game:GetService("DataStoreService"):GetDataStore("BombYourWay_Lobby_QA_v1"):GetAsync("qa-permission-probe")
 end)
 if ok then print("BOMB_LOBBY_API_READ_PROBE",true,type(result))
 else warn("BOMB_LOBBY_API_READ_PROBE",false,tostring(result)) end
end)