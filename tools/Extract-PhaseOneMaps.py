"""Extract the authored map symbols from pages 5–6, preserving PDF positions."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "build/tools/pdf-reader"))
from pypdf import PdfReader

reader = PdfReader(ROOT / "Mundos_Fases_Etapas_Bomb_Your_Way (1).pdf")
maps = []
for page_number in (5, 6):
    grid = [["." for _ in range(13)] for _ in range(11)]
    symbols = []

    def visit(text, cm, tm, font, size):
        symbol = text.strip()
        if len(symbol) != 1 or symbol not in "B#RDNSUPXO":
            return
        # Map is one translated PDF group; local glyph baseline spacing is fixed.
        x = round((tm[4] - 20) / 14.74016)
        y = round((166.5638 - tm[5]) / 14.74016)
        if not (0 <= x < 13 and 0 <= y < 11):
            raise ValueError((page_number, symbol, tm))
        if grid[y][x] != ".":
            raise ValueError("Two symbols occupy the same cell")
        grid[y][x] = symbol
        symbols.append({"symbol": symbol, "x": x + 1, "y": y + 1})

    reader.pages[page_number - 1].extract_text(visitor_text=visit)
    rows = ["".join(row) for row in grid]
    assert rows[10][1] == "P"
    assert rows[1][2] == rows[1][10] == "R"
    assert sum(row.count("B") for row in rows) == (54 if page_number == 5 else 59)
    assert sum(row.count("#") for row in rows) == (27 if page_number == 5 else 25)
    maps.append({"page": page_number, "internalRows": rows, "symbols": symbols})
    print(f"PDF page {page_number}")
    print("\n".join(rows))

destination = ROOT / "build/phase1-pdf-maps.json"
destination.write_text(json.dumps(maps, indent=2), encoding="utf-8")
