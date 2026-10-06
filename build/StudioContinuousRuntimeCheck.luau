assert(game.PlaceId==140221183064352 and game:GetService('RunService'):IsClient())
local p=game.Players.LocalPlayer
local remotes=game.ReplicatedStorage.Assets.TutorialRemotes
local ui=p.PlayerGui.TutorialUI
local control={state=nil,frames=0,renderSamples={},done=false}
_G.BombContinuousQA=control
local stateConnection=remotes.State.OnClientEvent:Connect(function(s) control.state=s end)
local frameConnection=game:GetService('RunService').RenderStepped:Connect(function(dt)
 control.frames+=1
 table.insert(control.renderSamples,{os.clock(),ui.PlayArea.Board.Hero.Position.X.Scale*13+1,ui.PlayArea.Board.Hero.Position.Y.Scale*9+1,dt})
end)
local function hold(vector,seconds)
 local started=os.clock()
 repeat remotes.Input:FireServer('move',vector);task.wait(math.min(.15,seconds-(os.clock()-started))) until os.clock()-started>=seconds
end
local function report(name)
 local s=control.state
 print('BOMB_CONTINUOUS_RUNTIME',name,s.x,s.y,s.input[1],s.input[2],s.mode)
end
task.spawn(function()
 remotes.Input:FireServer('restart')
 remotes.Input:FireServer('pause',false)
 task.wait(.1)
 hold('down',3)
 remotes.Input:FireServer('move','stop');task.wait(.1)
 report('held-three-seconds')
 hold('up',1.35);hold('right',.18);hold('down',.13)
 report('fractional-turn')
 hold({1,1},.1);report('diagonal')
 hold('right',.6);report('wall-contact')
 hold({1,1},.25);report('wall-slide')
 remotes.Input:FireServer('move','stop');task.wait(.1)
 local x,y=control.state.x,control.state.y
 task.wait(.2)
 assert(control.state.x==x and control.state.y==y,'release drift')
 remotes.Input:FireServer('bomb');task.wait(.1)
 local cell=tostring(math.floor(x+.5))..':'..tostring(math.floor(y+.5))
 assert(control.state.bombs[cell],'between-cell bomb missing')
 print('BOMB_CONTINUOUS_BOMB_CELL',x,y,cell,control.state.bombs[cell].x,control.state.bombs[cell].y)
 hold('left',.5)
 hold('down',.6)
 remotes.Input:FireServer('move','stop');task.wait(.1)
 stateConnection:Disconnect();frameConnection:Disconnect();control.done=true
 local device=game:GetService('GuiService'):GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
 local core=game:GetService('GuiService'):GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
 assert(ui.Header.Position.Y.Offset>=core.Min.Y-device.Min.Y,'HUD intersects Roblox top bar')
 print('BOMB_CONTINUOUS_RUNTIME_FINISHED',control.frames,ui.AbsoluteSize,ui.Header.Position.Y.Offset,core.Min.Y-device.Min.Y)
end)
