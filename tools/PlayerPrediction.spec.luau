local Simulation = require("../game/Shared/Simulation")
local Prediction = require("../game/Shared/PlayerPrediction")
local checks = 0
local function expect(ok, message)
	checks += 1
	assert(ok, message)
end
local function fixture()
	local sim = Simulation.new({
		width = 30,
		height = 30,
		stages = { { rows = { "P............................D" } } },
		moveInterval = 0.24,
		enemyInterval = 100,
		fuse = 2.4,
		blastDuration = 0.45,
	})
	sim.x, sim.y = 10, 10
	return sim
end
for _, fps in ipairs({ 5, 10, 15, 30, 60, 120, 144 }) do
	local sim = fixture()
	local predictor = Prediction.new(0.24)
	local initial = sim:snapshot()
	initial.inputSequence = 0
	predictor:receive(initial, 0)
	local input = predictor:setInput(initial, { 1, 0 }, 0)
	for frame = 1, fps * 3 do
		local time = frame / fps
		-- A delayed authoritative stream must not restart the presentation position.
		if frame % math.max(1, math.floor(fps / 20)) == 0 then
			local s = sim:snapshot()
			s.x = 10 + math.max(0, time - 0.07) / 0.24
			s.input = { 1, 0 }
			s.inputSequence = input[3]
			predictor:receive(s, time)
		end
		local x, y = predictor:advance(initial, time, true)
		expect(
			math.abs(x - 10 - time / 0.24) < 1e-7 and y == 10,
			"held display integrates continuously across delayed snapshots"
		)
	end
	local x = predictor.x
	local stop = predictor:setInput(initial, { 0, 0 }, 3)
	for frame = 1, math.ceil(fps * 0.07) do
		local px = predictor:advance(initial, 3 + frame / fps, true)
		expect(px == x, "local release freezes immediately before server acknowledgement")
	end
	local final = sim:snapshot()
	final.x = x
	final.input = { 0, 0 }
	final.inputSequence = stop[3]
	predictor:receive(final, 3.1)
	expect(predictor.x == x, "acknowledged stop never snaps to a cell center")
end
local sim = fixture()
local predictor = Prediction.new(0.24)
local s = sim:snapshot()
predictor:receive(s, 0)
predictor:setInput(s, { 1, 0 }, 0)
predictor:advance(s, 0.037, true)
local x, y = predictor.x, predictor.y
predictor:setInput(s, { 0, -1 }, 0.037)
predictor:advance(s, 0.057, true)
expect(math.abs(predictor.x - x) < 1e-9 and predictor.y < y, "presentation changes axis between cells")
s = sim:snapshot()
s.revision += 1
s.x, s.y = 2, 2
predictor:receive(s, 0.1)
expect(predictor.x == 2 and predictor.y == 2, "checkpoint resets prediction")
print(string.format("Player prediction passed: %d checks.", checks))
