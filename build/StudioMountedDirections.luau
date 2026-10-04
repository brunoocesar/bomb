assert(game.PlaceId==140221183064352 and game.Players.LocalPlayer)
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
local Catalog=require(game.ReplicatedStorage.Shared.SpriteCatalog)
local Motion=require(game.ReplicatedStorage.Shared.ActorMotion)
local ui=game.Players.LocalPlayer.PlayerGui.TutorialUI
local latest
local connection=remotes.State.OnClientEvent:Connect(function(s) latest=s end)
local function waitFor(test)
	local deadline=os.clock()+3
	repeat task.wait() until (latest and test(latest)) or os.clock()>deadline
	assert(latest and test(latest),"mounted direction timeout")
end
_G.MountedPauseOverlay=game:GetService("RunService").RenderStepped:Connect(function() ui.PauseOverlay.Visible=false end)
remotes.Input:FireServer("ready")
task.spawn(function()
	local ok,err=pcall(function()
		waitFor(function(s) return s.frog end)
		for _,direction in ipairs({"down","left","right","up","down"}) do
			remotes.Input:FireServer("pause",false)
			waitFor(function(s) return not s.paused end)
			remotes.Input:FireServer("move",direction)
			waitFor(function(s) return s.direction==direction end)
			remotes.Input:FireServer("move","stop")
			waitFor(function(s) return not s.motion or s.time>=s.motion.at+s.motion.duration end)
			remotes.Input:FireServer("pause",true)
			waitFor(function(s) return s.paused end)
			task.wait(.1)
			local sprite=ui.PlayArea.Board.Hero.Sprite
			local sequence=Catalog.animations.mounted.idle[direction]
			local atlas=Catalog.atlases.mounted
			local frame=atlas.frames[sequence[2]*atlas.columns+1]
			assert(sprite.IsLoaded and sprite.Image=="rbxassetid://91298046318312")
			assert(not ui.PlayArea.Board.Frog.Visible,"double mount rendered")
			local support=sprite.AbsolutePosition+sprite.AbsoluteSize*Vector2.new(unpack(frame.groundPivot))
			local px,py=Motion.position(latest,latest.time)
			local board=ui.PlayArea.Board
			local expected=board.AbsolutePosition+board.AbsoluteSize*Vector2.new((px-.5)/13,(py-.18)/9)
			assert((support-expected).Magnitude<1.5,"ground support shifted")
			local ratio=sprite.AbsoluteSize.X/sprite.AbsoluteSize.Y
			assert(math.abs(ratio-frame.rect[3]/frame.rect[4])<.04,"mounted image stretched")
			print("BOMB_MOUNTED_DIRECTION_OK",direction,sprite.ImageRectOffset,sprite.ImageRectSize,(support-expected).Magnitude)
		end
		print("BOMB_MOUNTED_DIRECTIONS_RUNTIME_OK",game:GetService("UserInputService").TouchEnabled)
	end)
	connection:Disconnect()
	if not ok then warn("BOMB_MOUNTED_DIRECTIONS_RUNTIME_FAIL",err) end
end)
