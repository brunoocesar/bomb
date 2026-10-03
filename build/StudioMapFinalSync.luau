assert(game.PlaceId == 140221183064352)
assert(not game:GetService("RunService"):IsRunning())
local storage = game:GetService("ReplicatedStorage")
local images = require(storage.Shared.MapImages)
assert(images.atlas == "rbxassetid://123264576899987")
assert(images.garden == "rbxassetid://131156549136240")
assert(images.courtyard == "rbxassetid://100575841870639")
for _, name in { "TutorialUI", "TutorialCompactUI" } do
	local board = storage.Assets[name].PlayArea.Board
	assert(board.Ground:IsA("ImageLabel") and board.Exit.Gate:IsA("ImageLabel"))
	assert(board.Exit.Remaining.Size == UDim2.fromOffset(18, 18))
end
print("BOMB_MAP_FINAL_SYNC", game.PlaceId, images.atlas, images.garden, images.courtyard, "edit mode; both authored layouts verified")
