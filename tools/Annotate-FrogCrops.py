"""Build crop annotations from measured connected silhouettes; never edits image pixels."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
parts = json.loads((ROOT / "build/frog-components.json").read_text(encoding="utf-8-sig"))
parts = [p["value"] for p in parts]
frames = {}
for row in range(8):
    for column in range(8):
        if row == 6:
            continue  # Smoke legitimately contains disconnected bubbles.
        candidates = [p for p in parts if int((p[0] + p[2]/2)/156.75) == column
                      and int((p[1] + p[3]/2)/156.75) == row]
        assert candidates, (row, column)
        x, y, w, h, area = max(candidates, key=lambda p: p[4])
        frames[f"frog_r{row}_c{column}"] = {"rect": [x-2, y-2, w+4, h+4]}
        if row in (5, 7):
            # Fixed ground plane across the authored jump, rather than its moving feet.
            frames[f"frog_r{row}_c{column}"]["groundY"] = 916 if row == 5 else 1216
for column in range(8):
    top = round(6/8*1254)
    bottom = min(round(7/8*1254), frames[f"frog_r7_c{column}"]["rect"][1]-2)
    left, right = round(column/8*1254), round((column+1)/8*1254)
    frames[f"frog_r6_c{column}"] = {"rect": [left, top, right-left, bottom-top]}
target = ROOT / "art/sprites/frog/frame-crops.json"
target.write_text(json.dumps({"source": "base/frog-clean-v1.png", "alphaThreshold": 64,
    "paddingPixels": 2, "frames": frames}, indent=2)+"\n", encoding="utf-8")
print("Annotated 64 frog rectangles without changing source artwork.")
