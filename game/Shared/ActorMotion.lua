-- Shared by authoritative hazards and presentation. Coordinates are cell centers.
local ActorMotion = {}

function ActorMotion.position(actor, time)
	local move = actor.motion
	if not move then
		return actor.x, actor.y
	end
	if move.points then
		local distance = math.clamp((time - move.at) / move.duration, 0, 1) * move.distance
		local x, y = move.x, move.y
		for _, point in ipairs(move.points) do
			local length = math.abs(point[1] - x) + math.abs(point[2] - y)
			if length > 0 and distance <= length then
				local alpha = distance / length
				return x + (point[1] - x) * alpha, y + (point[2] - y) * alpha
			end
			distance -= length
			x, y = point[1], point[2]
		end
		return actor.x, actor.y
	end
	local alpha = math.clamp((time - move.at) / move.duration, 0, 1)
	return move.x + (actor.x - move.x) * alpha, move.y + (actor.y - move.y) * alpha
end

function ActorMotion.beginPath(actor, points, input, time, secondsPerCell)
	local x, y = ActorMotion.position(actor, time)
	local distance, previousX, previousY = 0, x, y
	for _, point in ipairs(points) do
		assert(point[1] == previousX or point[2] == previousY, "Movement segments must follow one axis")
		distance += math.abs(point[1] - previousX) + math.abs(point[2] - previousY)
		previousX, previousY = point[1], point[2]
	end
	actor.x, actor.y = previousX, previousY
	if distance < 0.000001 then
		actor.motion = nil
	else
		actor.motion = {
			x = x,
			y = y,
			at = time,
			duration = distance * secondsPerCell,
			distance = distance,
			points = points,
			input = input,
		}
	end
	return distance * secondsPerCell
end

function ActorMotion.begin(actor, x, y, time, duration)
	local fromX, fromY = ActorMotion.position(actor, time)
	actor.motion = { x = fromX, y = fromY, at = time, duration = duration }
	actor.x, actor.y = x, y
end

function ActorMotion.cell(actor, time)
	local x, y = ActorMotion.position(actor, time)
	return math.floor(x + 0.5), math.floor(y + 0.5)
end

return ActorMotion
