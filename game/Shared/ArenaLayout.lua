-- Pixel geometry within the ScreenGui safe area. The whole 13x9 map stays visible.
local Layout = {}
function Layout.compute(width, height)
	local wide = width > height * 1.4
	local area = wide and { 156, 8, width - 264, height - 36 } or { 8, 84, width - 16, height - 218 }
	local cell = math.min(area[3] / 13, area[4] / 9)
	local bw, bh = cell * 13, cell * 9
	local bx, by = area[1] + (area[3] - bw) / 2, area[2] + (area[4] - bh) / 2
	local result = {
		wide = wide,
		board = { bx, by, bw, bh },
		cell = cell,
		header = wide and { 8, 8, 140, 96 } or { 0, 0, width, 52 },
		hint = wide and { 8, 104, 140, 48 } or { 8, 58, width - 16, 22 },
		buttons = {},
	}
	if wide then
		local left = math.max(8, bx - 152)
		local top = math.max(154, by + bh / 2 - 47)
		for name, offset in pairs({ Up = { 50, 0 }, Left = { 0, 50 }, Down = { 50, 50 }, Right = { 100, 50 } }) do
			result.buttons[name] = { left + offset[1], top + offset[2], 44, 44 }
		end
		result.buttons.Bomb = { bx + bw + 8, by + bh / 2 - 45, 90, 90 }
		result.headerParts = {
			Stage = { 0, 0, 140, 24 },
			Energy = { 0, 24, 140, 24 },
			Stats = { 0, 48, 140, 48 },
			Pause = {
				width - 64,
				0,
				44,
				44,
			},
		}
	else
		for name, offset in pairs({ Up = { 58, 0 }, Left = { 0, 58 }, Down = { 58, 58 }, Right = { 116, 58 } }) do
			result.buttons[name] = { 8 + offset[1], height - 134 + offset[2], 52, 52 }
		end
		result.buttons.Bomb = { width - 98, height - 122, 90, 90 }
	end
	return result
end
return Layout
