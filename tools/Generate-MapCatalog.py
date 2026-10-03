"""Export measured map atlas rectangles; never alters raster images or uploaded IDs."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
manifest = json.loads((ROOT / "art/maps/map-manifest.json").read_text(encoding="utf-8-sig"))
lines = ["-- Generated from art/maps/map-manifest.json; image IDs live in MapImages.lua.",
         "return {", "\timageSize = { " + ", ".join(map(str, manifest["imageSize"])) + " },", "\tframes = {"]
for name, rect in manifest["frames"].items():
    lines.append("\t\t" + name + " = { " + ", ".join(map(str, rect)) + " },")
lines += ["\t},", "}"]
(ROOT / "game/Shared/MapCatalog.lua").write_text("\n".join(lines) + "\n", encoding="utf-8")
print("Exported 20 measured map sprite rectangles.")
