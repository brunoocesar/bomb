assert(game.PlaceId==140221183064352)
local sound=game.SoundService.CampFeedback.Click
local c
c=sound.Played:Connect(function() print("BOMB_LOBBY_NATIVE_CLICK_AUDIO",sound.IsLoaded,sound.Volume); c:Disconnect() end)
print("BOMB_LOBBY_NATIVE_CLICK_OBSERVER_READY")