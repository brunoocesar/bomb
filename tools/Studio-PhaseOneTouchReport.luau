assert(game.PlaceId == 140221183064352, "Wrong project")
assert(game:GetService("RunService"):IsClient(), "Use the Studio client")
local remotes = game.ReplicatedStorage.Assets.TutorialRemotes
local connection
connection = remotes.State.OnClientEvent:Connect(function(state)
	connection:Disconnect()
	print("BOMB_PHASE1_TOUCH_RESULT", state.mode, state.deaths, state.x, state.y, state.firstMove, state.firstBomb, state.firstBlock)
	assert(state.mode == "playing" and state.deaths == 0, "Touch escape did not survive")
	assert(state.firstMove and state.firstBomb and state.firstBlock, "Movement, bomb and destruction must be observed")
	print("BOMB_PHASE1_TOUCH_VERIFIED")
end)
remotes.Input:FireServer("ready")
