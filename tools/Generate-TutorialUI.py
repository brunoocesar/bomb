"""Deliberate offline authoring of the tutorial's Roblox UI asset."""
import json
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def udim(x, y, ox=0, oy=0):
    return {"UDim2": [[x, ox], [y, oy]]}


def color(value):
    return [int(value[index:index + 2], 16) / 255 for index in (0, 2, 4)]


def node(name, class_name, properties=None, children=None):
    return {"Name": name, "ClassName": class_name,
            "Properties": properties or {}, "Children": children or []}


def round_corner(radius=8):
    return node("Corner", "UICorner", {"CornerRadius": {"UDim": [0, radius]}})


def frame(name, size, position, background="243E3A", z=1, children=None, **extra):
    return node(name, "Frame", {"Size": size, "Position": position,
        "BackgroundColor3": color(background), "BorderSizePixel": 0, "ZIndex": z,
        **extra}, children)


def label(name, text, size, position, z=5, **extra):
    return node(name, "TextLabel", {"Size": size, "Position": position,
        "BackgroundTransparency": 1, "BorderSizePixel": 0,
        "Text": text, "TextColor3": color("FFF4DD"), "Font": "GothamBold",
        "TextScaled": True, "ZIndex": z, **extra}, [
        node("TextLimits", "UITextSizeConstraint", {"MinTextSize": 10, "MaxTextSize": 20})])


def button(name, text, size, position, background="FFAA45", z=50):
    result = label(name, text, size, position, z, BackgroundTransparency=0,
        BackgroundColor3=color(background), AutoButtonColor=True,
        TextColor3=color("17263A"))
    result["ClassName"] = "TextButton"
    result["Children"].append(round_corner(12))
    return result


def image(name, size, position, z, **extra):
    return node(name, "ImageLabel", {"Size": size, "Position": position,
        "BackgroundTransparency": 1, "BorderSizePixel": 0, "Image": "",
        "ScaleType": "Fit", "ZIndex": z, **extra})


def mascot(name, frog=False):
    body_color = "35CAB4" if frog else "F89835"
    children = [round_corner(22),
        frame("Belly", udim(.68, .5), udim(.16, .43), "FFF0C5", 31, [round_corner(18)]),
        frame("LeftEye", udim(.13, .19), udim(.22, .24), "17263A", 33, [round_corner(20)]),
        frame("RightEye", udim(.13, .19), udim(.65, .24), "17263A", 33, [round_corner(20)]),
        label("Smile", "v", udim(.24, .23), udim(.38, .38), 33),
        frame("LeftFoot", udim(.3, .23), udim(.03, .82), body_color, 30, [round_corner(12)]),
        frame("RightFoot", udim(.3, .23), udim(.67, .82), body_color, 30, [round_corner(12)]),
    ]
    if not frog:
        children += [frame("Wick", udim(.09, .23), udim(.46, -.16), "CDB68D", 31, [round_corner(3)]),
            frame("Flame", udim(.24, .3), udim(.39, -.35), "FFD653", 32, [round_corner(12)])]
    return frame(name, udim(.76, .75), udim(.12, .17), body_color, 30, children)


def blast():
    # Half-cell connectors meet exactly at cell borders. Clip all flames to danger.
    return frame("Blast", udim(1, 1), udim(0, 0), z=36,
        BackgroundTransparency=1, ClipsDescendants=True, Visible=False, children=[
            image("Up", udim(.58, .51), udim(.21, 0), 36, ScaleType="Stretch", Visible=False),
            image("Right", udim(.51, .58), udim(.49, .21), 36, ScaleType="Stretch", Visible=False),
            image("Down", udim(.58, .51), udim(.21, .49), 36, ScaleType="Stretch", Visible=False),
            image("Left", udim(.51, .58), udim(0, .21), 36, ScaleType="Stretch", Visible=False),
            image("Core", udim(.9, .9), udim(.05, .05), 37, ScaleType="Stretch", Visible=False),
        ])


