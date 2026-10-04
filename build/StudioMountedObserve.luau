assert(game.PlaceId == 140221183064352 and game.Players.LocalPlayer)
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
local connection
connection=remotes.State.OnClientEvent:Connect(function(s)
	if _G.BombMapRoute then _G.BombMapRoute.advance=true end
	if s.frog and s.mode=="playing" then
		connection:Disconnect()
		if _G.BombMapRoute then _G.BombMapRoute.stop=true end
		remotes.Input:FireServer("move","stop")
		task.delay(.3,function()
			remotes.Input:FireServer("pause",true)
			task.wait(.2)
			local ui=game.Players.LocalPlayer.PlayerGui.TutorialUI
			ui.PauseOverlay.Visible=false
			assert(not ui.PlayArea.Board.Frog.Visible,"separate frog drawn twice")
			local sprite=ui.PlayArea.Board.Hero.Sprite
			assert(sprite.Image=="rbxassetid://91298046318312","unified mounted atlas missing")
			local deadline=os.clock()+10
			repeat task.wait() until sprite.IsLoaded or os.clock()>deadline
			assert(sprite.IsLoaded,"mounted atlas did not load")
			print("BOMB_MOUNTED_RUNTIME_OK",s.stage,s.direction,s.skinPack,sprite.ImageRectSize,
				game:GetService("UserInputService").TouchEnabled)
		end)
	end
end)
