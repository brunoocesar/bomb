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


tiles = []
for y in range(1, 10):
    for x in range(1, 14):
        tiles.append(frame(f"Cell_{x}_{y}", udim(1/13, 1/9), udim((x-1)/13, (y-1)/9),
            "35534B" if (x+y) % 2 == 0 else "3B5B51", 2, [
                image("Object", udim(1, 1), udim(0, 0), 7, Visible=False),
                image("Item", udim(.75, .75), udim(.125, .125), 12, Visible=False),
                image("Blast", udim(1, 1), udim(0, 0), 20, Visible=False),
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
board = frame("Board", udim(1, 1), udim(.5, .5), "263F37", 1,
    [image("Ground", udim(1, 1), udim(0, 0), 1, ScaleType="Stretch")] + tiles + [
        frame("Exit", udim(1/13, 1/9), udim(0, 0), z=9, BackgroundTransparency=1,
            children=[image("Gate", udim(1.1, 1.45), udim(-.05, -.45), 10),
                image("Sparkle", udim(.36, .36), udim(.32, -.3), 11, Visible=False),
                label("Remaining", "2", udim(0, 0, 18, 18), udim(.5, .77), 11,
                    AnchorPoint=[.5, .5], BackgroundTransparency=.1, BackgroundColor3=color("17263A"))])
    ] + [frog, hero] + enemies + [
        node("Aspect", "UIAspectRatioConstraint", {"AspectRatio": 13/9,
            "AspectType": "FitWithinMaxSize", "DominantAxis": "Width"}),
        node("Outline", "UIStroke", {"Color": color("819F77"), "Thickness": 3})],
    AnchorPoint=[.5, .5], ClipsDescendants=False)

controls = frame("Controls", udim(1, 0, 0, 125), udim(0, 1, 0, -150), z=45,
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
    frame("Header", udim(1, 0, 0, 60), udim(0, 0), "1E3243", 40, [
        label("Stage", "FIRST SPARK", udim(.31, 1, -6, -8), udim(0, 0, 6, 4), 41),
        label("Energy", "ENERGY 0/2", udim(.3, 1, 0, -8), udim(.31, 0, 0, 4), 41,
            TextColor3=color("85F2D7")),
        label("Stats", "BOMBS 1", udim(.21, 1, 0, -8), udim(.61, 0, 0, 4), 41),
        button("Pause", "II", udim(.15, .8), udim(.84, .1), "DBEAC2", 42),
    ]),
    label("Hint", "Move with WASD or the arrows.", udim(1, 0, -24, 30), udim(0, 0, 12, 66), 42),
    frame("PlayArea", udim(1, 1, -24, -260), udim(0, 0, 12, 105), z=1,
        BackgroundTransparency=1, children=[board]),
    controls,
    label("Status", "Connecting...", udim(1, 0, -16, 22), udim(0, 1, 8, -24), 42),
    modal("PauseOverlay", "PAUSED", "Move: WASD / arrows • Bomb: Space\nDestroy the energy boxes to open the exit.", [
        button("Resume", "RESUME", udim(.9, .14), udim(.05, .59), "85E5CF", 72),
        button("Restart", "RESTART STAGE", udim(.9, .14), udim(.05, .77), "FFAA45", 72),
    ]),
    modal("ResultOverlay", "TUTORIAL COMPLETE!", "", [
        button("Replay", "PLAY AGAIN", udim(.9, .14), udim(.05, .59), "FFAA45", 72),
        button("Camp", "VIEW REWARDS", udim(.9, .14), udim(.05, .77), "85E5CF", 72),
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
by_name["Hint"]["Properties"]["Position"] = udim(0, 0, 12, 48)
by_name["Hint"]["Properties"]["Size"] = udim(1, 0, -24, 25)
by_name["PlayArea"]["Properties"]["Position"] = udim(0, 0, 164, 82)
by_name["PlayArea"]["Properties"]["Size"] = udim(1, 1, -276, -110)
by_name["Controls"]["Properties"]["Position"] = udim(0, .5, 0, -24)
compact_buttons = {child["Name"]: child for child in by_name["Controls"]["Children"]}
for name, x, y in (("Up", 58, 0), ("Left", 8, 50), ("Down", 58, 50), ("Right", 108, 50)):
    compact_buttons[name]["Properties"]["Size"] = udim(0, 0, 44, 44)
    compact_buttons[name]["Properties"]["Position"] = udim(0, 0, x, y)
(ROOT / "game/Assets/TutorialCompactUI.model.json").write_text(json.dumps(compact, indent=2) + "\n", encoding="utf-8")
print(f"Authored {path.name}: 117 cells, 4 enemy slots, independent hero/frog layers.")
