assert(game.PlaceId == 140221183064352 and game.CreatorId == 204998424, "Wrong project")
local marketplace = game:GetService("MarketplaceService")
local assets = game:GetService("AssetService")
local images = require(game.ReplicatedStorage.Shared.SpriteImages)
for _, name in ipairs({ "heroCream", "heroMovementCream", "mountedCream", "heroScarf", "heroMovementScarf", "mountedScarf" }) do
    local id = tonumber(string.match(images[name], "%d+"))
    local info = marketplace:GetProductInfo(id, Enum.InfoType.Asset)
    assert(info.Creator.CreatorTargetId == 204998424 and info.Creator.CreatorType == "Group", name .. " wrong owner")
    local editable = assets:CreateEditableImageAsync(Content.fromUri(images[name]))
    assert(editable.Size == Vector2.new(1024, 1024), name .. " wrong dimensions")
    print("BOMB_REWARD_ASSET", name, id, info.Name, info.Creator.CreatorTargetId, editable.Size)
    editable:Destroy()
end
print("BOMB_REWARD_ASSETS_VERIFIED", 6)
