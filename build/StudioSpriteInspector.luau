assert(game.PlaceId == 140221183064352 and game:GetService("RunService"):IsStudio())
local player = game.Players.LocalPlayer
local shared = game.ReplicatedStorage.Shared
local Catalog = require(shared.SpriteCatalog)
local Images = require(shared.SpriteImages)
local Layout = require(shared.SpriteLayout)
local selector = require(shared.SpriteAnimation).new(function() return .5 end)
local gui = Instance.new("ScreenGui")
gui.Name = "SpriteFrameDiagnostic"
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.DisplayOrder = 100
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui
local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1,1)
root.BackgroundColor3 = Color3.fromRGB(230,235,239)
root.Parent = gui
local views = {}
local control = {time=0, playing=false, frames={"hero_r3_c0","frog_r4_c0","frog_r5_c3"}}
_G.BombSpriteInspect = control
local function label(text,x,y,w,h)
 local v=Instance.new("TextLabel")
 v.Text=text;v.TextColor3=Color3.fromRGB(23,42,59);v.BackgroundTransparency=1
 v.Position=UDim2.fromScale(x,y);v.Size=UDim2.fromScale(w,h)
 v.TextSize=16;v.TextWrapped=true;v.Parent=root
 return v
end
label("Frozen frame inspector | blue: crop | pink: ground anchor | common pixel scale",0,.08,1,.1)
for i,kind in ipairs({"hero","frog","frog"}) do
 local v=Instance.new("ImageLabel")
 v.Name="Sprite"..i;v.BackgroundTransparency=1;v.ScaleType=Enum.ScaleType.Stretch;v.ZIndex=4
 v.BorderSizePixel=1;v.BorderColor3=Color3.fromRGB(20,130,230);v.Parent=root
 local stroke=Instance.new("UIStroke");stroke.Color=v.BorderColor3;stroke.Thickness=1;stroke.Parent=v
 local dot=Instance.new("Frame")
 dot.Size=UDim2.fromOffset(7,7);dot.AnchorPoint=Vector2.new(.5,.5)
 dot.BackgroundColor3=Color3.fromRGB(235,35,130);dot.BorderSizePixel=0;dot.ZIndex=5;dot.Parent=root
 local shadow=game.ReplicatedStorage.Assets.TutorialUI.PlayArea.Board.PlayerShadow:Clone()
 shadow.Visible=true;shadow.Parent=root
 views[i]={sprite=v,dot=dot,shadow=shadow,kind=kind,title=label("",(i-1)/3,.2,1/3,.12)}
end
local previous={}
local connection
connection=game:GetService("RunService").RenderStepped:Connect(function(dt)
 if not gui.Parent then connection:Disconnect();return end
 if control.playing then control.time+=dt end
 local width,height=gui.AbsoluteSize.X,gui.AbsoluteSize.Y
 for i,view in ipairs(views) do
  local frame,atlasId,blink
  if control.playing then
   frame,atlasId,blink=selector:select(i,"base",view.kind,i==3 and "jump" or "idle","down",control.time)
  else
   atlasId=view.kind
   for _,candidate in ipairs(Catalog.atlases[atlasId].frames) do if candidate.id==control.frames[i] then frame=candidate;break end end
  end
  assert(frame)
  local atlas=Catalog.atlases[atlasId]
  local size=Images.imageSizes[atlasId]
  local sx,sy=size[1]/atlas.imageSize[1],size[2]/atlas.imageSize[2]
  local rect=frame.rect
  local left,top=math.round(rect[1]*sx),math.round(rect[2]*sy)
  local scale=Layout.fit(atlasId,width*.27,height*.46)
  local w,h=rect[3]*scale,rect[4]*scale
  local ax,ay=width*(i-.5)/3,height*.79
  view.sprite.Position=UDim2.fromOffset(ax-frame.groundPivot[1]*w,ay-frame.groundPivot[2]*h)
  view.sprite.Size=UDim2.fromOffset(w,h)
  view.sprite.Image=Images[atlasId]
  view.sprite.ImageRectOffset=Vector2.new(left,top)
  view.sprite.ImageRectSize=Vector2.new(math.round((rect[1]+rect[3])*sx)-left,math.round((rect[2]+rect[4])*sy)-top)
  view.dot.Position=UDim2.fromOffset(ax,ay)
  view.shadow.Position=UDim2.fromOffset(ax,ay)
  view.shadow.Size=UDim2.fromOffset(width*.12,width*.027)
  view.title.Text=frame.id..(blink and " / BLINK" or "")
  if previous[i]~=frame.id then
   print("BOMB_SPRITE_FRAME_RENDER",i,frame.id,math.round(control.time*1000)/1000,view.sprite.ImageRectOffset,view.sprite.ImageRectSize)
   previous[i]=frame.id
  end
 end
end)
control.stop=function() connection:Disconnect();gui.Enabled=false end
print("BOMB_SPRITE_INSPECTOR_READY",gui.ScreenInsets.Name)
