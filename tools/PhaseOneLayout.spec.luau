local Layout = require("../game/Shared/ArenaLayout")
local Phase = require("../game/Shared/PhaseOne")
local checks = 0
for _, size in ipairs({ { 320, 426 }, { 375, 600 }, { 768, 950 }, { 1280, 680 }, { 801, 392 }, { 1920, 980 } }) do
	local layout = Layout.compute(size[1], size[2], 58, Phase.width, Phase.height)
	local board = layout.board
	assert(math.abs(board[3] / 15 - board[4] / 13) < 1e-8, "Cells remain square")
	assert(
		board[1] >= 0 and board[2] >= 58 and board[1] + board[3] <= size[1] and board[2] + board[4] <= size[2],
		"Whole arena fits safe area"
	)
	for _, button in pairs(layout.buttons) do
		assert(
			button[1] >= 0 and button[2] >= 58 and button[1] + button[3] <= size[1] and button[2] + button[4] <= size[2],
			"Controls remain inside safe area"
		)
	end
	checks += 7
end
print("PhaseOneLayout: " .. checks .. " geometry checks passed; no device runtime claim")
