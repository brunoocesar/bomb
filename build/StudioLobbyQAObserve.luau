assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
_G.BombLobbyQA={}
remotes.State.OnClientEvent:Connect(function(s) _G.BombLobbyQA.state=s end)
remotes.Input:FireServer("ready")
local images=require(game.ReplicatedStorage.Shared.LobbyImages)
print("BOMB_LOBBY_CURRENT_IDS",images.background,images.icons)
local source=game.Players.LocalPlayer.PlayerScripts.Client.LobbyController.Source
print("BOMB_LOBBY_CURRENT_FIXES",source:find("geometry.reward",1,true)~=nil,source:find("lockedShopHint",1,true)~=nil)