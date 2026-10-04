assert(game.PlaceId == 140221183064352 and game.Players.LocalPlayer)
local remotes = game.ReplicatedStorage.Assets.TutorialRemotes
local Motion = require(game.ReplicatedStorage.Shared.ActorMotion)
local latest
local connection = remotes.State.OnClientEvent:Connect(function(s) latest = s end)
local function waitFor(test)
	local deadline = os.clock() + 3
	repeat task.wait() until (latest and test(latest)) or os.clock() > deadline
	assert(latest and test(latest), "cross-axis input timeout")
end
local function settle()
	remotes.Input:FireServer("move", "stop")
	waitFor(function(s) return not s.motion or s.time >= s.motion.at + s.motion.duration end)
end
local function oneStep(direction)
	local began = latest.motion and latest.motion.at or -1
	remotes.Input:FireServer("move", direction)
	waitFor(function(s) return s.motion and s.motion.at > began and s.motion.input == direction end)
	settle()
end
remotes.Input:FireServer("ready")
task.spawn(function()
	local ok, err = pcall(function()
		waitFor(function(s) return not s.error end)
		remotes.Input:FireServer("pause", false)
		waitFor(function(s) return not s.paused end)
		assert(latest.stage == 1, "Run this check at the first stage")
		settle()
		for _, pair in ipairs({{"left","up"},{"left","down"},{"right","up"},{"right","down"},
			{"up","left"},{"up","right"},{"down","left"},{"down","right"}}) do
			while latest.x ~= 3 do oneStep(latest.x < 3 and "right" or "left") end
			while latest.y ~= 3 do oneStep(latest.y < 3 and "down" or "up") end
			local oldAt = latest.motion and latest.motion.at or -1
			remotes.Input:FireServer("move", pair[1])
			waitFor(function(s) return s.motion and s.motion.at > oldAt and s.motion.input == pair[1] end)
			local began = latest.motion.at
			waitFor(function(s) return s.time >= began + 0.05 end)
			local at = os.clock()
			remotes.Input:FireServer("move", pair[2])
			waitFor(function(s) return s.motion and s.motion.at > began and s.motion.input == pair[2] end)
			local move = latest.motion
			local x,y = Motion.position(latest, move.at + 0.005)
			assert((pair[2] == "up" and y < move.y and x == move.x)
				or (pair[2] == "down" and y > move.y and x == move.x)
				or (pair[2] == "left" and x < move.x and y == move.y)
				or (pair[2] == "right" and x > move.x and y == move.y), "requested axis delayed")
			print("BOMB_CROSS_AXIS_RESPONSE", pair[1], pair[2], math.floor((os.clock()-at)*1000))
			settle()
		end
		print("BOMB_CROSS_AXIS_RUNTIME_OK", game:GetService("UserInputService").TouchEnabled)
	end)
	connection:Disconnect()
	if not ok then warn("BOMB_CROSS_AXIS_RUNTIME_FAIL", err) end
end)
