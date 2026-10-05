assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
local player=game.Players.LocalPlayer
local Controller=require(player.PlayerScripts.Client.LobbyController)
local state=table.clone(_G.BombLobbyQA.state)
state.completed=false; state.finished=false; state.frogUnlocked=false; state.visited=true
local requested={}
local test=Controller.new(player,game.ReplicatedStorage.Assets,{Input={FireServer=function(_,action,value) table.insert(requested,{action,value}) end}})
test.ui.Name="LobbyGuardDiagnostic"
test.ui.DisplayOrder=26
test:update(state)
test:open("Shop")
assert(test.panel=="Adventure" and test.lockedShopHint,"Pre-win shop was not blocked")
for _=1,5 do test:refresh() end
assert(test.ui.Panel.Content.Adventure.TrailHint.Text=="Win First Spark to open the camp store.","Lock explanation disappeared")
assert(#requested==0,"Blocked shop requested an action")
test:turn(1)
local direction=test.direction
test:open(nil)
assert(test.direction==direction and test.ui.Next.Visible)
assert(test.ui.Panel.Content.Frogs.Portrait.ImageColor3==Color3.new(.08,.12,.14),"Locked collection silhouette missing")
test:destroy()
print("BOMB_LOBBY_PREWIN_GUARD_VERIFIED","isolated controller fixture")