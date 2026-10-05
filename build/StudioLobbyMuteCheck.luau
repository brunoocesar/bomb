assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
_G.BombLobbyMuteQA={status="running"}
task.spawn(function()
 local qa=_G.BombLobbyQA
 local deadline=os.clock()+360
 while not qa.state or qa.state.location~="lobby" do
  assert(os.clock()<deadline,"Lobby diagnostic expired")
  _G.BombLobbyMuteQA.heartbeat=os.clock()
  task.wait(.1)
 end
 local ui=game.Players.LocalPlayer.PlayerGui.LobbyUI
 assert(ui.Panel.Content.Settings:FindFirstChild("Mute"),"New mute UI missing")
 assert(ui.Panel.Content.Profile.Save.Text=="Local Studio session","Save status missing")
 local settings=qa.state.settings
 local music,sfx=settings.music,settings.sfx
 local remote=game.ReplicatedStorage.Assets.TutorialRemotes.Input
 local sounds=game.SoundService.CampFeedback
 remote:FireServer("setting",{name="muted",value=true})
 task.wait(.4)
 assert(qa.state.settings.muted and sounds.Music.Volume==0 and sounds.Click.Volume==0 and sounds.Reward.Volume==0,"General mute failed")
 assert(ui.Panel.Content.Settings.Mute.Text=="MUTE ALL AUDIO: ON")
 remote:FireServer("setting",{name="muted",value=false})
 task.wait(.4)
 assert(not qa.state.settings.muted and qa.state.settings.music==music and qa.state.settings.sfx==sfx,"Mute changed preferences")
 assert(math.abs(sounds.Music.Volume-music*.25)<.001 and math.abs(sounds.Click.Volume-sfx*.35)<.001,"Volume not restored")
 _G.BombLobbyMuteQA.status="passed"
 print("BOMB_LOBBY_MUTE_VERIFIED",music,sfx,ui.Panel.Content.Profile.Save.Text)
end)