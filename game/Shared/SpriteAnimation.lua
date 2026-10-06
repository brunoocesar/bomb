-- One selector owns the frame for each view. Blink schedules never write to a GUI.
local Catalog = require(if script then script.Parent.SpriteCatalog else "./SpriteCatalog")
local Packs = require(if script then script.Parent.SkinPacks else "./SkinPacks")
local Animation = {}
Animation.__index = Animation

function Animation.new(random)
	return setmetatable({ slots = {}, random = random or math.random }, Animation)
end

function Animation:select(slot, pack, kind, action, direction, time)
	local animations = Catalog.animations[kind]
	local sequence = animations[action] and animations[action][direction] or animations.idle[direction]
	local signature = pack .. ":" .. kind .. ":" .. action .. ":" .. direction
	local state = self.slots[slot]
	if not state or state.signature ~= signature or time < state.time - 1 then
		state = { signature = signature, nextBlink = time + 3 + self.random() * 3 }
		self.slots[slot] = state
	end
	-- Snapshot/extrapolation jitter must not restart a several-second timer.
	time = math.max(time, state.time or time)
	state.time = time
	local blink = animations.blink and animations.blink[direction]
	local blinking = false
	if action == "idle" and blink then
		if time >= state.nextBlink then
			state.blinkUntil = time + 0.1 + self.random() * 0.1
			state.nextBlink = state.blinkUntil + 3 + self.random() * 3
		end
		blinking = state.blinkUntil ~= nil and time < state.blinkUntil
		if blinking then
			sequence = blink
		end
	end
	local atlasId = Packs.atlas(pack, kind, sequence[1])
	local atlas = Catalog.atlases[atlasId]
	local column = sequence[3]
	if action ~= "idle" then
		column += math.floor(time * 8) % (sequence[4] - sequence[3] + 1)
	end
	return atlas.frames[sequence[2] * atlas.columns + column + 1], atlasId, blinking
end

return Animation
