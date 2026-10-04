-- Presentation follows actual ray connections, not mere proximity of flames.
local BlastVisual = {}
local opposite = { up = "down", right = "left", down = "up", left = "right" }
local delta = { up = { 0, -1 }, right = { 1, 0 }, down = { 0, 1 }, left = { -1, 0 } }

function BlastVisual.connect(connections, from, to, direction, untilTime)
	connections[from] = connections[from] or {}
	connections[to] = connections[to] or {}
	connections[from][direction] = math.max(connections[from][direction] or 0, untilTime)
	local back = opposite[direction]
	connections[to][back] = math.max(connections[to][back] or 0, untilTime)
end

function BlastVisual.parts(state, x, y)
	local cell = x .. ":" .. y
	if not state.blasts[cell] or state.blasts[cell] <= state.time then
		return nil
	end
	local links = (state.blastConnections or {})[cell] or {}
	local connected = {}
	for direction, offset in pairs(delta) do
		local neighbor = state.blasts[(x + offset[1]) .. ":" .. (y + offset[2])]
		connected[direction] = (links[direction] or 0) > state.time and neighbor ~= nil and neighbor > state.time
	end
	local horizontal = connected.left or connected.right
	local vertical = connected.up or connected.down
	local center = ((state.blastCenters or {})[cell] or 0) > state.time
		or (horizontal and vertical)
		or not (horizontal or vertical)
	local result = { Core = center and "blastCore" or nil }
	for direction in pairs(delta) do
		local enabled = connected[direction] or (not center and connected[opposite[direction]])
		if enabled then
			local name = direction:sub(1, 1):upper() .. direction:sub(2)
			result[name] = connected[direction]
					and ((direction == "left" or direction == "right") and "blastJoinHorizontal" or "blastJoinVertical")
				or "blastTip" .. name
		end
	end
	return result
end

return BlastVisual