tiles = []
for y in range(1, 10):
    for x in range(1, 14):
        tiles.append(frame(f"Cell_{x}_{y}", udim(1/13, 1/9), udim((x-1)/13, (y-1)/9),
            "35534B" if (x+y) % 2 == 0 else "3B5B51", 2, [
                image("Object", udim(1, 1), udim(0, 0), 7, Visible=False),
                frame("ItemGlow", udim(.9, .9), udim(.05, .05), "85E5CF", 37,
                    children=[round_corner(8), node("Outline", "UIStroke", {"Color": color("85F2D7"), "Thickness": 2})],
                    BackgroundTransparency=.85, Visible=False),
                image("Item", udim(.75, .75), udim(.125, .125), 38, Visible=False),
                blast(),
                image("Bomb", udim(.7, .8), udim(.15, .08), 16, Visible=False),
            ], BackgroundTransparency=1))

hero = frame("Hero", udim(1/13, 1/9), udim(1/13, 1/9), "243E3A", 30,
    [mascot("Vector"), node("Sprite", "ImageLabel", {"Size": udim(1.35, 1.6),
        "Position": udim(-.175, -.55), "BackgroundTransparency": 1,
        "Image": "", "Visible": False, "ZIndex": 35, "ScaleType": "Stretch"})],
    BackgroundTransparency=1)
frog = frame("Frog", udim(1.15/13, .9/9), udim(1/13, 1/9), "243E3A", 24,
    [mascot("Vector", True), node("Sprite", "ImageLabel", {"Size": udim(1.25, 1.4),
        "Position": udim(-.125, -.3), "BackgroundTransparency": 1,
        "Image": "", "Visible": False, "ZIndex": 28})],
    BackgroundTransparency=1, Visible=False)
for descendant in frog["Children"][0]["Children"]:
    if "ZIndex" in descendant["Properties"]:
        descendant["Properties"]["ZIndex"] -= 8
frog["Children"][0]["Properties"]["ZIndex"] = 22
enemies = [image(f"Enemy_{index}", udim(.8/13, .8/9), udim(0, 0), 25, Visible=False)
    for index in range(1, 5)]
shadows = [frame(name, udim(.6/13, .18/9), udim(0, 0), "172D2A", 3,
    children=[node("Corner", "UICorner", {"CornerRadius": {"UDim": [.5, 0]}})],
    AnchorPoint=[.5, .5], BackgroundTransparency=.65, Visible=False)
    for name in ["PlayerShadow", *[f"EnemyShadow_{index}" for index in range(1, 5)]]]
destruction = frame("Effects", udim(1, 1), udim(0, 0), z=37,
    BackgroundTransparency=1, ClipsDescendants=True, children=[
        frame(f"Destroy_{index:02}", udim(1/13, 1/9), udim(0, 0), z=37,
            BackgroundTransparency=1, Visible=False, children=[
                image("Impact", udim(1, 1), udim(0, 0), 37, Visible=False),
                *[image(f"Piece_{piece}", udim(.44, .44), udim(.5, .5), 37,
                        AnchorPoint=[.5, .5], ScaleType="Stretch", Visible=False)
                    for piece in range(1, 5)],
            ]) for index in range(1, 17)
    ])
pointer = frame("Pointer", udim(.7, .7), udim(.5, -.25), "17263A", 38,
    AnchorPoint=[.5, .5], BackgroundTransparency=.15, Visible=False, children=[
        round_corner(8), node("Limits", "UISizeConstraint", {"MinSize": [28,28], "MaxSize": [44,44]}),
        node("Outline", "UIStroke", {"Color": color("85F2D7"), "Thickness": 2}),
        frame("Stem", udim(.16, .58), udim(.42, .02), "85F2D7", 38, [round_corner(3)]),
        frame("LeftTip", udim(.16, .48), udim(.28, .38), "85F2D7", 38, [round_corner(3)], Rotation=-45),
        frame("RightTip", udim(.16, .48), udim(.56, .38), "85F2D7", 38, [round_corner(3)], Rotation=45),
    ])
