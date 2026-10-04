assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
local connection
connection=remotes.State.OnClientEvent:Connect(function(state)
 if state.mode=="won" and state.location=="adventure" then
  print("BOMB_LOBBY_VICTORY",state.deaths,state.completed)
  remotes.Input:FireServer("lobby")
 elseif state.location=="lobby" then
  print("BOMB_LOBBY_ENTERED",state.completed,state.frogUnlocked)
  connection:Disconnect()
 end
end)
remotes.Input:FireServer("ready")