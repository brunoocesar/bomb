local Simulation = require("../game/Shared/Simulation")
local Motion = require("../game/Shared/ActorMotion")
local checks = 0
local function expect(ok, message)
	checks += 1
	assert(ok, message)
end
local function fixture()
	return Simulation.new({
		width = 7,
		height = 5,
		stages = { { rows = { "#######", "#P...D#", "#..B..#", "#....E#", "#######" } } },
		moveInterval = 0.24,
		enemyInterval = 0.95,
		fuse = 2.4,
		blastDuration = 0.45,
	})
end
local sim = fixture()
expect(not sim:steer("left"), "wall blocks first input")
expect(sim:steer("right"), "opposite input starts immediately despite blocked cooldown")
sim:step(0.06)
local px, py = Motion.position(sim, sim.time)
expect(sim:steer("left"), "mid-step reversal accepted before interval ends")
local rx, ry = Motion.position(sim, sim.time)
expect(math.abs(px - rx) < 1e-9 and py == ry, "reversal never teleports")
sim:step(0.02)
expect(Motion.position(sim, sim.time) < px, "reversal visibly travels left immediately")
expect(sim:steer("right"), "rapid second reversal is also accepted")
expect(sim:steer("down"), "perpendicular input accepted in an open corridor")
local tx, ty = Motion.position(sim, sim.time)
sim:step(0.01)
local ux, uy = Motion.position(sim, sim.time)
expect(ux == tx and uy > ty, "new axis starts immediately without diagonal movement")

-- Every ordered change of axis, at early and late portions of a step.
for _, pair in ipairs({
	{ "left", "up" },
	{ "left", "down" },
	{ "right", "up" },
	{ "right", "down" },
	{ "up", "left" },
	{ "up", "right" },
	{ "down", "left" },
	{ "down", "right" },
}) do
	for _, elapsed in ipairs({ 0.03, 0.09, 0.15, 0.21 }) do
		local turn = fixture()
		turn.tiles = {}
		turn.x, turn.y = 4, 3
		expect(turn:steer(pair[1]), "initial direction accepted")
		turn:step(elapsed)
		local x, y = Motion.position(turn, turn.time)
		expect(turn:steer(pair[2]), "all cross-axis turns accepted mid-step")
		local a, b = Motion.position(turn, turn.time)
		expect(a == x and b == y, "turn does not teleport")
		turn:step(0.005)
		a, b = Motion.position(turn, turn.time)
		expect(
			(pair[2] == "up" and b < y and a == x)
				or (pair[2] == "down" and b > y and a == x)
				or (pair[2] == "left" and a < x and b == y)
				or (pair[2] == "right" and a > x and b == y),
			"new axis responds immediately"
		)
		for _ = 1, 65 do
			turn:step(0.005)
			local nx, ny = Motion.position(turn, turn.time)
			expect(math.abs(nx - a) < 1e-9 or math.abs(ny - b) < 1e-9, "segments never move diagonally")
			a, b = nx, ny
		end
		expect(a == turn.x and b == turn.y and a % 1 == 0 and b % 1 == 0, "turn returns to grid center")
	end
end

sim = fixture()
sim.x, sim.y = 3, 2
sim:steer("right")
sim:step(0.06)
expect(sim:steer("down"), "solid corner chooses reachable intersection")
local cornerX = Motion.position(sim, sim.time)
sim:step(0.02)
expect(Motion.position(sim, sim.time) < cornerX, "approaches nearby turn instead of finishing old step")
for _ = 1, 80 do
	sim:step(0.005)
	local x, y = Motion.cell(sim, sim.time)
	expect(not sim.tiles[x .. ":" .. y], "corner turn never enters solid cell")
end
sim = fixture()
sim:steer("right")
sim:step(0.06)
expect(sim:placeBomb() and sim.bombs["2:2"] ~= nil, "bomb uses occupied cell rather than queued destination")
expect(sim:steer("left"), "own bomb permits reversal before leaving its occupied cell")
sim:step(0.1)
sim:steer("right")
sim:step(0.15)
expect(not sim.bombs["2:2"].passThrough, "own bomb becomes solid after physically leaving")
expect(not sim:steer("left"), "reversal cannot enter bomb after leaving")

sim = fixture()
sim:steer("right")
sim:step(0.06)
sim:steer("down")
expect(sim.x == 2 and sim.y == 3, "turned path retains integer final destination")
expect(sim:placeBomb() and sim.bombs["2:2"], "bomb during cross-axis turn stays at actual support")
sim.invulnerableUntil = 0
sim.blasts["2:3"] = sim.time + 1
sim:checkHazards()
expect(sim.mode == "playing", "queued destination does not deal premature blast damage")
sim:step(0.14)
expect(sim.mode == "dead", "blast damage follows support along new axis")

sim = fixture()
sim.x, sim.y = 3, 2
sim.bombs["3:3"] = { x = 3, y = 3, at = 10, range = 2, passThrough = false }
sim:steer("left")
sim:step(0.06)
expect(sim:steer("down"), "bomb corner chooses alternate safe intersection")
for _ = 1, 80 do
	sim:step(0.005)
	local x, y = Motion.cell(sim, sim.time)
	expect(x ~= 3 or y ~= 3, "turn cannot cross a solid bomb")
end
sim = fixture()
sim:steer("right")
sim:step(0.06)
local arrival = sim.nextMove
expect(not sim:steer("up"), "closed perpendicular corridor remains blocked")
expect(sim.nextMove == arrival, "failed turn does not delay current motion")
expect(not sim:steer("right") and sim.direction == "right", "return to previous held axis updates facing immediately")
sim:step(0.19, "right")
expect(sim.x == 4, "held movement resumes without a blocked-turn cooldown")

sim = fixture()
sim:steer("right")
expect(sim:steer("left") and sim.motion == nil, "zero-distance reversal cancels safely")
for _ = 1, 100 do
	sim:step(0.01, "left")
	local x, y = Motion.position(sim, sim.time)
	expect(x >= 2 and y == 2, "rapid wall input stays inside corridor")
end
print(string.format("Input response passed: %d checks.", checks))