board = frame("Board", udim(1, 1), udim(.5, .5), "263F37", 1,
    [image("Ground", udim(1, 1), udim(0, 0), 1, ScaleType="Stretch")] + tiles + [
        frame("Exit", udim(1/13, 1/9), udim(0, 0), z=9, BackgroundTransparency=1,
            children=[frame("Glow", udim(.96, .96), udim(.02, .02), "35CAB4", 34,
                    [round_corner(10), node("Outline", "UIStroke", {"Color": color("85F2D7"), "Thickness": 3})],
                    BackgroundTransparency=.8, Visible=False),
                image("Gate", udim(1.3, 1.5), udim(-.15, -.5), 35), pointer,
                image("Sparkle", udim(.36, .36), udim(.32, -.3), 11, Visible=False),
                label("OpenLabel", "EXIT", udim(0, 0, 44, 16), udim(.5, .98), 38,
                    AnchorPoint=[.5, 1], Visible=False, BackgroundTransparency=.15, BackgroundColor3=color("17263A")),
                label("Remaining", "2", udim(0, 0, 18, 18), udim(.5, .77), 11,
                    AnchorPoint=[.5, .5], BackgroundTransparency=.1, BackgroundColor3=color("17263A"))])
    ] + shadows + [frog, hero] + enemies + [destruction,
        node("Aspect", "UIAspectRatioConstraint", {"AspectRatio": 13/9,
            "AspectType": "FitWithinMaxSize", "DominantAxis": "Width"}),
        node("Outline", "UIStroke", {"Color": color("819F77"), "Thickness": 3})],
    AnchorPoint=[.5, .5], ClipsDescendants=False)

controls = frame("Controls", udim(1, 0, 0, 110), udim(0, 1, 0, -140), z=45,
    BackgroundTransparency=1, children=[
        button("Up", "^", udim(0, 0, 52, 52), udim(0, 0, 70, 0), "DBEAC2"),
        button("Left", "<", udim(0, 0, 52, 52), udim(0, 0, 12, 58), "DBEAC2"),
        button("Down", "v", udim(0, 0, 52, 52), udim(0, 0, 70, 58), "DBEAC2"),
        button("Right", ">", udim(0, 0, 52, 52), udim(0, 0, 128, 58), "DBEAC2"),
        button("Bomb", "BOMB", udim(0, 0, 90, 90), udim(1, 0, -104, 12)),
    ])

def modal(name, title, detail, buttons):
    panel = frame("Panel", udim(.9, .75), udim(.5, .5), "24364D", 70,
        [round_corner(18),
         node("Limits", "UISizeConstraint", {"MaxSize": [500, 380]}),
         label("Title", title, udim(.9, .16), udim(.05, .04), 71),
         label("Detail", detail, udim(.9, .36), udim(.05, .2), 71, TextWrapped=True)] + buttons,
        AnchorPoint=[.5, .5])
    return frame(name, udim(1, 1), udim(0, 0), "101928", 65, [panel],
        Visible=False, BackgroundTransparency=.15, Active=True)

