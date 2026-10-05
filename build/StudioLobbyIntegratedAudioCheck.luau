assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
local qa=_G.BombLobbyQA
assert(qa,"Snapshot observer missing")
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
_G.BombLobbyAudioQA={state="waiting"}
task.spawn(function()
 local deadline=os.clock()+180
 while qa.state.location~="lobby" and os.clock()<deadline do task.wait(.1) end
 assert(qa.state.location=="lobby","Lobby not reached within diagnostic deadline")
 local sounds=game:GetService("SoundService"):WaitForChild("CampFeedback")
 assert(sounds.Music.SoundId=="rbxassetid://139323405075519" and sounds.Music.IsLoaded,"Integrated music missing")
 assert(sounds.Music.Playing,"Camp music not playing")
 local position=sounds.Music.TimePosition
 task.wait(.2)
 assert(sounds.Music.TimePosition~=position,"Camp music is not advancing")
 remotes.Input:FireServer("setting",{name="music",value=0})
 task.wait(.3)
 assert(sounds.Music.Volume==0,"Music mute failed")
 remotes.Input:FireServer("setting",{name="music",value=.75})
 remotes.Input:FireServer("setting",{name="sfx",value=.4})
 task.wait(.3)
 assert(math.abs(sounds.Music.Volume-.1875)<.001,"Music preference ignored")
 assert(math.abs(sounds.Click.Volume-.14)<.001 and math.abs(sounds.Reward.Volume-.18)<.001,"Effects preference ignored")
 remotes.Input:FireServer("playPhase","first_spark")
 task.wait(.3)
 assert(qa.state.location=="adventure" and not sounds.Music.Playing,"Camp music continued during adventure")
 remotes.Input:FireServer("lobby")
 task.wait(.3)
 assert(qa.state.location=="lobby" and sounds.Music.Playing,"Camp music did not resume")
 _G.BombLobbyAudioQA.state="passed"
 print("BOMB_LOBBY_INTEGRATED_AUDIO_VERIFIED",sounds.Music.TimeLength,sounds.Music.Volume,sounds.Click.Volume,sounds.Reward.Volume)
end)