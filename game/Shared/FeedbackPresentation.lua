-- Pure presentation data. Never writes to simulation tiles, hazards or rewards.
local Feedback = {}
Feedback.duration = 0.42
Feedback.poolSize = 16
local corners = { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }

function Feedback.changes(previous, current)
	local destroyed, revealed = {}, {}
	if not previous or previous.revision ~= current.revision then
		return destroyed, revealed
	end
	for cell, tile in pairs(previous.tiles) do
		if tile ~= "#" and not current.tiles[cell] then
			local x, y = cell:match("^(%d+):(%d+)$")
			table.insert(destroyed, { x = tonumber(x), y = tonumber(y), tile = tile, at = current.time })
		end
	end
	table.sort(destroyed, function(a, b)
		return a.y == b.y and a.x < b.x or a.y < b.y
	end)
	for cell, item in pairs(current.items) do
		if previous.items[cell] ~= item then
			revealed[cell] = current.time
		end
	end
	return destroyed, revealed
end

function Feedback.fragment(index, age)
	if age >= Feedback.duration then
		return nil
	end
	local t = math.clamp(age / Feedback.duration, 0, 1)
	local corner = corners[index]
	return {
		x = 0.5 + corner[1] * (0.2 + 0.15 * t),
		y = 0.5 + corner[2] * (0.2 + 0.15 * t) - math.sin(t * math.pi) * 0.12,
		size = 0.44 - 0.24 * t,
		rotation = corner[1] * corner[2] * 55 * t,
		transparency = t * t,
	}
end

function Feedback.item(age)
	local t = math.clamp(age / 0.5, 0, 1)
	return {
		size = 0.75 + math.sin(t * math.pi) * 0.17,
		y = 0.5 - math.sin(t * math.pi) * 0.12,
		glow = 0.75 - math.sin(t * math.pi) * 0.5,
	}
end

function Feedback.stats(state, narrow)
	local active = 0
	for _ in pairs(state.bombs) do
		active += 1
	end
	return string.format(
		narrow and "BOMBS READY\n%d/%d\nRANGE: %d tiles" or "BOMBS READY: %d/%d\nRANGE: %d tiles",
		math.max(0, state.capacity - active),
		state.capacity,
		state.range
	)
end

function Feedback.mount(state)
	return state.frog and "FROG: 1 HIT" or "FROG: NONE"
end

function Feedback.saveMessage(state)
	if state.saveStatus == "Local Studio session" then
		return ""
	end
	if state.saveStatus == "Save pending - retrying" then
		return "Progress save pending. We'll retry."
	end
	if state.saveStatus == "Save pending" then
		return "Saving progress..."
	end
	return state.saveStatus or ""
end

Feedback.exitHint = "Exit open! Enter the glowing portal."
return Feedback
