assert(game.PlaceId == 140221183064352)
assert(game.CreatorId == 204998424)
for _, id in ipairs({91547200008356,131533049817842}) do
	local info=game:GetService("MarketplaceService"):GetProductInfoAsync(id,Enum.InfoType.Asset)
	assert(info.Creator.CreatorTargetId==204998424,"Unexpected image owner")
	print("BOMB_LOBBY_ASSET",id,info.Name,info.Creator.CreatorTargetId)
	local ok,image=pcall(function()
		return game:GetService("AssetService"):CreateEditableImageAsync(Content.fromAssetId(id))
	end)
	if ok and image then
		print("BOMB_LOBBY_IMAGE_SIZE",id,image.Size.X,image.Size.Y)
		image:Destroy()
	else
		warn("BOMB_LOBBY_IMAGE_SIZE_PENDING",id,tostring(image))
	end
end
local source=game.StarterPlayer.StarterPlayerScripts.Client.Tutorial.Source
print("BOMB_LOBBY_SOURCE_SYNC",source:find("CampFeedback",1,true)~=nil)
