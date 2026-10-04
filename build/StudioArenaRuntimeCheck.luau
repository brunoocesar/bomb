assert(game.PlaceId==140221183064352 and game.Players.LocalPlayer)
local ui=game.Players.LocalPlayer.PlayerGui.TutorialUI
local Layout=require(game.ReplicatedStorage.Shared.ArenaLayout)
local g=Layout.compute(ui.AbsoluteSize.X,ui.AbsoluteSize.Y)
local board=ui.PlayArea.Board
assert(math.abs(board.AbsoluteSize.X/13-board.AbsoluteSize.Y/9)<1)
assert(math.abs(board.AbsoluteSize.X-g.board[3])<2,"board does not match available space")
for _,view in ipairs({ui.Header.Stage,ui.Header.Energy,ui.Header.Stats,ui.Hint}) do
 assert(view.TextBounds.X<=view.AbsoluteSize.X+1 and view.TextBounds.Y<=view.AbsoluteSize.Y+1,"text cropped: "..view.Name)
end
local old=g.wide and math.min(ui.AbsoluteSize.X-264,(ui.AbsoluteSize.Y-80)*13/9) or math.min(ui.AbsoluteSize.X-24,(ui.AbsoluteSize.Y-240)*13/9)
print("BOMB_ARENA_RUNTIME_GEOMETRY",ui.AbsoluteSize,old,board.AbsoluteSize,game:GetService("UserInputService").TouchEnabled)
_G.LayoutRouteAdvance=game:GetService("RunService").RenderStepped:Connect(function()
 if _G.BombMapRoute then _G.BombMapRoute.advance=true end
end)
