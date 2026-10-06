local Layout = require("../game/Shared/ArenaLayout")
local sizes = {
	{ 320, 426 },
	{ 375, 600 },
	{ 768, 950 },
	{ 1280, 680 },
	{ 568, 280 },
	{ 812, 330 },
	{ 667, 280 },
	{ 1920, 980 },
	{ 2560, 1080 },
	{ 1052, 430 },
	{ 640, 360 },
	{ 560, 400 },
	{ 561, 400 },
	{ 400, 561 },
}
local function overlap(a, b)
	return a[1] < b[1] + b[3] - 1e-6
		and b[1] < a[1] + a[3] - 1e-6
		and a[2] < b[2] + b[4] - 1e-6
		and b[2] < a[2] + a[4] - 1e-6
end
for _, size in ipairs(sizes) do
	for _, inset in ipairs({ 36, 58, 64 }) do
		local g = Layout.compute(size[1], size[2], inset)
		assert(g.header[2] >= inset and g.hint[2] >= inset, "HUD clears the Roblox top bar")
		assert(g.board[2] >= inset and g.board[2] + g.board[4] <= size[2], "safe layout keeps arena visible")
		assert(math.abs(g.board[3] / 13 - g.board[4] / 9) < 1e-9, "safe layout preserves square cells")
		for _, b in pairs(g.buttons) do
			assert(b[2] >= inset and b[2] + b[4] <= size[2], "safe controls fit")
		end
	end
end
for _, size in ipairs(sizes) do
	local w, h = unpack(size)
	local g = Layout.compute(w, h)
	local board = g.board
	assert(board[3] > 200 and board[4] > 140, "arena too small")
	assert(math.abs(board[3] / 13 - board[4] / 9) < 1e-9, "cells not square")
	assert(board[1] >= 0 and board[2] >= 0 and board[1] + board[3] <= w and board[2] + board[4] <= h)
	assert(not overlap(board, g.hint), "hint overlaps arena")
	assert(not overlap(board, g.header), "header overlaps arena")
	local footer = { 8, h - 24, w - 16, 22 }
	assert(not overlap(board, footer), "footer overlaps arena")
	for name, b in pairs(g.buttons) do
		assert(b[3] >= 44 and b[4] >= 44, "touch target too small")
		assert(b[1] >= 0 and b[2] >= 0 and b[1] + b[3] <= w and b[2] + b[4] <= h, name .. " outside screen")
		assert(
			not overlap(b, board) and not overlap(b, g.hint) and not overlap(b, g.header) and not overlap(b, footer),
			name .. " overlaps content"
		)
		for other, c in pairs(g.buttons) do
			if other ~= name then
				assert(not overlap(b, c), "controls overlap")
			end
		end
	end
	if g.headerParts then
		for name, part in pairs(g.headerParts) do
			local box = { part[1] + g.header[1], part[2] + g.header[2], part[3], part[4] }
			assert(not overlap(box, board) and not overlap(box, g.hint), name .. " overlaps content")
		end
	end
	local old = g.wide and math.min(w - 264, (h - 80) * 13 / 9) or math.min(w - 24, (h - 240) * 13 / 9)
	assert(board[3] >= old, "arena shrank")
	print(
		string.format(
			"Arena %dx%d: %.1f -> %.1f px (%+.1f%%), cells %.1f px",
			w,
			h,
			old,
			board[3],
			(board[3] / old - 1) * 100,
			g.cell
		)
	)
end
print("Arena layout passed: 14 safe areas, square cells, whole map, separate HUD and controls.")
