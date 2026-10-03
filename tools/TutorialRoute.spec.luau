-- A planning controller walks the actual production simulation; it never teleports or edits level state.
local Tutorial = require("../game/Shared/Tutorial")
local Simulation = require("../game/Shared/Simulation")
local directions = { { "up", 0, -1 }, { "right", 1, 0 }, { "down", 0, 1 }, { "left", -1, 0 } }
local sim = Simulation.new(Tutorial)

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for k, v in pairs(value) do
		result[k] = k == "definition" and v or copy(v)
	end
	return setmetatable(result, getmetatable(value))
end

local function walk(model, path)
	for _, direction in ipairs(path) do
		local x, y = model.x, model.y
		for _ = 1, 8 do
			model:step(0.05, direction)
			if model.x ~= x or model.y ~= y or model.mode ~= "playing" then
				break
			end
		end
		if (model.x == x and model.y == y) or model.mode ~= "playing" then
			return false
		end
	end
	return true
end

local function reachable(model)
	local start = { x = model.x, y = model.y, path = {} }
	local queue, seen = { start }, { [model.x .. ":" .. model.y] = true }
	local index = 1
	while index <= #queue do
		local current = queue[index]
		index += 1
		for _, direction in ipairs(directions) do
			local x, y = current.x + direction[2], current.y + direction[3]
			local key = x .. ":" .. y
			if not seen[key] and not model:blocked(x, y, "player") then
				seen[key] = true
				local path = table.clone(current.path)
				path[#path + 1] = direction[1]
				queue[#queue + 1] = { x = x, y = y, path = path }
			end
		end
	end
	return queue
end

local function score(model, cell)
	local value = 0
	for _, direction in ipairs(directions) do
		for distance = 1, model.range do
			local x, y = cell.x + direction[2] * distance, cell.y + direction[3] * distance
			local tile = model.tiles[x .. ":" .. y]
			if tile == "#" then
				break
			end
			for _, enemy in ipairs(model.enemies) do
				if enemy.alive and enemy.x == x and enemy.y == y then
					value += 15
				end
			end
			if tile then
				value += tile == "E" and 30 or (tile == "S" or tile == "A" or tile == "L") and 12 or 5
				break
			end
		end
	end
	return value - #cell.path * 0.25
end

local function safeBombPlan(cell)
	local model = copy(sim)
	if not walk(model, cell.path) or model.profile.deaths ~= 0 then
		return nil
	end
	if not model:placeBomb() then
		return nil
	end
	local at = model.time
	for _, refuge in ipairs(reachable(model)) do
		if #refuge.path <= 7 then
			local attempt = copy(model)
			if walk(attempt, refuge.path) then
				while attempt.time < at + Tutorial.fuse + Tutorial.blastDuration + 0.15 do
					attempt:step(0.05)
				end
				if attempt.mode == "playing" and attempt.profile.deaths == 0 and attempt.stage == sim.stage then
					return refuge.path
				end
			end
		end
	end
	return nil
end

local actions = 0
while sim.mode ~= "won" and actions < 150 do
	actions += 1
	local cells = reachable(sim)
	local acted = false
	for _, cell in ipairs(cells) do
		local item = sim.items[cell.x .. ":" .. cell.y]
		local exit = sim.energy == sim.totalEnergy
			and cell.x == sim.exitX
			and cell.y == sim.exitY
			and (sim.stage ~= 1 or sim.profile.secret)
		if item or exit then
			local attempt = copy(sim)
			walk(attempt, cell.path)
			if attempt.profile.deaths == 0 then
				walk(sim, cell.path)
				acted = true
				break
			end
		end
	end
	if not acted then
		table.sort(cells, function(a, b)
			return score(sim, a) > score(sim, b)
		end)
		for _, cell in ipairs(cells) do
			if score(sim, cell) > 0 then
				local refuge = safeBombPlan(cell)
				if refuge then
					assert(walk(sim, cell.path), "walk to planned bomb")
					assert(sim:placeBomb(), "place planned bomb")
					local at = sim.time
					assert(walk(sim, refuge), "escape planned bomb")
					while sim.time < at + Tutorial.fuse + Tutorial.blastDuration + 0.15 do
						sim:step(0.05)
					end
					acted = true
					break
				end
			end
		end
	end
	assert(acted, string.format("No safe plan at stage %d, cell %d,%d", sim.stage, sim.x, sim.y))
	assert(sim.profile.deaths == 0, "full-route controller survived")
	table.clear(sim.events)
end
assert(sim.mode == "won", "both authored stages are completable")
assert(sim.profile.frogUnlocked, "frog rescued on route")
assert(sim.profile.secret, "main secret found on route")
print(
	string.format(
		"Full tutorial route passed: %d actions, %.1f simulated seconds, no deaths, secret and frog unlocked.",
		actions,
		sim.time
	)
)
