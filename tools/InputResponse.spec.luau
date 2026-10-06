local Simulation = require("../game/Shared/Simulation")
local Movement = require("../game/Shared/PlayerMovement")
local checks = 0
local function expect(ok, message)
	checks += 1
	assert(ok, message)
end
local function fixture()
	return Simulation.new({
		width = 7,
		height = 7,
		stages = { { rows = { "#######", "#P...D#", "#.....#", "#..B..#", "#.....#", "#....E#", "#######" } } },
		moveInterval = 0.24,
		enemyInterval = 0.95,
		fuse = 2.4,
		blastDuration = 0.45,
	})
end
for _, first in ipairs({ "left", "right", "up", "down" }) do
	for _, second in ipairs({ "left", "right", "up", "down" }) do
		for _, elapsed in ipairs({ 0.003, 0.03, 0.09, 0.15, 0.21 }) do
			local sim = fixture()
			sim.x, sim.y = 4, 3
			sim.tiles = {}
			sim.enemies = {}
			sim:steer(first)
			sim:step(elapsed)
			local x, y = sim.x, sim.y
			sim:steer(second)
			expect(sim.x == x and sim.y == y, "steering never snaps fractional position")
			sim:step(0.005)
			local vx, vy = Movement.vector(second)
			expect(
				math.abs(sim.x - x - vx * 0.005 / 0.24) < 1e-8 and math.abs(sim.y - y - vy * 0.005 / 0.24) < 1e-8,
				"all direction changes start immediately"
			)
			sim:steer("stop")
			x, y = sim.x, sim.y
			sim:step(0.4)
			expect(sim.x == x and sim.y == y, "release never finishes a cell")
		end
	end
end
local sim = fixture()
sim:step(0.01, "left")
local x, y = sim.x, sim.y
sim:step(0.01, "right")
expect(sim.x > x and sim.y == y, "blocked input imposes no cooldown on the opposite direction")
sim = fixture()
sim.x, sim.y = 3.4, 3
sim:step(0.2, "down")
expect(sim.y < 3.5, "solid corner blocks the attempted axis")
x, y = sim.x, sim.y
sim:step(0.02, "left")
expect(sim.x < x and sim.y == y, "can slide immediately away from a blocked corner")
sim = fixture()
sim:step(0.06, "right")
sim:steer("stop")
expect(sim:placeBomb() and sim.bombs["2:2"], "fractional position selects occupied cell")
sim.invulnerableUntil = 0
sim.blasts["2:3"] = 10
sim:checkHazards()
expect(sim.mode == "playing", "different cell blast is not premature damage")
sim:step(0.15, "down")
expect(sim.mode == "dead", "blast damage follows actual occupied cell")
print(string.format("Input response passed: %d checks.", checks))
