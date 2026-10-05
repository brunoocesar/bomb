assert(game.PlaceId==140221183064352 and game.CreatorId==204998424)
local expected={
 {"Music",139323405075519,"camp-theme-v1",24},
 {"Click",94723519223362,"menu-click-v1",.18},
 {"Reward",102483984204817,"reward-v1",.95},
}
task.spawn(function()
 for _,item in ipairs(expected) do
  local info=game:GetService("MarketplaceService"):GetProductInfoAsync(item[2],Enum.InfoType.Asset)
  assert(info.Creator.CreatorTargetId==204998424,"Unexpected audio owner")
  assert(info.Name==item[3],"Unexpected audio name")
  local sound=game.ReplicatedStorage.Assets.CampFeedback[item[1]]:Clone()
  sound.Name="BombCampAudioDiagnostic_"..item[1]
  sound.SoundId="rbxassetid://"..item[2]
  sound.Volume=0
  sound.Parent=game:GetService("SoundService")
  local deadline=os.clock()+20
  while not sound.IsLoaded and os.clock()<deadline do task.wait(.1) end
  print("BOMB_CAMP_AUDIO_CHECK",item[1],item[2],info.Creator.CreatorTargetId,sound.IsLoaded,sound.TimeLength)
  if sound.IsLoaded then
   assert(math.abs(sound.TimeLength-item[4])<.2,"Unexpected duration")
   sound:Play()
   task.wait(.08)
   print("BOMB_CAMP_AUDIO_PLAYBACK",item[1],sound.Playing,sound.TimePosition)
  end
  sound:Destroy()
 end
end)