root = node("TutorialUI", "ScreenGui", {"ResetOnSpawn": False, "DisplayOrder": 20,
    "ZIndexBehavior": "Global", "ScreenInsets": "CoreUISafeInsets"}, [
    frame("Background", udim(1, 1), udim(0, 0), "152B2A", 0),
    frame("Header", udim(1, 0, 0, 52), udim(0, 0), "1E3243", 40, [
        label("Stage", "FIRST SPARK", udim(.29, 1, -8, -8), udim(0, 0, 4, 4), 41),
        label("Energy", "ENERGY\n0/2", udim(.22, 1, 0, -8), udim(.29, 0, 0, 4), 41,
            TextColor3=color("85F2D7")),
        label("Stats", "BOMBS READY: 1/1\nRANGE: 2 tiles", udim(.35, 1, 0, -8), udim(.51, 0, 0, 4), 41),
        button("Pause", "II", udim(.14, .8), udim(.86, .1), "DBEAC2", 42),
    ]),
    label("Hint", "Move with WASD or the arrows.", udim(1, 0, -24, 26), udim(0, 0, 12, 58), 42),
    frame("PlayArea", udim(1, 1, -24, -240), udim(0, 0, 12, 92), z=1,
        BackgroundTransparency=1, children=[board]),
    controls,
    frame("Status", udim(1, 0, -16, 22), udim(0, 1, 8, -24), z=42,
        BackgroundTransparency=1, children=[
            image("FrogIcon", udim(0, 0, 22, 22), udim(0, 0), 42),
            label("Mount", "FROG: NONE", udim(.65, 1, -24, 0), udim(0, 0, 24, 0), 42, TextXAlignment="Left"),
            label("Coins", "COINS 0", udim(.32, 1), udim(.68, 0), 42, TextXAlignment="Right"),
        ]),
    modal("PauseOverlay", "PAUSED", "Move: WASD / arrows • Bomb: Space\nBombs ready: available / capacity.\nRange: tiles from the bomb.\nThe frog protects you from one hit.", [
        label("Save", "", udim(.9, .05), udim(.05, .54), 71),
        button("Resume", "RESUME", udim(.9, .11), udim(.05, .59), "85E5CF", 72),
        button("Restart", "RESTART STAGE", udim(.44, .11), udim(.05, .73), "FFAA45", 72),
        button("Settings", "SETTINGS", udim(.44, .11), udim(.51, .73), "85E5CF", 72),
        button("Camp", "RETURN TO CAMP", udim(.9, .11), udim(.05, .87), "85E5CF", 72),
    ]),
    modal("ResultOverlay", "TUTORIAL COMPLETE!", "", [
        button("Replay", "PLAY AGAIN", udim(.9, .14), udim(.05, .59), "FFAA45", 72),
        button("Camp", "CAMP", udim(.9, .14), udim(.05, .77), "85E5CF", 72),
    ]),
    modal("ErrorOverlay", "PROGRESS UNAVAILABLE", "Please rejoin. Your saved progress has not been replaced.", []),
    label("Death", "Try again!", udim(.8, .2), udim(.1, .4), 63, Visible=False,
        BackgroundTransparency=.15, BackgroundColor3=color("3C2539")),
])

path = ROOT / "game/Assets/TutorialUI.model.json"
root.pop("Name")
path.write_text(json.dumps(root, indent=2) + "\n", encoding="utf-8")
compact = deepcopy(root)
by_name = {child["Name"]: child for child in compact["Children"]}
by_name["Header"]["Properties"]["Size"] = udim(1, 0, 0, 44)
by_name["Hint"]["Properties"]["Position"] = udim(0, 0, 8, 52)
by_name["Hint"]["Properties"]["Size"] = udim(0, 0, 140, 48)
by_name["Hint"]["Properties"]["TextWrapped"] = True
by_name["PlayArea"]["Properties"]["Position"] = udim(0, 0, 156, 52)
by_name["PlayArea"]["Properties"]["Size"] = udim(1, 1, -264, -80)
by_name["Controls"]["Properties"]["Position"] = udim(0, .5, 0, -24)
compact_buttons = {child["Name"]: child for child in by_name["Controls"]["Children"]}
for name, x, y in (("Up", 58, 0), ("Left", 8, 50), ("Down", 58, 50), ("Right", 108, 50)):
    compact_buttons[name]["Properties"]["Size"] = udim(0, 0, 44, 44)
    compact_buttons[name]["Properties"]["Position"] = udim(0, 0, x, y)
(ROOT / "game/Assets/TutorialCompactUI.model.json").write_text(json.dumps(compact, indent=2) + "\n", encoding="utf-8")
print(f"Authored {path.name}: 117 cells, 4 enemy slots, independent hero/frog layers.")
