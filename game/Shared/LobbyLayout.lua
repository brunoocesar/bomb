local LobbyLayout = {}
function LobbyLayout.compute(width, height)
	local portrait = width < height * 1.05
	local gap, footer = 10, portrait and 84 or 56
	local header = portrait and 52 or 42
	local nav = portrait and 60 or width < 850 and 112 or 160
	local result = {
		portrait = portrait,
		header = { gap, 6, width - 2 * gap, header },
		footer = { gap, height - footer - gap, width - 2 * gap, footer },
	}
	local top, bottom = header + 16, height - footer - 20
	result.navColumns = not portrait and height < 400 and 2 or 1
	result.navigation = { gap, top, nav, math.min(bottom - top, result.navColumns == 2 and 124 or 256) }
	if portrait then
		local contentWidth = width - nav - 3 * gap
		local heroHeight = math.max(142, math.min(height * 0.36, bottom - top - 156))
		result.stage = { nav + 2 * gap, top, contentWidth, heroHeight }
		result.card = { nav + 2 * gap, top + heroHeight + 8, contentWidth, bottom - top - heroHeight - 8 }
		result.panel = table.clone(result.card)
	else
		local cardWidth = math.clamp(width * 0.29, 232, 340)
		local centerWidth = width - nav - cardWidth - 4 * gap
		result.stage = { nav + 2 * gap, top, centerWidth, bottom - top }
		result.card = { width - cardWidth - gap, top + math.max(0, (bottom - top - 280) / 2), cardWidth, math.min(
			280,
			bottom - top
		) }
		result.panel = { width - cardWidth - gap, top, cardWidth, bottom - top }
	end
	return result
end
return LobbyLayout
