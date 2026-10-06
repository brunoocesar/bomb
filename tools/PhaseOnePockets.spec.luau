-- Geometry-only bomb escape fixtures: no enemies or mount. Starts are fixtures,
-- not teleports in the full-route test. Closed and cleared layouts retain walls/chest.
local Phase = require("../game/Shared/PhaseOne")
local Simulation = require("../game/Shared/Simulation")
local directions = { { "up", 0, -1 }, { "right", 1, 0 }, { "down", 0, 1 }, { "left", -1, 0 } }
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
local function reachable(model)
	local queue = { { x = model.x, y = model.y, path = {} } }
	local seen = { [model.x .. ":" .. model.y] = true }
	local cursor = 1
	while cursor <= #queue do
		local cell = queue[cursor]
		cursor += 1
		for _, d in ipairs(directions) do
			local x, y = cell.x + d[2], cell.y + d[3]
			local key = x .. ":" .. y
			if not seen[key] and not model:blocked(x, y, "player") then
				seen[key] = true
				local path = table.clone(cell.path)
				table.insert(path, d[1])
				table.insert(queue, { x = x, y = y, path = path })
			end
		end
	end
	return queue
end
local checks = 0
for stage = 1, 2 do
	for _, cleared in ipairs({ false, true }) do
		local base = Simulation.new(Phase, { stage = stage, deaths = 0 })
		base.enemies = {}
		if cleared then
			for cell, tile in pairs(base.tiles) do
				if tile ~= "#" and tile ~= "X" then
					base.tiles[cell] = nil
				end
			end
		end
		for _, cell in ipairs(reachable(base)) do
			for _, range in ipairs({ 2, 3 }) do
				local fixture = copy(base)
				fixture.x, fixture.y, fixture.range = cell.x, cell.y, range
				assert(fixture:placeBomb(), "fixture can place one bomb")
				local safe = false
				for _, refuge in ipairs(reachable(fixture)) do
					if #refuge.path <= 8 then
						local attempt = copy(fixture)
						for _, direction in ipairs(refuge.path) do
							for _ = 1, 24 do
								attempt:step(0.01, direction)
							end
						end
						attempt:steer("stop")
						while attempt.time < Phase.fuse + Phase.blastDuration + 0.1 do
							attempt:step(0.01, "stop")
						end
						if attempt.profile.deaths == 0 then
							safe = true
							break
						end
					end
				end
				checks += 1
				assert(
					safe,
					string.format(
						"No unmounted escape: stage %d, cleared %s, %d,%d, range %d",
						stage,
						tostring(cleared),
						cell.x,
						cell.y,
						range
					)
				)
			end
		end
	end
end
print("PhaseOne pockets: " .. checks .. " reachable bomb placements have a geometry-only escape, without a mount.")
