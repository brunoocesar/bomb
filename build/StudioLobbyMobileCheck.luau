assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
local ui=game.Players.LocalPlayer.PlayerGui.LobbyUI
local input=game:GetService("UserInputService")
assert(input.TouchEnabled,"Touch emulator not enabled")
assert(ui.Enabled and _G.BombLobbyQA.state.location=="lobby")
assert(ui.Background.IsLoaded and ui.Stage.Hero.IsLoaded,"Lobby artwork not loaded")
local function overlap(a,b)
 local p,q=a.AbsolutePosition,b.AbsolutePosition
 local x,y=a.AbsoluteSize,b.AbsoluteSize
 return p.X<q.X+y.X and q.X<p.X+x.X and p.Y<q.Y+y.Y and q.Y<p.Y+x.Y
end
assert(not overlap(ui.Stage,ui.RewardToast),"Reward hides hero stage")
assert(not overlap(ui.Next.Continue,ui.RewardToast),"Reward hides primary action")
for _,v in ipairs({ui.Stage.RotateLeft,ui.Stage.RotateRight,ui.Panel.Back}) do
 assert(v.AbsoluteSize.X>=44 and v.AbsoluteSize.Y>=44,"Small touch control: "..v.Name)
end
print("BOMB_LOBBY_MOBILE_LAYOUT_VERIFIED",ui.AbsoluteSize.X,ui.AbsoluteSize.Y,input.TouchEnabled)