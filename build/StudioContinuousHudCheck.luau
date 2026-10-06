assert(game.PlaceId==140221183064352)
local ui=game.Players.LocalPlayer.PlayerGui.TutorialUI
local g=game:GetService('GuiService')
local a=g:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
local b=g:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
local safe=math.max(0,b.Min.Y-a.Min.Y)
assert(ui.ScreenInsets==Enum.ScreenInsets.DeviceSafeInsets)
assert(ui.Header.Position.Y.Offset>=safe)
for _,name in ipairs({'Stage','Energy','Stats'}) do
 local v=ui.Header[name]
 print('BOMB_HUD_SAFE',name,v.TextFits,v.AbsolutePosition,v.AbsoluteSize,ui.AbsoluteSize,safe)
end
game.ReplicatedStorage.Assets.TutorialRemotes.Input:FireServer('pause',false)
