"""Author the camp UI offline. Client fills real profile data; no runtime UI creation."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
def u(x=0,y=0,ox=0,oy=0): return {"UDim2":[[x,ox],[y,oy]]}
def c(s): return [int(s[i:i+2],16)/255 for i in (0,2,4)]
def n(name,cls,p=None,ch=None): return {"Name":name,"ClassName":cls,"Properties":p or {},"Children":ch or []}
def corner(r=14): return n("Corner","UICorner",{"CornerRadius":{"UDim":[0,r]}})
def f(name,ch=None,z=10,**p):
    return n(name,"Frame",{"Size":u(1,1),"Position":u(),"BorderSizePixel":0,"BackgroundColor3":c("20384A"),"BackgroundTransparency":.08,"ZIndex":z,**p},ch)
def text(name,value="",z=12,**p):
    return n(name,"TextLabel",{"Size":u(1,0,0,32),"Position":u(),"BackgroundTransparency":1,"BorderSizePixel":0,"Text":value,"Font":"GothamBold","TextColor3":c("FFF2D6"),"TextSize":16,"TextWrapped":True,"ZIndex":z,**p})
def icon(name,z=13,**p): return n(name,"ImageLabel",{"Size":u(0,0,40,40),"Position":u(),"BackgroundTransparency":1,"Image":"","ScaleType":"Fit","ZIndex":z,**p})
def b(name,value="",z=14,**p):
    props={"BackgroundTransparency":0,"BackgroundColor3":c("FFAE48"),"TextColor3":c("172A3B"),"AutoButtonColor":True,**p}
    out=text(name,value,z,**props)
    out["ClassName"]="TextButton";out["Children"]=[corner(12)];return out
def rect(x,y,w,h): return {"Position":u(0,0,x,y),"Size":u(0,0,w,h)}
def section(name,title,body,action=None):
    children=[corner(),text("Title",title,TextSize=21),text("Body",body,Position=u(0,0,0,34),Size=u(1,0,0,64),TextColor3=c("CADBCF"),TextSize=14)]
    if action: children.append(b("Action",action,Position=u(0,0,0,104),Size=u(1,0,0,44)))
    return f(name,children,BackgroundTransparency=1)

navigation=[]
for idx,(name,value) in enumerate([( "Adventure","ADVENTURE"),("Character","CHARACTER"),("Frogs","FROGS"),("Shop","SHOP")]):
    item=b(name,"",BackgroundColor3=c("20384A"),**rect(0,idx*64,160,56))
    item["Children"] += [icon("Icon",**rect(10,8,40,40)),text("Caption",value,Position=u(0,0,56,0),Size=u(1,1,-62,0),TextSize=14,TextXAlignment="Left")]
    navigation.append(item)

panels=[]
# Scroll content remains to the side/below the hero, never covers the central showcase.
adventure=section("Adventure","ADVENTURE","First trail • First Spark")
adventure["Children"] += [icon("Map",Size=u(1,0,0,122),Position=u(0,0,0,84),ScaleType="Crop")]
for i in range(4):
    adventure["Children"].append(b(f"Trail_{i+1}",str(i+1) if i==0 else "?",**rect(8+i*56,116,44,44),BackgroundColor3=c("85DFC4" if i==0 else "33475B")))
adventure["Children"] += [text("Medals","",Position=u(0,0,0,214),Size=u(1,0,0,64),TextSize=14),b("Play","CONTINUE",Position=u(0,0,0,286),Size=u(1,0,0,46)),text("TrailHint","",Position=u(0,0,0,338),Size=u(1,0,0,54),TextSize=14)]
panels.append(adventure)
character=section("Character","YOUR PACK","One look for you and your companion.")
character["Children"] += [f("PackArt",[icon("Hero",Position=u(0,0),Size=u(.33,1)),icon("Frog",Position=u(.33,0),Size=u(.33,1)),icon("Mounted",Position=u(.66,0),Size=u(.34,1))],Position=u(0,0,0,90),Size=u(1,0,0,112),BackgroundTransparency=1),text("PackName","ORIGINAL PACK",Position=u(0,0,0,212),Size=u(1,0,0,28),TextColor3=c("85DFC4")),text("Includes","Orange hero • Teal companion\nA complete matching set.",Position=u(0,0,0,248),Size=u(1,0,0,52),TextSize=14),b("Preview","PREVIEW",Position=u(0,0,0,310),Size=u(1,0,0,44)),b("Equip","EQUIPPED",Position=u(0,0,0,362),Size=u(1,0,0,44),BackgroundColor3=c("85DFC4"))]
panels.append(character)
frogs=section("Frogs","FROG COLLECTION","Your companion, your matching pack.")
frogs["Children"] += [icon("Portrait",Position=u(.5,0,0,94),Size=u(0,0,126,108),AnchorPoint=[.5,0]),text("Name","TEAL COMPANION",Position=u(0,0,0,210),TextColor3=c("85DFC4")),text("Origin","",Position=u(0,0,0,246),Size=u(1,0,0,72),TextSize=14),b("Preview","PREVIEW",Position=u(0,0,0,330),Size=u(1,0,0,44)),b("Equip","EQUIP PACK",Position=u(0,0,0,382),Size=u(1,0,0,44),BackgroundColor3=c("85DFC4"))]
panels.append(frogs)
shop=section("Shop","CAMP STORE","Looks to enjoy. The same adventure rules.")
shop["Children"] += [icon("Pack",Position=u(0,0,0,84),Size=u(1,0,0,112)),text("Offer","ORIGINAL PACK • INCLUDED",Position=u(0,0,0,204),Size=u(1,0,0,48)),b("Preview","PREVIEW COMPLETE PACK",Position=u(0,0,0,262),Size=u(1,0,0,44)),f("Supply",[icon("Icon",**rect(4,4,44,44)),text("Title","DAILY SUPPLIES",Position=u(0,0,56,0),Size=u(1,0,-56,28)),text("Detail","3 coins • one claim per day",Position=u(0,0,56,30),Size=u(1,0,-56,46),TextSize=14),b("Claim","CLAIM",Position=u(0,0,4,88),Size=u(1,0,-8,44))],Position=u(0,0,0,322),Size=u(1,0,0,144),BackgroundTransparency=.35)]
panels.append(shop)
missions=section("Missions","DAILY MISSIONS","Play at your pace. Claim earned rewards.")
for i,(name,title,body) in enumerate([("Energy","ENERGY HUNT","Break 3 energy crates • 5 coins"),("Clear","CLEAN RUN","Complete First Spark without dying • 10 coins"),("Supply","CAMP SUPPLIES","7 visits, any days • Campfire badge")]):
    missions["Children"].append(f(name,[text("Title",title,TextXAlignment="Left",TextColor3=c("85DFC4")),text("Progress",body,Position=u(0,0,0,34),Size=u(1,0,0,56),TextSize=14,TextXAlignment="Left"),b("Claim","CLAIM",Position=u(0,0,0,98),Size=u(1,0,0,44))],Position=u(0,0,0,86+i*164),Size=u(1,0,0,150),BackgroundTransparency=1))
panels.append(missions)
profile=section("Profile","YOUR JOURNEY","")
profile["Children"] += [text("Name","",Position=u(0,0,0,38),Size=u(1,0,0,48),TextColor3=c("85DFC4")),text("Stats","",Position=u(0,0,0,98),Size=u(1,0,0,142),TextSize=15),icon("Badge",Position=u(.5,0,0,250),Size=u(0,0,80,80),AnchorPoint=[.5,0]),text("BadgeHint","Campfire badge • Claim supplies on 7 days.",Position=u(0,0,0,340),Size=u(1,0,0,60),TextSize=14),b("EquipBadge","LOCKED",Position=u(0,0,0,410),Size=u(1,0,0,44))]
panels.append(profile)
settings=section("Settings","SETTINGS","Changes apply immediately and are saved.")
for idx,(name,caption) in enumerate([("Music","MUSIC"),("Sfx","SOUND EFFECTS"),("Vibration","VIBRATION"),("Effects","REDUCED EFFECTS"),("Handed","CONTROLS SIDE"),("Opacity","CONTROLS OPACITY"),("Text","LARGE TEXT"),("Language","LANGUAGE")]):
    settings["Children"].append(b(name,caption,Position=u(0,0,0,86+idx*54),Size=u(1,0,0,46),BackgroundColor3=c("334D5B")))
settings["Children"].append(text("Controls","Move: WASD / arrows / left stick\nBomb: Space / A / BOMB\nBack: Escape / B",Position=u(0,0,0,526),Size=u(1,0,0,82),TextSize=14))
panels.append(settings)
for panel in panels:
    panel["Properties"].update(Visible=False,Size=u(1,0,-24,620),Position=u(0,0,12,0))

root=n("LobbyUI","ScreenGui",{"ResetOnSpawn":False,"Enabled":False,"DisplayOrder":25,"ZIndexBehavior":"Global","ScreenInsets":"CoreUISafeInsets"},[
    icon("Background",0,Size=u(1,1),ScaleType="Crop"),
    f("Shade",z=1,BackgroundColor3=c("102B31"),BackgroundTransparency=.78),
    f("Header",[text("Title","BOMB YOUR WAY!",TextXAlignment="Left",TextSize=24),b("Coins","0",BackgroundColor3=c("20384A"),TextColor3=c("FFF2D6")),b("Profile","",BackgroundColor3=c("20384A")),b("Settings","",BackgroundColor3=c("20384A"))],BackgroundTransparency=1),
    f("Navigation",navigation,BackgroundTransparency=1),
    f("Stage",[f("Shadow",[corner(100)],z=4,Size=u(.48,.05),Position=u(.5,.83),AnchorPoint=[.5,.5],BackgroundColor3=c("243D31"),BackgroundTransparency=.65),icon("Hero",5),icon("Frog",5),b("Inspect","",6,Size=u(1,.76),BackgroundTransparency=1),b("RotateLeft","<",**rect(4,0,44,44)),b("RotateRight",">",**rect(52,0,44,44)),text("PackName","ORIGINAL PACK",Position=u(0,.88),Size=u(1,0,0,26),TextColor3=c("172A3B")),text("InspectHint","Tap to turn • Preview your pack",Position=u(0,.96),Size=u(1,0,0,24),TextSize=13,TextColor3=c("172A3B"))],BackgroundTransparency=1),
    f("Next",[corner(18),icon("Art",Size=u(1,0,0,82),ScaleType="Crop"),text("Eyebrow","YOUR NEXT ADVENTURE",Position=u(0,0,12,94),Size=u(1,0,-24,24),TextSize=13,TextColor3=c("85DFC4")),text("Title","FIRST SPARK",Position=u(0,0,12,120),Size=u(1,0,-24,30),TextSize=23),text("Detail","",Position=u(0,0,12,155),Size=u(1,0,-24,68),TextSize=15),b("Continue","CONTINUE",Position=u(0,1,12,-58),Size=u(1,0,-24,46))]),
    f("Panel",[corner(18),b("Back","BACK",**rect(12,8,100,38),BackgroundColor3=c("334D5B")),n("Content","ScrollingFrame",{"Size":u(1,1,0,-60),"Position":u(0,0,0,56),"CanvasSize":u(0,0,0,620),"ScrollBarThickness":4,"ScrollingDirection":"Y","BackgroundTransparency":1,"BorderSizePixel":0,"ZIndex":11},panels)],Visible=False),
    f("Footer",[b("Daily","",BackgroundColor3=c("20384A")),b("Reward","",BackgroundColor3=c("20384A"))],BackgroundTransparency=1),
    f("RewardToast",[corner(),text("Title","COMPANION RESCUED",TextColor3=c("85DFC4")),text("Detail","Your matching Original Pack is ready.",Position=u(0,0,8,32),Size=u(1,0,-16,44),TextSize=14),b("Equip","EQUIP PACK",Position=u(0,0,8,84),Size=u(.7,0,-16,40)),b("Close","OK",Position=u(.7,0),Size=u(.3,0,-8,40))],z=30,Visible=False,Size=u(0,0,300,132),Position=u(.5,0,0,62),AnchorPoint=[.5,0]),
])
# Supply/navigation widgets use authored images and text children, no glyph substitutes.
by={item["Name"]:item for item in root["Children"]}
ambient=f("Ambient",z=2,BackgroundTransparency=1)
for index in range(6):
    leaf=f(f"Leaf_{index+1}",[corner(6)],z=3,Size=u(0,0,5,10),Position=u(.08+index*.16,.2+(index%3)*.12),BackgroundColor3=c("B9C891"),BackgroundTransparency=.45,Rotation=35,Visible=True)
    ambient["Children"].append(leaf)
root["Children"].insert(2,ambient)
next(item for item in by["RewardToast"]["Children"] if item["Name"]=="Close")["Properties"]["Position"]=u(.7,0,0,84)
for idx,name in enumerate(("Daily","Reward")):
    btn=next(item for item in by["Footer"]["Children"] if item["Name"]==name)
    btn["Properties"].update(Size=u(.5,1,-5,0),Position=u(idx*.5,0,idx*5,0))
    btn["Children"] += [icon("Icon",Position=u(0,.5,8,0),AnchorPoint=[0,.5]),text("Caption","",Position=u(0,0,56,4),Size=u(1,1,-64,-8),TextXAlignment="Left",TextSize=14)]
for name in ("Profile","Settings"):
    btn=next(item for item in by["Header"]["Children"] if item["Name"]==name)
    btn["Children"].append(icon("Icon",Position=u(.5,.5),Size=u(0,0,30,30),AnchorPoint=[.5,.5]))
coin=next(item for item in by["Header"]["Children"] if item["Name"]=="Coins")
coin["Children"].append(icon("Icon",**rect(6,6,30,30)))
coin["Properties"].update(TextXAlignment="Right",TextSize=18)
root.pop("Name")
def layers(item,parent=-1):
    if "ZIndex" in item.get("Properties",{}):
        item["Properties"]["ZIndex"]=max(parent+1,item["Properties"]["ZIndex"])
        parent=item["Properties"]["ZIndex"]
    for child in item.get("Children",[]): layers(child,parent)
layers(root)
(ROOT/"game/Assets/LobbyUI.model.json").write_text(json.dumps(root,indent=2)+"\n",encoding="utf-8")
print("Authored lobby: camp, hero showcase, four navigation buttons, seven panels, daily rewards and settings.")
