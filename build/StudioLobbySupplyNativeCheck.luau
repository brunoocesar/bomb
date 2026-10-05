assert(game.PlaceId==140221183064352)
local ui=game.Players.LocalPlayer.PlayerGui.LobbyUI
local qa=_G.BombLobbyQA
local before=qa.state.coins
local sound=game.SoundService.CampFeedback.Reward
local heard=false
sound.Played:Connect(function() heard=true; print("BOMB_LOBBY_REWARD_SOUND_NATIVE",sound.IsLoaded,sound.Volume) end)
ui.Panel.Content.Shop.Supply.Claim.Activated:Connect(function()
 task.wait(.5)
 assert(qa.state.coins==before+3,"Supply amount changed or duplicated")
 assert(qa.state.supplies.lastDay==qa.state.daily.day)
 assert(heard,"Reward sound missing")
 print("BOMB_LOBBY_SUPPLY_NATIVE",before,qa.state.coins,ui.Panel.Content.Shop.Supply.Claim.Text)
end)
print("BOMB_LOBBY_SUPPLY_OBSERVER_READY",before)