assert(game.PlaceId==140221183064352)
_G.BombLobbyAutoAdvance={status="running"}
task.spawn(function()
 while _G.BombLobbyQA.state.location~="lobby" do
  if _G.BombMapRoute.stop then break end
  _G.BombMapRoute.advance=true
  _G.BombLobbyAutoAdvance.heartbeat=os.clock()
  task.wait(.5)
 end
 _G.BombLobbyAutoAdvance.status="finished"
 print("BOMB_LOBBY_INSPECTION_RELEASE_FINISHED")
end)