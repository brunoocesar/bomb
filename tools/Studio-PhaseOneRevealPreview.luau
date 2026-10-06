-- Isolated visual fixture. It does not grant keys or complete gameplay.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 140221183064352, "Wrong project")
local player = game.Players.LocalPlayer
assert(player, "Use client")
local existing = player.PlayerGui:FindFirstChild("PhaseOneRevealPreviewQA")
if existing then existing:Destroy() end
game.ReplicatedStorage.Assets.TutorialRemotes.Input:FireServer("pause", true)
local ui = game.ReplicatedStorage.Assets.PhaseOneUI:Clone()
ui.Name, ui.DisplayOrder = "PhaseOneRevealPreviewQA", 99
for _, child in ipairs(ui:GetChildren()) do
	if child:IsA("GuiObject") then
		child.Visible = child.Name == "ChestReveal"
	end
end
local panel = ui.ChestReveal.Panel
local art = require(game.ReplicatedStorage.Shared.PhaseOneArt)
local map = require(game.ReplicatedStorage.Shared.MapCatalog)
local mapImages = require(game.ReplicatedStorage.Shared.MapImages)
local function sprite(view, imageId, rect, sourceSize, imageSize)
	view.Image = imageId
	view.Visible = true
	local sx, sy = imageSize[1] / sourceSize[1], imageSize[2] / sourceSize[2]
	local x, y = math.round(rect[1] * sx), math.round(rect[2] * sy)
	view.ImageRectOffset = Vector2.new(x, y)
	view.ImageRectSize = Vector2.new(math.round((rect[1] + rect[3]) * sx) - x, math.round((rect[2] + rect[4]) * sy) - y)
end
sprite(panel.Key, art.atlas, art.frames.sunKey, art.imageSize, art.atlasSize)
sprite(panel.Coins, mapImages.atlas, map.frames.coins, map.imageSize, mapImages.atlasSize)
panel.Detail.Text = "World 1 • Sun Key 1/4\n+20 coins • Reward saved."
ui.Parent = player.PlayerGui
panel.Skip.Activated:Connect(function()
	print("BOMB_REVEAL_PREVIEW_SKIPPED")
	ui:Destroy()
end)
print("BOMB_REVEAL_PREVIEW_READY", ui.AbsoluteSize, panel.AbsoluteSize)
