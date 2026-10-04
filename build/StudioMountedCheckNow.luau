assert(game.PlaceId==140221183064352 and game.Players.LocalPlayer)
local ui=game.Players.LocalPlayer.PlayerGui.TutorialUI
local sprite=ui.PlayArea.Board.Hero.Sprite
print("BOMB_MOUNTED_LOAD_STATE",sprite.Image,sprite.IsLoaded,sprite.Visible,sprite.ImageRectOffset,sprite.ImageRectSize)
ui.PauseOverlay.Visible=false
local overlay=game:GetService("RunService").RenderStepped:Connect(function() ui.PauseOverlay.Visible=false end)
_G.MountedPauseOverlay=overlay
task.spawn(function()
	game:GetService("ContentProvider"):PreloadAsync({sprite.Image},function(id,status) print("BOMB_MOUNTED_PRELOAD",id,status) end)
	task.wait(1)
	print("BOMB_MOUNTED_LOADED",sprite.IsLoaded)
end)
