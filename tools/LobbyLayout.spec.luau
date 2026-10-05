local Layout = require("../game/Shared/LobbyLayout")
local checks = 0
local function expect(ok, message)
	checks += 1
	assert(ok, message)
end
local function overlap(a, b)
	return a[1] < b[1] + b[3] and b[1] < a[1] + a[3] and a[2] < b[2] + b[4] and b[2] < a[2] + a[4]
end
for _, size in ipairs({
	{ 320, 426 },
	{ 360, 640 },
	{ 390, 754 },
	{ 412, 800 },
	{ 600, 900 },
	{ 768, 960 },
	{ 640, 280 },
	{ 568, 320 },
	{ 800, 360 },
	{ 1024, 600 },
	{ 1280, 720 },
	{ 1600, 900 },
	{ 1920, 1080 },
	{ 2560, 1080 },
}) do
	local width, height = size[1], size[2]
	local layout = Layout.compute(width, height)
	for _, name in ipairs({ "header", "footer", "navigation", "stage", "card", "panel", "reward" }) do
		local rect = layout[name]
		expect(rect[3] > 0 and rect[4] > 0, "positive dimensions: " .. name)
		expect(
			rect[1] >= 0 and rect[2] >= 0 and rect[1] + rect[3] <= width and rect[2] + rect[4] <= height,
			"inside safe area: " .. name
		)
	end
	for _, name in ipairs({ "header", "footer", "navigation", "card", "panel", "reward" }) do
		expect(not overlap(layout.stage, layout[name]), "hero unobscured by " .. name)
	end
	local card = layout.card
	local continueButton = { card[1] + 12, card[2] + card[4] - 58, card[3] - 24, 46 }
	expect(not overlap(layout.reward, continueButton), "reward keeps primary action accessible")
	local columns = layout.navColumns
	local nav = layout.navigation
	expect((nav[3] - (columns - 1) * 6) / columns >= 44, "navigation touch width")
	expect((nav[4] - (4 / columns - 1) * 6) / (4 / columns) >= 44, "navigation touch height")
	expect(layout.panel[3] - 24 >= 176, "four campaign nodes fit")
end
print(string.format("Lobby layout passed: %d checks across 14 safe viewports.", checks))
