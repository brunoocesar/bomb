assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
assert(_G.BombLobbyQA.state.location=="lobby")
task.spawn(function()
 local function send(action,value)
  remotes.Input:FireServer(action,value)
  task.wait(.3)
  return _G.BombLobbyQA.state
 end
 local before=_G.BombLobbyQA.state.coins
 local state=send("claimReward","energy")
 assert(state.coins==before+5 and state.daily.energyClaimed,"Energy reward")
 state=send("claimReward","energy")
 assert(state.coins==before+5,"Energy reward duplicated")
 state=send("claimReward","supply")
 assert(state.coins==before+8 and state.supplies.count==1,"Supply reward")
 state=send("claimReward","supply")
 assert(state.coins==before+8 and state.supplies.count==1,"Supply reward duplicated")
 state=send("claimReward","clear")
 assert(state.coins==before+8,"Unfinished clean run rewarded")
 state=send("equipSkinPack","missing_pack")
 assert(state.skinPack=="base","Unknown pack equipped")
 print("BOMB_LOBBY_REWARDS_VERIFIED",before,state.coins,state.supplies.count)
end)