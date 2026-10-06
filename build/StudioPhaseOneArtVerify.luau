assert(game.PlaceId == 140221183064352, "Wrong place")
local marketplace = game:GetService("MarketplaceService")
for name, id in pairs({ atlas = 114790931774586, entrance = 76195326912660, courtyard = 112943965283471 }) do
	local ok, result = pcall(function()
		return marketplace:GetProductInfo(id, Enum.InfoType.Asset)
	end)
	if ok then
		print("BOMB_PHASE1_ASSET", name, id, result.Name, result.Creator.CreatorTargetId or result.Creator.Id, result.Creator.CreatorType)
	else
		warn("BOMB_PHASE1_ASSET_ERROR", name, result)
	end
end
print("BOMB_PHASE1_ACTIVE", require(game.ReplicatedStorage.Shared.Tutorial).phaseId, game.ReplicatedStorage.Assets.PhaseOneUI.ScreenInsets)
