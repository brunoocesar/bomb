assert(game.PlaceId==140221183064352)
local ui=game.Players.LocalPlayer.PlayerGui.LobbyUI
ui.Panel.Content.Character.Equip.Activated:Connect(function()
 task.wait(.4)
 local s=_G.BombLobbyQA.state
 assert(s.skinPack=="base" and s.ownedSkinPacks.base,"Owned pack missing")
 assert(ui.Panel.Content.Character.Equip.Text=="EQUIPPED")
 print("BOMB_LOBBY_EQUIP_NATIVE",s.skinPack,s.coins,s.frogUnlocked)
end)
print("BOMB_LOBBY_EQUIP_OBSERVER_READY")