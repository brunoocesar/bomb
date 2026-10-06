-- Continuous cell-space movement, shared by the server and client presentation.
local Movement = {}
local Contact = require(if script then script.Parent.ObstacleCollision else "./ObstacleCollision")
local directions = { up = { 0, -1 }, down = { 0, 1 }, left = { -1, 0 }, right = { 1, 0 } }

function Movement.vector(input)
	local value = type(input) == "string" and directions[input] or input
	if type(value) ~= "table" then
		return 0, 0
	end
	local x, y = value[1], value[2]
	if
		type(x) ~= "number"
		or type(y) ~= "number"
		or x ~= x
		or y ~= y
		or math.abs(x) == math.huge
		or math.abs(y) == math.huge
	then
		return 0, 0
	end
	local length = math.sqrt(x * x + y * y)
	if length > 1 then
		x, y = x / length, y / length
	end
	return x, y
end

function Movement.facing(x, y, previous)
	if x == 0 and y == 0 then
		return previous
	end
	if math.abs(x) > math.abs(y) then
		return x > 0 and "right" or "left"
	end
	return y > 0 and "down" or "up"
end

local function obstacles(state, visit)
	for cell, tile in pairs(state.tiles) do
		local x, y = cell:match("^(%d+):(%d+)$")
		x, y = tonumber(x), tonumber(y)
		local dimensions = state.definition or state
		visit(x, y, tile == "#" and x > 1 and y > 1 and x < dimensions.width and y < dimensions.height)
	end
	for _, bomb in pairs(state.bombs) do
		if not bomb.passThrough then
			visit(bomb.x, bomb.y, false)
		end
	end
	if state.energy < state.totalEnergy and state.exitX and state.exitX > 0 then
		visit(state.exitX, state.exitY, false)
	end
end

local function bounds(x, y, stone)
	-- Fixed stones retain the foot-plane contact. Other solid cells use a
	-- centered contact so an actor can stop beside them without entering them.
	local offset = stone and Contact.groundOffset or 0
	local height = stone and Contact.halfHeight or Contact.halfWidth
	return x - 0.5 - Contact.halfWidth,
		x + 0.5 + Contact.halfWidth,
		y - 0.5 - offset - height,
		math.max(y + 0.5 - offset + height, y + 0.500001)
end

function Movement.advance(state, px, py, input, dt, secondsPerCell)
	local vx, vy = Movement.vector(input)
	if dt <= 0 or vx == 0 and vy == 0 then
		return px, py
	end
	local distance = dt / secondsPerCell
	-- Small swept axis steps allow wall sliding while preventing diagonal tunneling.
	local count = math.max(1, math.ceil(distance / 0.1))
	local dx, dy = vx * distance / count, vy * distance / count
	for _ = 1, count do
		local nx = px + dx
		obstacles(state, function(x, y, stone)
			local left, right, top, bottom = bounds(x, y, stone)
			if py > top + 1e-7 and py < bottom - 1e-7 then
				if dx > 0 and px <= left + 1e-7 and nx > left then
					nx = math.min(nx, left)
				elseif dx < 0 and px >= right - 1e-7 and nx < right then
					nx = math.max(nx, right)
				end
			end
		end)
		px = nx
		local ny = py + dy
		obstacles(state, function(x, y, stone)
			local left, right, top, bottom = bounds(x, y, stone)
			if px > left + 1e-7 and px < right - 1e-7 then
				if dy > 0 and py <= top + 1e-7 and ny > top then
					ny = math.min(ny, top)
				elseif dy < 0 and py >= bottom - 1e-7 and ny < bottom then
					ny = math.max(ny, bottom)
				end
			end
		end)
		py = ny
	end
	return px, py
end

function Movement.overlapsBomb(px, py, bomb)
	local left, right, top, bottom = bounds(bomb.x, bomb.y, false)
	return px > left + 1e-7 and px < right - 1e-7 and py > top + 1e-7 and py < bottom - 1e-7
end

return Movement
