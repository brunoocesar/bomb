assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
assert(_G.BombMapRoute,"Route controller missing")
task.spawn(function()
 local deadline=os.clock()+300
 while os.clock()<deadline and not _G.BombMapRoute.stop do
  _G.BombMapRoute.advance=true
  task.wait(.2)
 end
end)
print("BOMB_LOBBY_ROUTE_AUTO_ADVANCE")