-- Pixel geometry within the ScreenGui safe area. All cells remain square.
local Layout = {}
function Layout.compute(width, height, safeTop, columns, rows)
	columns, rows = columns or 13, rows or 9
	if safeTop and safeTop > 0 then
		local result = Layout.compute(width, height - safeTop, nil, columns, rows)
		for _, rect in ipairs({ result.board, result.header, result.hint }) do
			rect[2] += safeTop
		end
		for _, rect in pairs(result.buttons) do
			rect[2] += safeTop
		end
		return result
	end
	local wide = width > height * 1.4
	local short = wide and height < 260
	local area = wide and { 156, 8, width - 264, height - 36 } or { 8, 84, width - 16, height - 218 }
	if short then
		area = { 156, 44, width - 264, height - 72 }
	end
	local cell = math.min(area[3] / columns, area[4] / rows)
	local bw, bh = cell * columns, cell * rows
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
		local top = short and math.max(90, math.min(height - 124, by + bh / 2 - 47)) or math.max(154, by + bh / 2 - 47)
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
		if short then
			result.header = { 8, 8, 140, 72 }
			result.hint = { 156, 8, width - 264, 28 }
			result.headerParts.Stage = { 0, 0, 140, 20 }
			result.headerParts.Energy = { 0, 20, 140, 20 }
			result.headerParts.Stats = { 0, 40, 140, 32 }
		end
	else
		for name, offset in pairs({ Up = { 58, 0 }, Left = { 0, 58 }, Down = { 58, 58 }, Right = { 116, 58 } }) do
			result.buttons[name] = { 8 + offset[1], height - 134 + offset[2], 52, 52 }
		end
		result.buttons.Bomb = { width - 98, height - 122, 90, 90 }
	end
	return result
end
return Layout
