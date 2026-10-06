-- One continuous presentation position, reconciled with authoritative snapshots.
local Movement = require(if script then script.Parent.PlayerMovement else "./PlayerMovement")
local Prediction = {}
Prediction.__index = Prediction

function Prediction.new(secondsPerCell)
	return setmetatable({ speed = secondsPerCell, input = { 0, 0 }, sequence = 0 }, Prediction)
end

function Prediction:advance(state, now, live)
	if not self.x then
		self.x, self.y = state.x, state.y
	end
	local dt = self.at and math.max(0, now - self.at) or 0
	self.at = now
	if live then
		self.x, self.y = Movement.advance(state, self.x, self.y, self.input, dt, self.speed)
	end
	return self.x, self.y
end

function Prediction:setInput(state, input, now)
	if state then
		self:advance(state, now, not state.paused and state.mode == "playing")
	end
	self.input = input
	self.sequence += 1
	return { input[1], input[2], self.sequence }
end

function Prediction:receive(state, now)
	if self.x and self.state then
		self:advance(self.state, now, not self.state.paused and self.state.mode == "playing")
	end
	local reset = not self.state or self.state.revision ~= state.revision or state.paused or state.mode ~= "playing"
	local acknowledged = (state.inputSequence or 0) >= self.sequence
	local stopped = self.input[1] == 0 and self.input[2] == 0 and state.input[1] == 0 and state.input[2] == 0
	-- Held movement is integrated across snapshots, rather than restarted every
	-- network tick. Reconcile the final stop after its command is acknowledged.
	if reset or acknowledged and stopped then
		self.x, self.y = state.x, state.y
	end
	if self.x and (math.abs(self.x - state.x) + math.abs(self.y - state.y) > 1) then
		self.x, self.y = state.x, state.y
	end
	self.state, self.at = state, now
end

return Prediction
