"""Static asset/layout checks. These do not replace Roblox Studio Play tests."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def children(node):
    return {child["Name"]: child for child in node.get("Children", [])}


def rect(node, parent):
    p = node["Properties"]
    size, position = p["Size"]["UDim2"], p["Position"]["UDim2"]
    width = parent[2] * size[0][0] + size[0][1]
    height = parent[3] * size[1][0] + size[1][1]
    return (parent[0] + parent[2] * position[0][0] + position[0][1],
            parent[1] + parent[3] * position[1][0] + position[1][1], width, height)


def overlap(a, b):
    return a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]


normal = json.loads((ROOT / "game/Assets/TutorialUI.model.json").read_text())
compact = json.loads((ROOT / "game/Assets/TutorialCompactUI.model.json").read_text())
for asset in (normal, compact):
    assert asset["ClassName"] == "ScreenGui"
    assert asset["Properties"]["ScreenInsets"] == "CoreUISafeInsets"
    top = children(asset)
    board = children(top["PlayArea"])["Board"]
    cells = children(board)
    assert cells["Ground"]["ClassName"] == "ImageLabel"
    gate = children(cells["Exit"])
    assert gate["Gate"]["ClassName"] == "ImageLabel"
    assert gate["Sparkle"]["ClassName"] == "ImageLabel"
    assert sum(name.startswith("Cell_") for name in cells) == 117
    assert all(name in cells for name in ("Hero", "Frog", "Enemy_1", "Enemy_2", "Enemy_3", "Enemy_4"))
    assert children(cells["Frog"])["Vector"]["Properties"]["ZIndex"] < children(children(cells["Frog"])["Vector"])["Belly"]["Properties"]["ZIndex"]
    for y in range(1, 10):
        for x in range(1, 14):
            assert set(children(cells[f"Cell_{x}_{y}"])) == {"Object", "Item", "Blast", "Bomb"}
            assert cells[f"Cell_{x}_{y}"]["Properties"]["BackgroundTransparency"] == 1
            assert all(view["ClassName"] == "ImageLabel" for view in children(cells[f"Cell_{x}_{y}"]).values())
    assert all(cells[f"Enemy_{index}"]["ClassName"] == "ImageLabel" for index in range(1, 5))
    for name in ("PauseOverlay", "ResultOverlay", "ErrorOverlay"):
        assert not top[name]["Properties"]["Visible"]
        assert top[name]["Properties"]["ZIndex"] > cells["Hero"]["Properties"]["ZIndex"]

viewports = [(320, 426), (375, 600), (768, 950), (1280, 680), (568, 280), (812, 330), (667, 280)]
for width, height in viewports:
    asset = compact if width > height * 1.4 and height < 550 else normal
    top = children(asset)
    parent = (0, 0, width, height)
    area = rect(top["PlayArea"], parent)
    board_width = min(area[2], area[3] * 13 / 9)
    board_height = board_width * 9 / 13
    board_rect = (area[0] + (area[2] - board_width) / 2,
                  area[1] + (area[3] - board_height) / 2, board_width, board_height)
    assert board_width > 200 and board_height > 140, (width, height, board_rect)
    control_parent = rect(top["Controls"], parent)
    buttons = [rect(button, control_parent) for button in children(top["Controls"]).values()]
    for button in buttons:
        assert button[2] >= 44 and button[3] >= 44
        assert 0 <= button[0] < button[0] + button[2] <= width
        assert 0 <= button[1] < button[1] + button[3] <= height
        assert not overlap(button, board_rect), (width, height, "button covers board")
    for index, button in enumerate(buttons):
        assert all(not overlap(button, other) for other in buttons[index + 1:])

client = (ROOT / "game/Client/Tutorial.client.lua").read_text()
assert 'Instance.new' not in client, "UI must come from authored assets"
assert 'WindowFocusReleased' in client and 'InputEnded' in client
print(f"Tutorial UI contract passed: 2 authored layouts, {len(viewports)} safe-area viewports, 117 cells each.")
