-- Offline preview data from production ray propagation and presentation selection.
local Simulation = require("../game/Shared/Simulation")
local Visual = require("../game/Shared/BlastVisual")
local function fixture()
	return Simulation.new({
		width = 13,
		height = 9,
		fuse = 2.4,
		blastDuration = 0.45,
		moveInterval = 0.24,
		enemyInterval = 1,
		stages = {
			{
				rows = {
					"#############",
					"#P..........#",
					"#...........#",
					"#...........#",
					"#...........#",
					"#...........#",
					"#...........#",
					"#.........ED#",
					"#############",
				},
			},
		},
	})
end
local function addBomb(sim, x, y, range)
	sim.bombs[x .. ":" .. y] = { x = x, y = y, range = range, at = 2.4 }
end
local function capture(sim)
	local cells = {}
	for y = 1, 9 do
		for x = 1, 13 do
			local parts = Visual.parts(sim:snapshot(), x, y)
			if parts then
				cells[x .. ":" .. y] = { x = x, y = y, parts = parts }
			end
		end
	end
	return { cells = cells, tiles = sim.tiles }
end
local result = {}
local sim = fixture()
addBomb(sim, 7, 5, 3)
sim:explode("7:5")
result.Open = capture(sim)
sim = fixture()
sim.tiles["7:3"], sim.tiles["9:5"], sim.tiles["4:5"] = "#", "B", "#"
addBomb(sim, 7, 5, 3)
sim:explode("7:5")
result.Blocked = capture(sim)
sim = fixture()
addBomb(sim, 5, 5, 3)
addBomb(sim, 8, 5, 2)
sim:explode("5:5")
result.Chain = capture(sim)

local function json(value)
	if type(value) == "string" then
		return string.format("%q", value)
	end
	if type(value) ~= "table" then
		return tostring(value)
	end
	local keys, entries = {}, {}
	for key in pairs(value) do
		table.insert(keys, key)
	end
	table.sort(keys)
	for _, key in ipairs(keys) do
		table.insert(entries, json(key) .. ":" .. json(value[key]))
	end
	return "{" .. table.concat(entries, ",") .. "}"
end
print(json(result))
